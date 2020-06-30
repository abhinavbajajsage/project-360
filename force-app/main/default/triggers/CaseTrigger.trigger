trigger CaseTrigger on Case (before insert) {
    Boolean isTriggerActive = FALSE;
    isTriggerActive = [SELECT Id, DeveloperName, Trigger_is_active__c FROM Trigger_Flag__mdt where developerName = 'Case_Settings'].Trigger_is_active__c;
    
    if(isTriggerActive) {
        if(Trigger.isBefore && Trigger.isInsert){
            CaseTriggerHandler.populateOutsideBusinessHours(Trigger.new);
        }
    }
}