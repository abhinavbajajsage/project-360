@isTest
public class ServiceTerritoryMemberTriggerHandlerTest {
    static testmethod void testUserTerritoryRecords(){
        List<OperatingHours> newOPs = new List<OperatingHours>(); 
        newOPs = TestDataUtility.createOperatingHour(1,'SA Operating hours', true);
                
        List<ServiceTerritory> newSTs = new List<ServiceTerritory>(); 
        newSTs = TestDataUtility.createSTerritories(1,'SA',newOPs[0].id , true);

        List<User> newUsers = new List<User>(); 
        newUsers = TestDataUtility.createUsers(2, true);      
        
        List<ServiceResource> newSR1 = TestDataUtility.createServiceResource(1, newUsers[0].id, true); 
        List<ServiceResource> newSR2 = TestDataUtility.createServiceResource(1, newUsers[1].id, true);
        
        Test.startTest();     
            List<ServiceTerritoryMember> stmList = new List<ServiceTerritoryMember>();
            stmList.add(new ServiceTerritoryMember(ServiceTerritoryId = newSTs[0].Id, ServiceResourceId = newSR1[0].Id, EffectiveStartDate = System.today()));
            insert stmList;
            List<FSL__User_Territory__c> userTer = [Select Id, FSL__ServiceTerritory__c, FSL__User__c From FSL__User_Territory__c Where FSL__ServiceTerritory__c = :newSTs[0].Id AND FSL__User__c = :newUsers[0].id];
            System.assert(userTer.size() == 1);
            stmList[0].ServiceResourceId = newSR2[0].Id;
            update stmList;
            userTer = [Select Id, FSL__ServiceTerritory__c, FSL__User__c From FSL__User_Territory__c Where FSL__ServiceTerritory__c = :newSTs[0].Id AND FSL__User__c = :newUsers[1].id];
            System.assert(userTer.size() == 1);
            delete stmList;
            userTer = [Select Id, FSL__ServiceTerritory__c, FSL__User__c From FSL__User_Territory__c Where FSL__ServiceTerritory__c = :newSTs[0].Id AND FSL__User__c = :newUsers[1].id];
            System.assert(userTer.size() == 0);

            stmList = new List<ServiceTerritoryMember>();
            stmList.add(new ServiceTerritoryMember(ServiceTerritoryId = newSTs[0].Id, ServiceResourceId = newSR1[0].Id, EffectiveStartDate = System.today().addDays(-5), EffectiveEndDate = System.today()));
            insert stmList;
            CleanupUserTerritoryScheduleJob sh1 = new CleanupUserTerritoryScheduleJob();

            String sch = '0 0 23 * * ?'; 
            system.schedule('Test Delete User Territories', sch, sh1); 

            CleanupUserTerritoryBatchJob batchJob = new CleanupUserTerritoryBatchJob('Select Id, User_Territory__c From ServiceTerritoryMember Where User_Territory__c != null AND EffectiveEndDate <= TODAY');
            ID batchprocessid = Database.executeBatch(batchJob , 1);
        Test.stopTest();

        List<FSL__User_Territory__c>  delUserTer = [Select Id, FSL__ServiceTerritory__c, FSL__User__c From FSL__User_Territory__c];
        System.assert(delUserTer.size() == 0);
    }
}