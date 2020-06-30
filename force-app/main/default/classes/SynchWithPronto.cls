/**
* 
@author: Cyrille Jeufo - Proquest Consulting
@initial version: 18/11/2019 - Initial version - This class contains methods to do callouts and handling responses
* 
*/
public class SynchWithPronto implements Queueable , Database.AllowsCallouts{
    public Account currentAccount;
    public WorkOrderLineItem currentWoli;
    public Sales_Order__c currentSO;
    public Purchase_Order__c currentPo;
    public Boolean validatePayroll;
    public static String customer_recordtype = Schema.SObjectType.Error_log__c.getRecordTypeInfosByDeveloperName ().get('Account_ErrorLog_RT').getRecordTypeId();
    public static String transaction_recordtype = Schema.SObjectType.Error_log__c.getRecordTypeInfosByDeveloperName ().get('Transaction_ErrorLog_RT').getRecordTypeId();
    public static String so_recordtype = Schema.SObjectType.Error_log__c.getRecordTypeInfosByDeveloperName ().get('SalesOrder_ErrorLog_RT').getRecordTypeId();
    public static String po_recordtype = Schema.SObjectType.Error_log__c.getRecordTypeInfosByDeveloperName ().get('PurchaseOrder_ErrorLog_RT').getRecordTypeId();
    
    public string context;
    
    public SynchWithPronto (Account accIn , String contextIn) {
        currentAccount = accIn;
        context = contextIn;
    }
    
    public SynchWithPronto (WorkOrderLineItem woliIn , String contextIn, Boolean validatePayrollIn) {
        currentWoli = woliIn;
        context = contextIn;
        System.debug('***validatePayrollIn:'+validatePayrollIn);
        validatePayroll = validatePayrollIn;
        Utilities.woliUpdateAllowed = true;
    }
    
    public SynchWithPronto (Sales_Order__c soIn , String contextIn) {
        currentSO = soIn;
        context = contextIn;
    }
    
    public SynchWithPronto (Purchase_Order__c poIn , String contextIn) {
        currentPO = poIn;
        context = contextIn;
    }
    
    /**
    * 
    @author: Cyrille Jeufo - Proquest Consulting
    @description: This method handles all the http callouts.
    @params: woliId/accountId/SalesOrderId represent the Salesforce Id of the record being sent to Pronto
    @params: body = the payload. This will be null when Method = GET (Transaction validation)
    * 
    */
    @Future(callout=true)
    public static void makeHTTPCallout(String woliId , String accountId , String salesOrderId , String purchaseOrderId, Boolean validatePayroll, String body, Boolean saCompleted, Boolean cancelPo){
        System.debug('$$$Here 2');
        HttpResponse res;
        System.debug('@@@woliId ' + woliId);
        System.debug('@@@account ' + accountId);
        
        HTTP_Request__mdt httpSettings;
        WorkOrderLineItem tempWoli;
        String urlWithDate;
        if(String.isNotBlank(woliId)){
            System.debug('@@@validatePayroll ' + validatePayroll);
            if(validatePayroll != null){
                httpSettings = SyncWithProntoDAO.getHTTPSettings('WOLI');
                tempWoli = [Select Id , StartDate from WorkOrderLineItem where Id =: woliId];
                urlWithDate = httpSettings.URL__c + '=' + string.valueOf(date.newinstance(tempWoli.StartDate.year(), tempWoli.StartDate.month(), tempWoli.StartDate.day()));
            }else{
                httpSettings = SyncWithProntoDAO.getHTTPSettings('Timesheet');
            }
        }
        
        if(String.isNotBlank(accountId)){
            httpSettings = SyncWithProntoDAO.getHTTPSettings('Customer');
        }
        
        if(String.isNotBlank(salesOrderId)){
            httpSettings = SyncWithProntoDAO.getHTTPSettings('Sales_Order');
        }

        if(String.isNotBlank(purchaseOrderId)){
            if(!cancelPo){
                httpSettings = SyncWithProntoDAO.getHTTPSettings('Purchase_Order');
            }else{
                httpSettings = SyncWithProntoDAO.getHTTPSettings('Purchase_Order_Cancel');
            }
        }
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(httpSettings.URL__c);
        req.setMethod(httpSettings.Method__c);
        
        if(String.isNotBlank(urlWithDate)){
            req.setEndpoint(urlWithDate);
        }
        if(String.isNotBlank(body)){
            req.setBody(body);
        }
        
        System.debug('@@@request body ' + body);
        req.setHeader('Content-Type', httpSettings.Content_Type__c);
        req.setHeader('Accept-Version',httpSettings.Version__c);
        req.setHeader('Ocp-Apim-Subscription-Key', httpSettings.Subscription_Key__c);
        req.setHeader('Conflux-River', httpSettings.Conflux_River__c);
        req.setTimeout(Integer.valueOf(httpSettings.Timeout__c));
        
        Http h = new Http();
        if(!Test.isRunningTest()){
            try{
                res = h.send(req);
            }catch(Exception ex){
                logError(woliId, accountId, salesOrderId, purchaseOrderId, ex);
                return;
            }
        }else{
            if(String.isNotBlank(accountId) || String.isNotBlank(salesOrderId) || String.isNotBlank(purchaseOrderId)){
                res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setStatusCode(200);
                res.setBody('{"code":200,"status":"success","message":null,"data":{"message":{"message_id":"cbe8be86-8978-48a7-9a7c-ec973cd08332"}}}');
            } else if(String.isNotBlank(woliId)){
                res = new HttpResponse();
                res.setBody('{ "code": 200, "status": "success", "message": "null", "data": { "valid": true } }');
                res.setStatusCode(200);
            }
        }
        
        if(woliId != null){
            handleWOLICalloutResponse(res , woliId, validatePayroll, saCompleted);
        }
        
        if(accountId != null){
            handleAccountCalloutResponse(res , accountId);
        }
        
        if(salesOrderId != null){
            handlSOCalloutResponse(res , salesOrderId);
        }

        if(purchaseOrderId != null){
            handlPOCalloutResponse(res , purchaseOrderId);
        }
        
    }
    
    /**
    * 
    @author: Cyrille Jeufo - Proquest Consulting
    @description: This method deserialise the response and updates the record. If and error was received it generates an error log record
    @params: woliId = transaction Id
    @params: result = server response 
    * 
    */
    public static void handleWOLICalloutResponse(HttpResponse result , String woliId, Boolean validatePayroll, Boolean saCompleted){
        try{
            System.debug('###handleCalloutResponse body ' + result.getBody());
            Utilities.woliUpdateAllowed = true;
            WorkOrderLineItem recordToUpdate = new WorkOrderLineItem(Id = woliId , Sync_With_Pronto__c = false,Integration_Status__c = Utilities.INTEGRATION_FAILED);
            PayrollResponse pResponse = (PayrollResponse) System.JSON.deserialize(result.getBody(), PayrollResponse.class);
            System.debug('pResponse ' + pResponse );
            if(result.getStatusCode() == 200){
                if(validatePayroll != null && validatePayroll){
                    recordToUpdate.Within_Current_Payroll_Period__c = pResponse.data.valid;
                    if(recordToUpdate.Within_Current_Payroll_Period__c){
                        recordToUpdate.Integration_Status__c = Utilities.INTEGRATION_PAYROLL_VALIDATED;                    
                    }else{
                        recordToUpdate.Integration_Status__c = Utilities.INTEGRATION_DENIED;                    
                    }
                    if(saCompleted){
                        recordToUpdate.Send_Timesheet__c =  true;
                    }
                }
                if(validatePayroll == null){
                    recordToUpdate.Integration_Status__c = Utilities.INTEGRATION_WAITING;                    
                }
            }else{
                Error_log__c logRecord = new Error_log__c(workOrderLineItem__c = woliId,  Message__c	= Json.serialize(pResponse.Data) , recordTypeId = transaction_recordtype, Status__c = pResponse.status, Status_Code__c = pResponse.code + '',Subject__c = pResponse.message );
                insert logRecord;   
            }
            update recordToUpdate;
        }catch(Exception ex){
            WorkOrderLineItem woli = new WorkOrderLineItem(Id = woliId, Integration_Status__c = Utilities.INTEGRATION_FAILED , Sync_With_Pronto__c = false);
            update woli;
            Utilities.logError(woli , ex , transaction_recordtype);
        }
    }    
    
    /**
    * 
    @author: Cyrille Jeufo - Proquest Consulting
    @description: This method deserialise the response and updates the record. If and error was received it generates an error log record 
    @params: accountId = Account Id
    @params: result = server response 
    * 
    */
    public static void handleAccountCalloutResponse(HttpResponse result , String accountId){
        Account recordToUpdate = new Account(Id = accountId, Sync_With_Pronto__c = false,Integration_Status__c = Utilities.INTEGRATION_FAILED);
        try{
            if(result.getStatusCode() == 200)
            {
                recordToUpdate.Integration_Status__c = Utilities.INTEGRATION_WAITING;       
            }else{
                Log log = (Log)JSON.deserialize(result.getbody(), Log.class);
                Error_log__c logRecord = new Error_log__c(Customer__c = accountId, Message__c	= Json.serialize(log.Data) , recordTypeId = customer_recordtype, Status__c = log.status, Status_Code__c = log.code + '',Subject__c = log.message );
                insert logRecord;     
            }
            update recordToUpdate;
        }catch (Exception ex){
            Account acc = new Account(Id = recordToUpdate.Id, Integration_Status__c = Utilities.INTEGRATION_FAILED , Sync_With_Pronto__c = false);
            update acc;
            Utilities.logError(acc , ex , customer_recordtype);
        }
        
    }    
    
    /**
    * 
    @author: Cyrille Jeufo - Proquest Consulting
    @description: This method deserialise the response and updates the record. If and error was received it generates an error log record
    @params: accountId = Sales Order Id
    @params: result = server response 
    * 
    */
    public static void handlSOCalloutResponse(HttpResponse result , String soId){
        System.debug('###handlSOCalloutResponse body ' + result.getBody());
        Sales_Order__c recordToUpdate = new Sales_Order__c(Id = soId, Sync_With_Pronto__c = false,Integration_Status__c = Utilities.INTEGRATION_FAILED);
        try{
            if(result.getStatusCode() == 200)
            {
                recordToUpdate.Integration_Status__c = Utilities.INTEGRATION_WAITING;       
            }else{
                Log log = (Log)JSON.deserialize(result.getbody(), Log.class);
                Error_log__c logRecord = new Error_log__c(Sales_Order__c = soId,  Message__c	= Json.serialize(log.Data) , recordTypeId = so_recordtype, Status__c = log.status, Status_Code__c = log.code + '',Subject__c = log.message );
                insert logRecord;     
            }
            update recordToUpdate;
        }catch (Exception ex){
			Update recordToUpdate;
            Utilities.logError(recordToUpdate , ex , so_recordtype);
        }
        
    }
    
    /**
    * 
    @author: Imalka Fernando - Proquest Consulting
    @description: This method deserialise the response and updates the record. If and error was received it generates an error log record
    @params: poId = Purchase Order Id
    @params: result = server response 
    * 
    */
    public static void handlPOCalloutResponse(HttpResponse result , String poId){
        Purchase_Order__c recordToUpdate = new Purchase_Order__c(Id = poId, Sync_With_Pronto__c = false,Integration_Status__c = Utilities.INTEGRATION_FAILED);
        Purchase_Order__c po = [Select Id,Integration_Status__c From Purchase_Order__c Where Id = :poId];
        System.debug('*****INT STATUS:'+po.Integration_Status__c);
        try{
            if(result.getStatusCode() == 200)
            {
                
                recordToUpdate.Integration_Status__c = Utilities.INTEGRATION_WAITING;       
            }else{
                Log log = (Log)JSON.deserialize(result.getbody(), Log.class);
                Error_log__c logRecord = new Error_log__c(Purchase_Order__c = poId,  Message__c	= Json.serialize(log.Data) , recordTypeId = po_recordtype, Status__c = log.status, Status_Code__c = log.code + '',Subject__c = log.message );
                insert logRecord;     
            }
            update recordToUpdate;
        }catch (Exception ex){
			Update recordToUpdate;
            Utilities.logError(recordToUpdate , ex , po_recordtype);
        }
        
    }
    
    public static void logError(String woliId , String accountId , String salesOrderId , String purchaseOrderId, Exception ex){
        if(woliId != null){
            WorkOrderLineItem woli = new WorkOrderLineItem(Id = woliId, Integration_Status__c = Utilities.INTEGRATION_FAILED , Sync_With_Pronto__c = false);
            update woli;
            Utilities.logError(woli , ex , transaction_recordtype);
        }
        if(accountId != null){
            Account acc = new Account(Id = accountId, Integration_Status__c = Utilities.INTEGRATION_FAILED , Sync_With_Pronto__c = false);
            update acc;
            Utilities.logError(acc , ex , customer_recordtype);
        }
        if(salesOrderId != null){
            Sales_Order__c sales = new Sales_Order__c(Id = salesOrderId, Integration_Status__c = Utilities.INTEGRATION_FAILED , Sync_With_Pronto__c = false);
            Update sales;
            Utilities.logError(sales , ex , so_recordtype);
        }
        if(purchaseOrderId != null){
            Purchase_Order__c po = new Purchase_Order__c(Id = purchaseOrderId, Integration_Status__c = Utilities.INTEGRATION_FAILED , Sync_With_Pronto__c = false);
            Update po;
            Utilities.logError(po , ex , po_recordtype);
        }
    }
    
    
    /**
    * 
    @author: Cyrille Jeufo - Proquest Consulting
    @description: This method takes a Sales Order, retrieve its line items and serializes everything and invoke the callout helper
    @params: so = Sales Order
    * 
    */
    public static void postSalesOrderToPronto(Sales_Order__c so){
        Sales_Order__c soCopy = new Sales_Order__c(Id = so.Id, Integration_Status__c = Utilities.INTEGRATION_FAILED , Sync_With_Pronto__c = false);
        try{
            List<SalesOrder.SalesOrderItems> wrappeditems = new List< SalesOrder.SalesOrderItems>();
            for(Sales_Order_Line_Item__c soli : [Select Id, Description__c , Notes__c, Units__c , Work_Order_Line_Item__c, Item_Price__c , Order_Quantity__c  , Technician__c , Discount__c , Tax_Rate__c from Sales_Order_Line_Item__c WHERE Sales_Order__c =: so.Id]){
                wrappeditems.add(SalesOrder.SalesOrderItems.WrappedSOLI(soli));
            }
            SalesOrder soWrapped = SalesOrder.WrappedSO(so);
            
            soWrapped.contact_name = SyncWithProntoDAO.getSalesOrderContact(so);
            soWrapped.sales_order_items = wrappeditems;
            String payload = Json.serialize(soWrapped);
            payload = payload.replace('caseNumber', 'case');
            System.debug('Json.serialize(soWrapped) ' + payload);
            makeHTTPCallout(null , null , so.Id, null, null, payload, null, false);
            update soCopy;
        }catch (Exception ex){
            System.debug('@@@Exception ' + ex.getMessage());
            update soCopy;
            Utilities.logError(soCopy , ex , so_recordtype);
        }
    }

    
    /**
    * 
    @author: Imalka Fernando - Proquest Consulting
    @description: This method takes a Purchase Order, retrieve its line items and serializes everything and invoke the callout helper
    @params: po = Purchase Order
    * 
    */
    public static void postPurchaseOrderToPronto(Purchase_Order__c po){
        Purchase_Order__c poCopy = new Purchase_Order__c(Id = po.Id, Integration_Status__c = Utilities.INTEGRATION_FAILED , Sync_With_Pronto__c = false);
        try{
            getPurchaseOrderPayload(po);
            
            
            update poCopy;
        }catch (Exception ex){
            System.debug('@@@Exception ' + ex.getMessage());
            update poCopy;
            Utilities.logError(poCopy , ex , po_recordtype);
        }
    }

    public static void getPurchaseOrderPayload(Purchase_Order__c po){
        String payload = '';
        if(po.Status__c == Constants.PURCHASE_ORDER_STATUS_APPROVED){
            List<PurchaseOrder.PurchaseOrderItems> wrappeditems = new List<PurchaseOrder.PurchaseOrderItems>();
            for(Purchase_Order_Line_Item__c poli : [Select Id, POLI_Number__c, Supplier_Code__c, Quantity__c, Cost__c, Units__c, Tax_Rate__c, Date_Expected__c, Description__c From Purchase_Order_Line_Item__c Where Purchase_Order__c = :po.Id]){
                wrappeditems.add(PurchaseOrder.PurchaseOrderItems.WrappedPOLI(poli));
            }
            PurchaseOrder poWrapped = PurchaseOrder.WrappedPO(po);
            
            poWrapped.purchase_order_items = wrappeditems;
            payload = Json.serialize(poWrapped);
            System.debug('Json.serialize(soWrapped) ' + payload);
            makeHTTPCallout(null , null , null, po.Id, null, payload, null, false);
        }else if(po.Status__c == Constants.PURCHASE_ORDER_STATUS_CANCELLED){
            PurchaseOrderCancel poWrapped = PurchaseOrderCancel.WrappedPO(po);
            payload = Json.serialize(poWrapped);
            System.debug('Json.serialize(soWrapped) ' + payload);
            makeHTTPCallout(null , null , null, po.Id, null, payload, null, true);
        }
    }
    /**
    * 
    @author: Cyrille Jeufo - Proquest Consulting
    @description: This method takes an account, retrieve the name of the primary account (if any present), 
    retrieve nature of business values and invoke the callout helper
    @params: currentAcc - Sales record being synced 
    */
    public static void postCustomerToPronto(Account currentAcc) {
        try{
            List<Contact> contacts = new List<Contact>();
            
            Account acc = [Select Id , Account_Payable_Contact__c , Integration_Status__c , Sync_With_Pronto__c From Account where Id =: currentAcc.Id];
            
            if(acc.Account_Payable_Contact__c != null){
                contacts = [Select Id , Name from Contact where Id =:acc.Account_Payable_Contact__c];
            }
            
            Utilities.SupplierWrapper acw = Utilities.getWrappedAccount(currentAcc);
            
            for(Nature_of_Business__mdt nob : [SELECT Id, DeveloperName, Industry_Code__c FROM Nature_of_Business__mdt limit 50000]){
                if(acw.nature_of_business  == nob.DeveloperName ){
                    acw.nature_of_business = nob.Industry_Code__c;
                }else{
                    Error_log__c logRecord = new Error_log__c(Customer__c = currentAcc.Id, Message__c	= Utilities.INVALID_INDUSTRY_CODE +' ' + currentAcc.Name , recordTypeId = customer_recordtype, Status__c = 'Request Cancelled', Status_Code__c = '0',Subject__c ='Invalid request' );
                    acc.Integration_Status__c = Utilities.INTEGRATION_FAILED;
                    acc.Sync_With_Pronto__c = false;
                    update acc;
                }
            }
            
            List<ServiceTerritory> territory = [SELECT Id, Pronto_Territory_Code__c FROM ServiceTerritory where Id =: currentAcc.Service_Territory__c ];
            if(contacts.size() > 0){
                acw.contact_name = contacts[0].Name;
            }
            
            if(territory.size() > 0){
                acw.territory = territory[0].Pronto_Territory_Code__c;
                
                System.debug('$$$ Json.serialize(acw) ' +  Json.serialize(acw));
                makeHTTPCallout(null , String.valueOf(currentAcc.Id) , null , null, null, Json.serialize(acw), null, false);
            }else{
                System.debug('$$$No territory ');
                Error_log__c logRecord = new Error_log__c(Customer__c = currentAcc.Id, Message__c	= Utilities.TERRITORY_MISSING +' ' + currentAcc.Name , recordTypeId = customer_recordtype, Status__c = 'Request Cancelled', Status_Code__c = '0',Subject__c ='Invalid request' );
                acc.Integration_Status__c = Utilities.INTEGRATION_FAILED;
                acc.Sync_With_Pronto__c = false;
                update acc;
                insert logRecord; 
            }
            
        }catch (Exception ex){
            System.debug('$$$Exception ' + ex.getMessage());
            Account acc = new Account(Id = currentAcc.Id, Integration_Status__c = Utilities.INTEGRATION_FAILED , Sync_With_Pronto__c = false);
            update acc;
            Utilities.logError(acc , ex , customer_recordtype);
        }
        
    }
    
    /**
    * 
    @author: Imalka Fernando - Proquest Consulting
    @description: This method takes a Work Order Line Item and serializes everything and invoke the callout helper
    @params: woli = Work Order Line Item
    * 
    */
    public static void postWorkOrderLineItemToPronto(WorkOrderLineItem woli){
        Utilities.woliUpdateAllowed = true;
        WorkOrderLineItem woliCopy = new WorkOrderLineItem(Id = woli.Id, Integration_Status__c = Utilities.INTEGRATION_FAILED , Sync_With_Pronto__c = false);
        try{
            System.debug('@@@woli ' + woli);
            System.debug('@@@woli.Resource__r ' + woli.Resource__r);
            System.debug('@@@woli.Resource__r.related ' + woli.Resource__r.RelatedRecordId);
            Id userId = woli.Resource__r.RelatedRecordId;
            Map<Id,User> usersMap = UserDAO.getUsers(new Set<Id>{userId});
            Timesheet woliWrapped = Timesheet.WrappedWOLI(woli,usersMap.get(userId));
            
            String payload = Json.serialize(woliWrapped);
            System.debug('Json.serialize(woliWrapped) ' + payload);
            makeHTTPCallout(woli.Id , null , null, null, null, payload, woli.SA_Completed__c, false);
            update woliCopy;
        }catch (Exception ex){
            System.debug('@@@Exception ' + ex.getMessage());
            woliCopy.Integration_Status__c = Utilities.INTEGRATION_FAILED;
            update woliCopy;
            Utilities.logError(woliCopy , ex , so_recordtype);
        }
    }
    
    /**
    * 
    @author: Cyrille Jeufo - Proquest Consulting
    @description: The execute method determines which integration is running based on the context passed to the constructor
    and invokes the relevant methods
    @params: 
    @params: 
    * 
    */
    public void execute(QueueableContext contextIn) {
        if(context == 'WorkOrderLineItem'){
            try{
                if(validatePayroll == null){
                    List<WorkOrderLineItem> workOrderLineItem = WorkOrderLineItemDAO.getWorkOrderLineItemsUsingIds(currentWoli.Id);
                    System.debug('****workOrderLineItem.get(0).Within_Current_Payroll_Period__c:'+workOrderLineItem.get(0).Within_Current_Payroll_Period__c);
                    System.debug('****workOrderLineItem.get(0).Id:'+workOrderLineItem.get(0).Id);
                    if(workOrderLineItem.size() > 0 && workOrderLineItem.get(0).Within_Current_Payroll_Period__c){
                        postWorkOrderLineItemToPronto(workOrderLineItem.get(0));
                    }
                }else if(validatePayroll){
                    makeHTTPCallout(currentWoli.Id , null , null, null, true , null, currentWoli.SA_Completed__c, false);
                }else if(!validatePayroll){
                    makeHTTPCallout(currentWoli.Id , null , null, null, true , null, currentWoli.SA_Completed__c, false);
                }
            }catch(Exception ex){
                System.debug('@@@Exception ' + ex.getMessage());
                WorkOrderLineItem woli = new WorkOrderLineItem(Id = currentWoli.Id, Integration_Status__c = Utilities.INTEGRATION_FAILED , Sync_With_Pronto__c = false);
                update woli;
                Error_log__c logRecord = new Error_log__c(workOrderLineItem__c = currentWoli.Id , Message__c	= ex.getStackTraceString(), recordTypeId = transaction_recordtype, Status__c = 'Unexpected exception', Status_Code__c = '-1',Subject__c = ex.getMessage() );
                insert logRecord; 
            }
        }
        
        if(context == 'Account'){
            postCustomerToPronto(currentAccount);
        }
        
        if(context == 'SalesOrder'){
            postSalesOrderToPronto(currentSO);
        }

        if(context == 'PurchaseOrder'){
            postPurchaseOrderToPronto(currentPO);
        }
        
        
    }
}