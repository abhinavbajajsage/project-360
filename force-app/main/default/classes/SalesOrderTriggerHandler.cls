public class SalesOrderTriggerHandler {
	private static String salesOrderRecordtypeId = Schema.SObjectType.Sales_Order__c.getRecordTypeInfosByDeveloperName ().get('WorkOrder_SalesOrder_RT').getRecordTypeId();
    
    //check if SO should be synced
    public static void checkTriggerPoints(List<Sales_Order__c> newSalesOrders , Map<Id , Sales_Order__c> oldSalesOrdersMap){
        for(Sales_Order__c so : newSalesOrders){
                Sales_Order__c oldSo = (Sales_Order__c) oldSalesOrdersMap.get(so.Id);
                if(so.Sync_With_Pronto__c == true && oldSo.Sync_With_Pronto__c == false && (so.Integration_Status__c != Utilities.INTEGRATION_SUCCESSFUL  && so.Integration_Status__c != Utilities.INTEGRATION_WAITING) && so.Days_till_Integration__c == 0){
                    so.Integration_Status__c = Utilities.INTEGRATION_PENDING;
                }else if(so.Sync_With_Pronto__c == true && oldSo.Sync_With_Pronto__c == false && so.Integration_Status__c == Utilities.INTEGRATION_SUCCESSFUL){
                    so.addError(System.Label.Record_Locked_CL);
                }else{
                    so.Sync_With_Pronto__c = false;
                }
        }
    }
    
    /**
    * synch with Pronto
    */
    public static void syncWithPronto(List<Sales_Order__c> newSalesOrders){
        List<Sales_Order__c> salesOrders = new List<Sales_Order__c>();
        
        for(Sales_Order__c so : newSalesOrders){
            System.debug('$$$After Trigger SO ' + so);
                if(so.Sync_With_Pronto__c == true ){
                    //if(Limits.getQueueableJobs() == Limits.getLimitQueueableJobs()) continue;
                    SynchWithPronto syncjob = new SynchWithPronto(so , 'SalesOrder');
                    ID jobID = System.enqueueJob(syncjob);
                }
        }
    }
    
    /**
    * check Sales Order delete
    */
    public static void salesOrderDelete(List<Sales_Order__c> oldSalesOrders){
        String aggregateBillingRecTypeId = Schema.SObjectType.Sales_Order__c.getRecordTypeInfosByDeveloperName().get('AggregatedBilling_SalesOrder_RT').getRecordTypeId();
        Id profileId = [Select Id From Profile Where Name='NOC Admin'].get(0).Id;
        for(Sales_Order__c so : oldSalesOrders){
            if(so.RecordTypeId != aggregateBillingRecTypeId && (so.Integration_Status__c == Utilities.INTEGRATION_SUCCESSFUL ||  so.Integration_Status__c == Utilities.INTEGRATION_WAITING) && UserInfo.getProfileId() == profileId){
                so.addError(System.Label.Sales_Order_Delete_CL);
            }
        }
    }
    
}