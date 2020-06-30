trigger ServiceTerritoryMemberTrigger on ServiceTerritoryMember (after insert, after update, before delete) {
    Boolean isTriggerActive = FALSE;
    isTriggerActive = [SELECT Id, DeveloperName, Trigger_is_active__c FROM Trigger_Flag__mdt where developerName = 'STM_Settings'].Trigger_is_active__c;
    if(isTriggerActive){
        if(Trigger.isAfter){
            if(Trigger.isInsert || Trigger.isUpdate){
                ServiceTerritoryMemberTriggerHandler.syncUserTerritoryRecords(Trigger.new, Trigger.oldMap);
            }
        }
        if(Trigger.isBefore && Trigger.isDelete){
            ServiceTerritoryMemberTriggerHandler.syncUserTerritoryRecords(null, Trigger.oldMap);        
        }     
    }
}