/**
* 
@author: Cyrille Jeufo - Proquest Consulting
@description: This class handles the retry logic of all the integration built during Phase 2
			  It retrieves all records stored on the Batch_Settings__mdt object and invokes the batch method
* 
*/
global class SyncWithProntoJob implements Schedulable {
    global void execute(SchedulableContext ctx) {
        List<Batch_Settings__mdt> bSettings = [SELECT Id, Batch_Query__c, DeveloperName FROM Batch_Settings__mdt limit 1000];
        if(bSettings.size() > 0){
            for(Batch_Settings__mdt bSetting : bSettings)  {
                if(String.isNotBlank(bSetting.Batch_Query__c)){
                    SyncWithProntoBatch batchJob = new SyncWithProntoBatch(bSetting.Batch_Query__c);
                    ID batchprocessid = Database.executeBatch(batchJob , 1);
                }
            }          
        }
    }
    
}