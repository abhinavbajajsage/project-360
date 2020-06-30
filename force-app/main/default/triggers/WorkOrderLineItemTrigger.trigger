trigger WorkOrderLineItemTrigger on WorkOrderLineItem (before insert, before update , after insert , after update) {
    Boolean isTriggerActive = FALSE;
    isTriggerActive = [SELECT Id, DeveloperName, Trigger_is_active__c FROM Trigger_Flag__mdt where developerName = 'WOLI_Settings'].Trigger_is_active__c;
    if(isTriggerActive){
       if(Trigger.isInsert){
            if(Trigger.isBefore){
                WorkOrderLineItemHandler.updateCreatedTransaction(Trigger.new, NULL);
                WorkOrderLineItemHandler.validateStartDate(Trigger.New , Trigger.OldMap);
            }
            if(Trigger.isAfter){
                WorkOrderLineItemHandler.createSplittedTransaction(Trigger.new, NULL);
                WorkOrderLineItemHandler.syncWithPronto(Trigger.newMap, NULL,true);    
            }   
            
        }
       if(Trigger.isUpdate){
            if(Trigger.isBefore){
                WorkOrderLineItemHandler.lockWorkOrderLineItem(Trigger.new, Trigger.OldMap);
                WorkOrderLineItemHandler.updateCreatedTransaction(Trigger.new, Trigger.OldMap);
                WorkOrderLineItemHandler.validateStartDate(Trigger.New , Trigger.OldMap);
            }
            if(Trigger.isAfter){
                WorkOrderLineItemHandler.updateSOLI(Trigger.new, Trigger.OldMap);
                WorkOrderLineItemHandler.createSplittedTransaction(Trigger.new, Trigger.OldMap);
                WorkOrderLineItemHandler.syncWithPronto(Trigger.newMap, Trigger.OldMap, true);    
            }   
            
        }
    }
    
}