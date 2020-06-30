/**
* 
@author: Imalka Fernando - Proquest Consulting
@description: This class retrieves all records matching a query passed from CleanupUserTerritoryScheduleJob and
			  those records will be deleted from the system
* 
*/
global class CleanupUserTerritoryBatchJob implements Database.Batchable<sObject> , Database.AllowsCallouts, Database.Stateful{
    global final String query;

    public CleanupUserTerritoryBatchJob(String queryIn) {
        query = queryIn;
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, 
                        List<sObject> scope){

        if(scope != null){
            for(SObject sobj : scope){
                ServiceTerritoryMember stm = (ServiceTerritoryMember)sobj;
                FSL__User_Territory__c utToDelete = new FSL__User_Territory__c(Id = stm.User_Territory__c);
                DeleteUserTerritory syncjob = new DeleteUserTerritory(utToDelete);
                ID jobID = System.enqueueJob(syncjob);
            }
        }
    }

    global void finish(Database.BatchableContext BC){
        
    }
}