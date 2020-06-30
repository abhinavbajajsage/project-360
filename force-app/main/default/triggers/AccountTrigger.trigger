/**
* 
@author: Cyrille Jeufo - Proquest Consulting
@initial version: 18/11/2019 - Initial version - Logic determines whether to make a callout or not
* 
*/
trigger AccountTrigger on Account (before insert , before update , after insert , after update) {
    Boolean isTriggerActive = FALSE;
    isTriggerActive = [SELECT Id, DeveloperName, Trigger_is_active__c FROM Trigger_Flag__mdt where developerName = 'Account_Settings'].Trigger_is_active__c;
    
    if(isTriggerActive) {
        if(Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert )){
            AccountTriggerHandler.checkAccountTriggerPoints(Trigger.New , Trigger.OldMap);
        }
        
        
        if(Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert )){
           AccountTriggerHandler.syncWithPronto(Trigger.New, Trigger.newMap);
        }
    }
    
}