/**
* 
@author: Imalka Fernando - Proquest Consulting
@description: This class handles the cleanup of user territory records for expired service territory member records
* 
*/
global class CleanupUserTerritoryScheduleJob implements Schedulable {
    global void execute(SchedulableContext ctx) {
        CleanupUserTerritoryBatchJob batchJob = new CleanupUserTerritoryBatchJob('Select Id, User_Territory__c From ServiceTerritoryMember Where User_Territory__c != null AND EffectiveEndDate <= TODAY');
        ID batchprocessid = Database.executeBatch(batchJob , 1);
    }
}