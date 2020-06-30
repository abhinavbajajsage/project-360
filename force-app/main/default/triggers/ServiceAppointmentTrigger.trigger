trigger ServiceAppointmentTrigger on ServiceAppointment (before update, after update) {
    Boolean isTriggerActive = FALSE;
    isTriggerActive = [SELECT Id, DeveloperName, Trigger_is_active__c FROM Trigger_Flag__mdt where developerName = 'SA_Settings'].Trigger_is_active__c;
    if(isTriggerActive){

        if(Trigger.isBefore &&  Trigger.isUpdate){
            ServiceAppointmentTriggerHandler.saValidationforCompleteWO(Trigger.New , Trigger.OldMap);
            ServiceAppointmentTriggerHandler.saValidationForOpenPOs(Trigger.New , Trigger.OldMap);
        }  
    

        if(Trigger.isAfter &&  Trigger.isUpdate){
            ServiceAppointmentTriggerHandler.syncWithProntoForCompletion(Trigger.New , Trigger.OldMap);
        }        
    }
}