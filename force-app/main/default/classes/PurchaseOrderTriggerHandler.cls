public class PurchaseOrderTriggerHandler {
    //check if PO should be synced
    public static void checkTriggerPoints(List<Purchase_Order__c> newPurchaseOrders , Map<Id , Purchase_Order__c> oldPurchaseOrdersMap){
        for(Purchase_Order__c po : newPurchaseOrders){
                Purchase_Order__c oldPo = (Purchase_Order__c) oldPurchaseOrdersMap.get(po.Id);
                if(po.Sync_With_Pronto__c == true && oldPo.Sync_With_Pronto__c == false && (po.Integration_Status__c != Utilities.INTEGRATION_SUCCESSFUL && po.Integration_Status__c != Utilities.INTEGRATION_WAITING) && po.Status__c == Constants.PURCHASE_ORDER_STATUS_APPROVED){
                    po.Integration_Status__c = Utilities.INTEGRATION_PENDING;
                }else if(po.Status__c != oldPo.Status__c ){
                    if((po.Integration_Status__c != Utilities.INTEGRATION_SUCCESSFUL  && po.Integration_Status__c != Utilities.INTEGRATION_WAITING && po.Status__c == Constants.PURCHASE_ORDER_STATUS_APPROVED) ||
                        ((po.Integration_Status__c == Utilities.INTEGRATION_SUCCESSFUL || po.Integration_Status__c == Utilities.INTEGRATION_WAITING) && po.Status__c == Constants.PURCHASE_ORDER_STATUS_CANCELLED)){
                        po.Sync_With_Pronto__c = true;
                        po.Integration_Status__c = Utilities.INTEGRATION_PENDING;
                    }
                }else if(po.Sync_With_Pronto__c == true && oldPo.Sync_With_Pronto__c == false && po.Integration_Status__c == Utilities.INTEGRATION_SUCCESSFUL){
                    po.addError(System.Label.Record_Locked_CL);
                }else{
                    po.Sync_With_Pronto__c = false;
                }
        }
    }

    /**
    * synch with Pronto
    */
    public static void syncWithPronto(List<Purchase_Order__c> newPurchaseOrders){
        List<Purchase_Order__c> purchaseOrders = new List<Purchase_Order__c>();
        
        for(Purchase_Order__c po : newPurchaseOrders){
            if(po.Sync_With_Pronto__c == true ){
                if(Limits.getQueueableJobs() == Limits.getLimitQueueableJobs()) continue;
                SynchWithPronto syncjob = new SynchWithPronto(po , 'PurchaseOrder');
                ID jobID = System.enqueueJob(syncjob);
            }
        }
    }
}