trigger ContactTrigger on Contact (before update) {
    if(Trigger.isBefore && Trigger.isUpdate){
        ContactTriggerHandler.checkContactEmailUpdated(Trigger.new, Trigger.oldMap);
    }
}