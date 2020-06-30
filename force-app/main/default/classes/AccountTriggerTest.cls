/*******************************************************************************
* @author          Cyrille Jeufo (Proquest Consulting)
* @date            21.Nov.2019        
* @description     Testing the SupplierAPI class
• @revision 
• v1.0      - Refer purpose 
*******************************************************************************/
@IsTest
public class AccountTriggerTest{
    @isTest static void testWithNoTerritory(){
        
        id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Constants.ACC_COMPANY_RT).getRecordTypeId();
        
        Test.setMock(HttpCalloutMock.class, new CustomerHttpCalloutMock()); 
        List<Account> newAccounts = new List<Account>(); 
        newAccounts = TestDataUtility.createAccounts(1,accRecordTypeId, true);
        
        List<Contact> newContacts = new List<Contact>();
        newContacts = TestDataUtility.createContacts(1,newAccounts[0].id, false);
        newContacts.get(0).Email = 'pq@consulting.com';
        newContacts[0].Primary__c = true;
        insert newContacts;
        newAccounts[0].Integration_Status__c = 'Failed';
        newAccounts[0].Sync_With_Pronto__c = false;
        newAccounts[0].Account_Payable_Contact__c = newContacts[0].Id;
        Test.startTest();
        update newAccounts;
        Test.stopTest();
        Account acc = [Select Id From Account where Id =:newAccounts[0].Id ];
    }
    
    
    @isTest static void testWithTerritory(){
        
        id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Constants.ACC_COMPANY_RT).getRecordTypeId();
        
        Test.setMock(HttpCalloutMock.class, new CustomerHttpCalloutMock()); 
        
        List<Account> newAccounts = new List<Account>(); 
        newAccounts = TestDataUtility.createAccounts(1,accRecordTypeId, true);
        
        List<Contact> newContacts = new List<Contact>();
        newContacts = TestDataUtility.createContacts(1,newAccounts[0].id, false);
        newContacts.get(0).Email = 'pq@consulting.com';
        newContacts[0].Primary__c = true;
        insert newContacts;
        newAccounts[0].Integration_Status__c = 'Failed';
        newAccounts[0].Sync_With_Pronto__c = false;
        newAccounts[0].Account_Payable_Contact__c = newContacts[0].Id;
        
        List<OperatingHours> newOPs = new List<OperatingHours>(); 
        newOPs = TestDataUtility.createOperatingHour(1,'SA Operating hours', true);
        
        List<ServiceTerritory> newSTs = new List<ServiceTerritory>(); 
        newSTs = TestDataUtility.createSTerritories(1,'SA',newOPs[0].id , true);
        newSTs[0].Pronto_Territory_Code__c = '700';
        update newSTs;
        Test.startTest();
        newAccounts[0].Sync_With_Pronto__c = true;
        newAccounts[0].Service_Territory__c = newSTs[0].id;
        update newAccounts;
        Test.stopTest();
        Account acc = [Select Id,Integration_Status__c, Sync_With_Pronto__c From Account where Id =:newAccounts[0].Id ];
        
    }
    
}