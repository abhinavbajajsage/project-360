public with sharing class AggregateBillingFormatController {
    @AuraEnabled(cacheable=true)
    public static Map<String,Aggregate_Billing_Format__mdt> getBillingFormatsMap(){
        Map<String,Aggregate_Billing_Format__mdt> billingFormats = new Map<String,Aggregate_Billing_Format__mdt>();
        List<Aggregate_Billing_Format__mdt> formats = [Select MasterLabel,WO_Field_Name__c  From Aggregate_Billing_Format__mdt];
        for(Aggregate_Billing_Format__mdt abf : formats){
            billingFormats.put(abf.WO_Field_Name__c, abf);
        }
        return billingFormats;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String,Aggregate_Billing_Format__mdt> getBillingFormatsMapByMasterLabel(){
        Map<String,Aggregate_Billing_Format__mdt> billingFormats = new Map<String,Aggregate_Billing_Format__mdt>();
        List<Aggregate_Billing_Format__mdt> formats = [Select MasterLabel,WO_Field_Name__c  From Aggregate_Billing_Format__mdt];
        for(Aggregate_Billing_Format__mdt abf : formats){
            billingFormats.put(abf.MasterLabel, abf);
        }
        return billingFormats;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getBillingFormats(){
        List<Aggregate_Billing_Format__mdt> formats = [Select MasterLabel,WO_Field_Name__c  From Aggregate_Billing_Format__mdt];
        List<String> bFormats = new List<String>();
		for(Aggregate_Billing_Format__mdt abf : formats){
            bFormats.add(abf.MasterLabel);
        }        
        return bFormats;
    }
    
    @AuraEnabled
    public static ServiceContract saveServiceContract(ServiceContract contract,String billingFormat){
        System.debug('****billingFormat:'+billingFormat);
        List<BillingFormat> billingFormatList = (List<BillingFormat>)JSON.deserialize(billingFormat, List<BillingFormat>.class);
        Map<String,Aggregate_Billing_Format__mdt> formatMDT = getBillingFormatsMapByMasterLabel();
        String aggFormat = '';
        for(BillingFormat bFormat : billingFormatList){
            aggFormat += formatMDT.get(bFormat.value).WO_Field_Name__c+':'+bFormat.label+',';
        }
        contract.Aggregate_Billing_Format__c = aggFormat;
        upsert contract;
        return contract;
    }
    
    @AuraEnabled(cacheable=true)
    public static ServiceContract getServiceContract(Id contractId){
        List<ServiceContract> formats = [Select  Id,
                                                 Name,
                                                 Aggregate_Billing_Format__c,
                                                 Service_Territory__c,
                                                 AccountId
                                         From 	 ServiceContract Where Id = :contractId];
        return formats.get(0);
    }
    
    @AuraEnabled(cacheable=true)
    public static List<BillingFormat> getServiceContractBillingFormat(Id contractId){
        List<BillingFormat> bFormats = new List<BillingFormat>();
        List<ServiceContract> formats = [Select Id,Name,Aggregate_Billing_Format__c From ServiceContract Where Id = :contractId];
        Map<String,Aggregate_Billing_Format__mdt> formatMDT = getBillingFormatsMap();
        if(formats.size() > 0 && formats.get(0).Aggregate_Billing_Format__c != null){
            for(String fieldFormat : formats.get(0).Aggregate_Billing_Format__c.split(',')){
                List<String> ff = fieldFormat.split(':');
                String masterLabel = ff.size() > 0 ? formatMDT.get(ff.get(0)).MasterLabel : '';
                BillingFormat bf = new BillingFormat(masterLabel,(ff.size() > 1 ? ff.get(1) : ''));
                bFormats.add(bf);            
            }
        }
        System.debug(bFormats);
        return bFormats;
    }
    
    @AuraEnabled
    public static List<WorkOrder> getWorkOrderForContractWithStatus(Id contractId, String workOrderStatus){
        List<WorkOrder> wos = [SELECT id, 
                                             ServiceContractId, 
                                             ServiceContract.Name, 
                                             Use_Pre_purchased_Hours__c,
                                             Customer_Purchase_Order_number__c,
                                             WorkOrderNumber,
                                             Subject,
                                             Total_Billable_Hours__c,
                                             Materials_Total__c,
                                             Subtotal    
                                      FROM   WorkOrder 
                                      WHERE  ServiceContractId = :contractId
                              		  AND	 Status = :workOrderStatus
                              		  AND 	 Sales_Order__c = null];

        return wos;
    }
    
    @AuraEnabled
    public static Id createSalesOrder(ServiceContract contract,String workOrderIds){
        Sales_Order__c sOrder = null;
        
        String aggregateRecordTypeId = Schema.SObjectType.Sales_Order__c.getRecordTypeInfosByDeveloperName ().get('AggregatedBilling_SalesOrder_RT').getRecordTypeId();
        
        System.debug('****workOrderIds:'+workOrderIds);
        Set<Id> woIds = (Set<Id>)JSON.deserialize(workOrderIds, Set<Id>.class);
        System.debug('****woIds:'+woIds.size())    ; 
        
        try{
            if(woIds.size() > 0){
                List<WorkOrder> wOrders = WorkOrderDAO.getWorkOrdersUsingIds(woIds);
                sOrder = new Sales_Order__c(Account__c = contract.AccountId ,
                                                          Currency__c = 'AUD',
                                                          RecordTypeId = aggregateRecordTypeId,
                                                          Service_Contract__c = contract.Id,
                                                          Service_Territory__c = contract.Service_Territory__c,
                                                          Order_Date__c = System.today() );
                insert sOrder;
                System.debug('***sOrder:'+sOrder);
                List<Sales_Order_Line_Item__c> solItems = new List<Sales_Order_Line_Item__c>();
                for(WorkOrder wOrder : wOrders){
                    solItems.add(new Sales_Order_Line_Item__c(Work_Order__c = wOrder.Id,
                                                              Sales_Order__c   = sOrder.Id,
                                                              Description__c = wOrder.Subject,
                                                              Item_Code__c = 'Special (S)',
                                                              Order_Quantity__c = 1,
                                                              Tax_Rate__c = 10,
                                                              Units__c = 'EACH',
                                                              Item_Price__c = wOrder.Subtotal));
                    wOrder.Sales_Order__c = sOrder.Id;
                }
                System.debug('***solItems:'+solItems);
                if(solItems.size() > 0){
                    insert solItems;
                }
                update wOrders;
                
            }
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());  
        }
        return sOrder != null ? sOrder.Id : null;
    }
    
    public class BillingFormat{
        @AuraEnabled
        public String value {get; set;}
        @AuraEnabled
        public String label {get; set;}   
        
        public BillingFormat(String value, String label){
            this.value = value;
            this.label = label;
        }
        
       public BillingFormat(){
            this.value = '';
            this.label = '';            
        }
        
        public BillingFormat parse(String json) {
            return (BillingFormat) System.JSON.deserialize(json, BillingFormat.class);
        }
    }
    	
}