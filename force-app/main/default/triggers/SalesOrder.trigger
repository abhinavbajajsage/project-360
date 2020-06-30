trigger SalesOrder on Sales_Order__c (before insert , before update , after insert , after update, before delete) {
    Boolean isTriggerActive = FALSE;
    isTriggerActive = [SELECT Id, DeveloperName, Trigger_is_active__c FROM Trigger_Flag__mdt where developerName = 'SO_Settings'].Trigger_is_active__c;
    if(isTriggerActive){
        if(Trigger.isBefore &&  Trigger.isUpdate){
            SalesOrderTriggerHandler.checkTriggerPoints(Trigger.New , Trigger.OldMap);
        }
        
        if(Trigger.isAfter &&  Trigger.isUpdate){
            SalesOrderTriggerHandler.syncWithPronto(Trigger.new);
        } 
        
        if(Trigger.isDelete){
            SalesOrderTriggerHandler.salesOrderDelete(Trigger.old);
        }
    }
}