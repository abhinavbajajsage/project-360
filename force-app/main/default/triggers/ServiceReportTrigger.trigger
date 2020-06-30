trigger ServiceReportTrigger on ServiceReport (after insert) {

    if(Trigger.isInsert){
        if(Trigger.isAfter){
            ServiceReportHandler.sendServiceReportToContractContact(Trigger.new);
        }
    }

}