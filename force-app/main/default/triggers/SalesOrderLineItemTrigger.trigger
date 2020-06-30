trigger SalesOrderLineItemTrigger on Sales_Order_Line_Item__c (before insert) {
    Boolean isTriggerActive = FALSE;
    isTriggerActive = [SELECT Id, DeveloperName, Trigger_is_active__c FROM Trigger_Flag__mdt where developerName = 'SOLI_Settings'].Trigger_is_active__c;
    if(isTriggerActive){
        if(Trigger.isBefore &&  Trigger.isInsert){
            SalesOrderLineItemTriggerHandler.populateDescription(Trigger.New);
        }
    }
}