/*******************************************************************************
* @author          Kengo CHINEN (Proquest Consulting)
* @date            4.Dec.2019        
* @description     Sales Order generation for Contract Fees. This class handles creation of Sales Order  + Line Items
                   Errors are stored in Error Log object
• @revision 
• v1.0      - 

*******************************************************************************/

global class CreateContractFeesBatch implements Database.Batchable<sObject>, Database.Stateful {   
    
    // instance member to retain state across transactions
    global Integer recordsProcessed = 0;
    public Set<Id> processedContractIds = new Set<Id>();
    
    private String idParameter;
 
    public CreateContractFeesBATCH(String strParam) {
        idParameter = strParam;
    }
    

    
    // Get Sales Order records with line items that will be processed in the batch
    global Database.QueryLocator start(Database.BatchableContext bc) {

         String query ='';
         // if parameter is a Service Territory
         if(idParameter.startsWith('0Hh'))
             query = 'SELECT ID, Next_Contract_Billing_Date__c, Annual_Service_Amount__c, AccountId, Service_Territory__c, EndDate, Billing_Cycle_Type__c, StartDate,' +
            'Contract_Billing_Cycle__c, (SELECT ID, Description__c, Item_Code__c, Quantity__c,' +
            'Service_Contract__c, Service_Rate__c FROM Service_Contract_Line_Item__r) FROM ServiceContract ' + 
            'WHERE Next_Contract_Billing_Date__c = TODAY ' +
            'AND Service_Territory__c = \'' + idParameter +'\''+
            'LIMIT 50000';
         // if parameter is a Service Contract
         else if(idParameter.startsWith('810')){
             query = 'SELECT ID, Next_Contract_Billing_Date__c, Annual_Service_Amount__c, AccountId, Service_Territory__c, EndDate, Billing_Cycle_Type__c, StartDate,' +
            'Contract_Billing_Cycle__c, (SELECT ID, Description__c, Item_Code__c, Quantity__c,' +
            'Service_Contract__c, Service_Rate__c FROM Service_Contract_Line_Item__r) FROM ServiceContract ' + 
            'WHERE  Id = \'' + idParameter  +'\'';
         }               
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<ServiceContract> serviceContracts){

        // process each batch of records
        List<Sales_Order__c> soToCreate = new List<Sales_Order__c>();
        List<Error_log__c> errorToCreate = new List <Error_log__c>();
        Id contractFeesRTId = Schema.SObjectType.Sales_Order__c.getRecordTypeInfosByDeveloperName().get(Constants.SOR_DEV_ContractFees_RT).getRecordTypeId();
        Id errorContractFeesRTId = Schema.SObjectType.Error_Log__c.getRecordTypeInfosByDeveloperName().get(Constants.ERR_DEV_ContractFees_RT).getRecordTypeId();

        for (ServiceContract sc : serviceContracts) {
            if(!processedContractIds.contains(sc.id)){      
                Sales_Order__c so = new Sales_Order__c(Service_Contract__c = sc.id,
                                                       Account__c = sc.AccountId,
                                                       Service_Territory__c = sc.Service_Territory__c,
                                                       RecordTypeId = contractFeesRTId
                                                       );
                soToCreate.add(so);
                // increment the instance member counter
                recordsProcessed = recordsProcessed + 1;
                processedContractIds.add(sc.id);
            }
        }
        
        Map<Id,String> soGenerationErrorsMap = new Map <Id,String>();
        
        // Insert Sales Orders
        if(soToCreate.size()>0){
            database.saveresult[] soList = database.insert(soToCreate, false);
            
            for(Database.SaveResult sr : soList) {
                for (Integer i = 0; i < soToCreate.size(); i++) {
                    if(!sr.isSuccess()) {
    
                        // Operation failed, so get all errors               
                        for(Database.Error err : sr.getErrors()) {
                        
                            Error_log__c logRecord = new Error_log__c(
                                                         Message__c   = err.getMessage() + ' ' + Label.NewLine.replace('-','') + Label.ContractFees_SOError_CL + err.getFields() , 
                                                         recordTypeId = errorContractFeesRTId , 
                                                         Service_Contract__c = soToCreate[i].Service_Contract__c,
                                                         Status_Code__c = String.valueOf(err.statusCode)
                                                         ); 
                            errorToCreate.add(logRecord);                           
                            soGenerationErrorsMap.put(soToCreate[i].Service_Contract__c, String.valueOf(err.statusCode));
                        }
                    }
                }
            }
        } 
        
        Map <Id,Id> scTosoMap = new Map <Id, Id>(); 
        Map <Id,Id> soToscMap = new Map <Id, Id>(); 
        for(Sales_Order__c so :soToCreate){
            scTosoMap.put(so.Service_Contract__c,so.Id);
            soToscMap.put(so.Id, so.Service_Contract__c);
        }
        
        Map<String, Integer> dividedByMap = new Map<String, Integer>();
        dividedByMap.put(Constants.CYCLE_YEARLY, 1);
        dividedByMap.put(Constants.CYCLE_MONTHLY, 12);
        dividedByMap.put(Constants.CYCLE_QUATERLY, 4);
        dividedByMap.put(Constants.CYCLE_HALFYEARLY, 2);
        
        List<Sales_Order_Line_Item__c> soliToCreate = new List <Sales_Order_Line_Item__c>();
        List<ServiceContract> nextBillingDateUpdate = new List <ServiceContract>();
        for (ServiceContract sc : serviceContracts) {
            if(scTosoMap.get(sc.id)<> NULL){                
                boolean containsLineItem = false;
                
                // Scenario where the contract has a billing cycle
                if(sc.Contract_Billing_Cycle__c <> NULL && sc.Contract_Billing_Cycle__c <> 'None'){
    
                // Calculate Next billing Date based on the cycle            
                Date nextBillingDate;
                if(sc.Billing_Cycle_Type__c == Constants.CYCLE_TYPE_IN_ADVANCE){
                    if(sc.Contract_Billing_Cycle__c == Constants.CYCLE_YEARLY && soGenerationErrorsMap.get(sc.id)==NULL){
                        nextBillingDate = Date.newInstance(sc.Next_Contract_Billing_Date__c.year()+1, sc.Next_Contract_Billing_Date__c.month(), sc.StartDate.day());
                        if(nextBillingDate.day() <> sc.StartDate.day()){
                            nextBillingDate = Date.newInstance(sc.Next_Contract_Billing_Date__c.year(), sc.Next_Contract_Billing_Date__c.month(), sc.StartDate.day()).addYears(1);
                        }

                    }
                    if(sc.Contract_Billing_Cycle__c == Constants.CYCLE_HALFYEARLY && soGenerationErrorsMap.get(sc.id)==NULL){
                        nextBillingDate = Date.newInstance(sc.Next_Contract_Billing_Date__c.year(), sc.Next_Contract_Billing_Date__c.month()+6, sc.StartDate.day());
                        if(nextBillingDate.day() <> sc.StartDate.day()){
                            nextBillingDate = Date.newInstance(sc.Next_Contract_Billing_Date__c.year(), sc.Next_Contract_Billing_Date__c.month(), sc.StartDate.day()).addMonths(6);
                        }
                    }
                    if(sc.Contract_Billing_Cycle__c == Constants.CYCLE_QUATERLY && soGenerationErrorsMap.get(sc.id)==NULL){
                        nextBillingDate = Date.newInstance(sc.Next_Contract_Billing_Date__c.year(), sc.Next_Contract_Billing_Date__c.month()+3, sc.StartDate.day());
                        if(nextBillingDate.day() <> sc.StartDate.day()){
                            nextBillingDate = Date.newInstance(sc.Next_Contract_Billing_Date__c.year(), sc.Next_Contract_Billing_Date__c.month(), sc.StartDate.day()).addMonths(3);
                        }
                    }
                    if(sc.Contract_Billing_Cycle__c == Constants.CYCLE_MONTHLY && soGenerationErrorsMap.get(sc.id)==NULL){
                        nextBillingDate = Date.newInstance(sc.Next_Contract_Billing_Date__c.year(), sc.Next_Contract_Billing_Date__c.month()+1, sc.StartDate.day());
                        if(nextBillingDate.day() <> sc.StartDate.day()){
                            nextBillingDate = Date.newInstance(sc.Next_Contract_Billing_Date__c.year(), sc.Next_Contract_Billing_Date__c.month(), sc.StartDate.day()).addMonths(1);
                        }
                    }
                }
                if(sc.Billing_Cycle_Type__c == Constants.CYCLE_TYPE_IN_ARREARS){
                
                    if(sc.Contract_Billing_Cycle__c == Constants.CYCLE_YEARLY && soGenerationErrorsMap.get(sc.id)==NULL){
                        if(sc.StartDate.day()==1){
                            nextBillingDate = Date.newInstance(sc.Next_Contract_Billing_Date__c.year(), sc.Next_Contract_Billing_Date__c.month(), sc.StartDate.day()).addYears(1).addMonths(1)-1;
                        }   else{
                                nextBillingDate = Date.newInstance(sc.Next_Contract_Billing_Date__c.year()+1, sc.Next_Contract_Billing_Date__c.month(), sc.StartDate.day())-1;
                                if(nextBillingDate.day()<>sc.StartDate.day()-1){
                                    nextBillingDate = Date.newInstance(sc.Next_Contract_Billing_Date__c.year(), sc.Next_Contract_Billing_Date__c.month(), sc.StartDate.day()).addYears(1)-1;
                                }
                            }
                    }
                    if(sc.Contract_Billing_Cycle__c == Constants.CYCLE_HALFYEARLY && soGenerationErrorsMap.get(sc.id)==NULL){
                        if(sc.StartDate.day()==1){
                            nextBillingDate = Date.newInstance(sc.Next_Contract_Billing_Date__c.year(), sc.Next_Contract_Billing_Date__c.month(), sc.StartDate.day()).addMonths(7)-1;
                        }   else{
                                nextBillingDate = Date.newInstance(sc.Next_Contract_Billing_Date__c.year(), sc.Next_Contract_Billing_Date__c.month()+6, sc.StartDate.day())-1;
                                if(nextBillingDate.day()<>sc.StartDate.day()-1){
                                    nextBillingDate = Date.newInstance(sc.Next_Contract_Billing_Date__c.year(), sc.Next_Contract_Billing_Date__c.month(), sc.StartDate.day()).addMonths(6)-1;
                                }
                            }                      
                    }
                    if(sc.Contract_Billing_Cycle__c == Constants.CYCLE_QUATERLY && soGenerationErrorsMap.get(sc.id)==NULL){
                        if(sc.StartDate.day()==1){
                            nextBillingDate = Date.newInstance(sc.Next_Contract_Billing_Date__c.year(), sc.Next_Contract_Billing_Date__c.month(), sc.StartDate.day()).addMonths(4)-1;
                        }   else{
                                nextBillingDate = Date.newInstance(sc.Next_Contract_Billing_Date__c.year(), sc.Next_Contract_Billing_Date__c.month()+3, sc.StartDate.day())-1;
                                if(nextBillingDate.day()<>sc.StartDate.day()-1){
                                    nextBillingDate = Date.newInstance(sc.Next_Contract_Billing_Date__c.year(), sc.Next_Contract_Billing_Date__c.month(), sc.StartDate.day()).addMonths(3)-1;
                                }
                            }                      
                    }
                    if(sc.Contract_Billing_Cycle__c == Constants.CYCLE_MONTHLY && soGenerationErrorsMap.get(sc.id)==NULL){
                        if(sc.StartDate.day()==1){
                            nextBillingDate = Date.newInstance(sc.Next_Contract_Billing_Date__c.year(), sc.Next_Contract_Billing_Date__c.month(), sc.StartDate.day()).addMonths(2)-1;
                        }   else{
                                nextBillingDate = Date.newInstance(sc.Next_Contract_Billing_Date__c.year(), sc.Next_Contract_Billing_Date__c.month()+1, sc.StartDate.day())-1;
                                if(nextBillingDate.day()<>sc.StartDate.day()-1){
                                    nextBillingDate = Date.newInstance(sc.Next_Contract_Billing_Date__c.year(), sc.Next_Contract_Billing_Date__c.month(), sc.StartDate.day()).addMonths(1)-1;
                                }
                        }
                    }
                }
                
                // Update Next billing Date only when the date is still under the contract        
                if(nextBillingDate <= sc.EndDate && soGenerationErrorsMap.get(sc.id)==NULL){
                    sc.Next_Contract_Billing_Date__c = nextBillingDate;
                    nextBillingDateUpdate.add(sc);        
                } else if(soGenerationErrorsMap.get(sc.id)==NULL){
                    // Clear Next Contract Billing Date on Service Contract so no future Sales Order will be created
                    sc.Next_Contract_Billing_Date__c = NULL;
                    nextBillingDateUpdate.add(sc);
                }
                
                
                    // Create Sales Order Line Items based on Service Contract Line Items
                    for (Service_Contract_Line_Item__c scli : sc.Service_Contract_Line_Item__r) {
    
                        Sales_Order_Line_Item__c soli = createSoli(scli);
                        soli.Item_Price__c = soli.Item_Price__c / dividedByMap.get(sc.Contract_Billing_Cycle__c);
                        soli.Sales_Order__c = scTosoMap.get(sc.id);
                        soliToCreate.add(soli);
                        containsLineItem = true;
                    }
    
                    // Create Sales Order Line Item when there is no line item on the contract
                    if(containsLineItem == false){   
                    Sales_Order_Line_Item__c soli = createSoliForContractWithoutLines(sc);
                        soli.Sales_Order__c = scTosoMap.get(sc.id);
                        soli.Item_Price__c = sc.Annual_Service_Amount__c /  dividedByMap.get(sc.Contract_Billing_Cycle__c) ;
                        soliToCreate.add(soli);
                    }
                }
            processedContractIds.add(sc.id);   
            }
        }    
        
        Map<Id,String> soLineInsertErrorsMap = new Map <Id,String>();
        // Insert Sales Orders Line Items
        if(soliToCreate.size()>0){
            database.saveresult[] soliList = database.insert(soliToCreate, false);
            for(Database.SaveResult sr : soliList) {
                for (Integer i = 0; i < soliToCreate.size(); i++) {
                    if(!sr.isSuccess()) {
    
                        // Operation failed, so get all errors               
                        for(Database.Error err : sr.getErrors()) {
                        
                            Error_log__c logRecord = new Error_log__c(
                                                         Message__c   = err.getMessage() +  ' ' + Label.NewLine.replace('-','')+ Label.ContractFees_SOLIError_CL + err.getFields() , 
                                                         recordTypeId = errorContractFeesRTId , 
                                                         Service_Contract__c = soToscMap.get(soliToCreate[i].Sales_Order__c),
                                                         Status_Code__c = String.valueOf(err.statusCode)
                                                         ); 
                            errorToCreate.add(logRecord);
                            soLineInsertErrorsMap.put(soToscMap.get(soliToCreate[i].Sales_Order__c), String.valueOf(err.statusCode));
                        }
                    }
                }
            }
        } 
        // delete created Sales Order for which the line item had an issue and could not be generated
        // remove from contract to be updated with the next billing date the one with a line item issue
        List<Sales_Order__c> deleteSalesOrder = new List <Sales_Order__c>();
        List<ServiceContract> contractUpdateList = new List <ServiceContract>();

        for(Sales_Order__c so :soToCreate){
            if(soLineInsertErrorsMap.get(so.Service_Contract__c)<> NULL){
                deleteSalesOrder.add(so);
            }
        }
        for(ServiceContract sc :nextBillingDateUpdate){
            if(soLineInsertErrorsMap.get(sc.id)== NULL){
                contractUpdateList.add(sc);
            }
        }
        
        
        if(deleteSalesOrder.size()>0){
            delete deleteSalesOrder;
        }
        
  
        // Update Service Contract Next billing Date
        if(contractUpdateList.size()>0){
            database.saveresult[] scList = database.update(contractUpdateList, false);
            
            for(Database.SaveResult sr : scList) {
                for (Integer i = 0; i < scList.size(); i++) {
                    if(!sr.isSuccess()) {                   
                        // Operation failed, so get all errors               
                        for(Database.Error err : sr.getErrors()) {      
                            Error_log__c logRecord = new Error_log__c(
                                                         Message__c   = err.getMessage() + ' ' + Label.NewLine.replace('-','') +Label.ContractFees_NextBillingDateError_CL + err.getFields() , 
                                                         recordTypeId = errorContractFeesRTId , 
                                                         Service_Contract__c = contractUpdateList[i].Id,
                                                         Status_Code__c = String.valueOf(err.statusCode)
                                                         ); 
                            errorToCreate.add(logRecord);
                        }
                    }
                }
            }
        } 
        if(errorToCreate.size()>0){
            insert errorToCreate;
        }
        
    }    
    global void finish(Database.BatchableContext bc){
        System.debug(recordsProcessed + '**records processed**');
    }  
    
    public static Sales_Order_Line_Item__c createSoli(Service_Contract_Line_Item__c scli) {    
        Sales_Order_Line_Item__c soli = new Sales_Order_Line_Item__c(
                                            Order_Quantity__c = scli.Quantity__c,
                                            Description__c = Label.ContractFees_LineDescription_CL + ' ' + scli.Item_Code__c,
                                            Item_Code__c = 'Special (S)' ,
                                            Units__c = Constants.UNITS_EACH,
                                            Item_Price__c = scli.Service_Rate__c  
                                        );
        return soli;
    } 
    public static Sales_Order_Line_Item__c createSoliForContractWithoutLines(ServiceContract sc) {    
        Sales_Order_Line_Item__c soli = new Sales_Order_Line_Item__c(
                                            
                                            Order_Quantity__c = 1,
                                            Description__c = Label.ContractFees_LineDescription_CL ,
                                            Item_Code__c = 'Special (S)' ,
                                            Units__c = Constants.UNITS_EACH,
                                            Item_Price__c = sc.Annual_Service_Amount__c
                                        );
        return soli; 
    }   
}