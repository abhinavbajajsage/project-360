trigger PurchaseOrderTrigger on Purchase_Order__c (before update, after update) {
    Boolean isTriggerActive = FALSE;
    isTriggerActive = [SELECT Id, DeveloperName, Trigger_is_active__c FROM Trigger_Flag__mdt where developerName = 'PO_Settings'].Trigger_is_active__c;
    if(isTriggerActive){
        if(Trigger.isBefore &&  Trigger.isUpdate){
            PurchaseOrderTriggerHandler.checkTriggerPoints(Trigger.New , Trigger.OldMap);
        }
        
        if(Trigger.isAfter &&  Trigger.isUpdate){
            PurchaseOrderTriggerHandler.syncWithPronto(Trigger.new);
        }        
    }
}