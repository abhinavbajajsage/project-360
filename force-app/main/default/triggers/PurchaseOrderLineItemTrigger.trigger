trigger PurchaseOrderLineItemTrigger on Purchase_Order_Line_Item__c (before insert, before update) {
    Boolean isTriggerActive = FALSE;
    isTriggerActive = [SELECT Id, DeveloperName, Trigger_is_active__c FROM Trigger_Flag__mdt where developerName = 'POLI_Settings'].Trigger_is_active__c;
    if(isTriggerActive){
        if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
            //PurchaseOrderLineItemTriggerHandler.calculateActualHours(Trigger.new, Trigger.oldMap);
        }      
    }
   
}