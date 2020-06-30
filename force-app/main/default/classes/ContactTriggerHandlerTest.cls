@isTest
public class ContactTriggerHandlerTest {
    static testmethod void serviceAppointmentCompletionTest(){
        id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Constants.ACC_COMPANY_RT).getRecordTypeId();
        
        List<OperatingHours> newOPs = new List<OperatingHours>(); 
        newOPs = TestDataUtility.createOperatingHour(1,'SA Operating hours', true);
                
        List<ServiceTerritory> newSTs = new List<ServiceTerritory>(); 
        newSTs = TestDataUtility.createSTerritories(1,'SA',newOPs[0].id , true);
         
        List<Account> newAccounts = new List<Account>(); 
        newAccounts = TestDataUtility.createAccounts(1,accRecordTypeId, false);
        newAccounts[0].Service_Territory__c = newSTs[0].id;
        insert newAccounts;

        List<Contact> newContacts = new List<Contact>();
        newContacts = TestDataUtility.createContacts(1,newAccounts[0].id, false);
        newContacts.get(0).Email = 'pq@consulting.com';
        insert newContacts;

        //update account details
        newAccounts[0].Account_Payable_Contact__c  = newContacts[0].Id;
        update newAccounts;
        
        List<Product2> newProducts = new List<Product2>(); 
        newProducts = TestDataUtility.createProducts(12 , 'Test', false);
        newProducts[0].Resource_Type__c =  Constants.TYPE_TECHNICIAN;
        newProducts[0].Service_Time__c  =  Constants.SERVICE_BUSINESS;
        newProducts[0].Contract_Type__c =  Constants.TYPE_SILVER;
        newProducts[1].Resource_Type__c =  Constants.TYPE_TECHNICIAN;
        newProducts[1].Service_Time__c  =  Constants.SERVICE_OVERTIME;   
        newProducts[1].Contract_Type__c =  Constants.TYPE_SILVER ;
        newProducts[2].Resource_Type__c =  Constants.TYPE_TECHNICIAN;
        newProducts[2].Service_Time__c  =  Constants.SERVICE_NIGHT;   
        newProducts[2].Contract_Type__c =  Constants.TYPE_SILVER;      
        newProducts[3].Resource_Type__c =  Constants.TYPE_ENGINEER;
        newProducts[3].Service_Time__c  =  Constants.SERVICE_BUSINESS;
        newProducts[3].Contract_Type__c =  Constants.TYPE_SILVER;
        newProducts[4].Resource_Type__c =  Constants.TYPE_ENGINEER;
        newProducts[4].Service_Time__c  =  Constants.SERVICE_OVERTIME;   
        newProducts[4].Contract_Type__c =  Constants.TYPE_SILVER ;
        newProducts[5].Resource_Type__c =  Constants.TYPE_ENGINEER;
        newProducts[5].Service_Time__c  =  Constants.SERVICE_NIGHT;   
        newProducts[5].Contract_Type__c =  Constants.TYPE_SILVER;     
        insert newProducts;   
        
        Pricebook2 pricebook = new Pricebook2 (Name = 'Silver PB', IsActive = true, Service_Territory__c = newSTs[0].id, Contract_Type__c = Constants.TYPE_SILVER);
        
        insert pricebook;
        
        Pricebook2 Standardpricebook = new Pricebook2( id = Test.getStandardPricebookId());
        update Standardpricebook ; 
        
        System.AssertNotEquals(NULL, Standardpricebook.id);
        
        List <PricebookEntry> pbEntries = new List <PricebookEntry>();
        Decimal unitPrice = 100;
        
        for(Product2 p :newProducts){        
            PricebookEntry entry = new PricebookEntry (Pricebook2Id = Standardpricebook.id, Product2id = p.id, UnitPrice =unitPrice, IsActive = true, Usage_per_hour__c =1.5 );
            unitPrice = unitPrice +1;
            pbEntries.add(entry);     
        }
        insert pbEntries;   
        
        for(Product2 p :newProducts){        
            PricebookEntry entry = new PricebookEntry (Pricebook2Id = pricebook.id, Product2id = p.id, UnitPrice =unitPrice, IsActive = true, Usage_per_hour__c =1.5 );
            unitPrice = unitPrice +1;
            pbEntries.add(entry);     
        }
        upsert pbEntries;    
        
        BusinessHours normalTimeBH  = BusinessHoursDAO.getBUUsingName('Adelaide Time: 07:30-16:00 Mon-Fri');        
        BusinessHours overtimeBH    = BusinessHoursDAO.getBUUsingName('Adelaide Time: 16:00-00:00 Mon-Fri 7:30-00:00 Sat-Sun'); 
        BusinessHours nighttimeBH   = BusinessHoursDAO.getBUUsingName('Adelaide Time: 00:00-07:30 Mon-Sun'); 
        
        BusinessHours normalTimeBH2 = BusinessHoursDAO.getBUUsingName('Adelaide Time: 06:00-18:00 Mon-Fri');    
        BusinessHours overtimeBH2   = BusinessHoursDAO.getBUUsingName('Adelaide Time: Any time after Business Hours');         
        
        List<ServiceContract> newServiceContracts = new List<ServiceContract>();
        newServiceContracts = TestDataUtility.createServiceContract(1, newAccounts[0].id, newContacts[0].id, newSTs[0].id, false);
        newServiceContracts[0].Normal_Time__c = normalTimeBH.id;
        newServiceContracts[0].Overtime__c = overtimeBH.id;
        newServiceContracts[0].Night_Time__c = nighttimeBH.id;
        newServiceContracts[0].Type__c = Constants.TYPE_SILVER;
        newServiceContracts[0].Number_of_Pre_Purchased_Hours__c = 0;
        newServiceContracts[0].Service_Territory__c =newSTs[0].id;
        newServiceContracts[0].Next_Contract_Billing_Date__c = System.Today();
        newServiceContracts[0].Annual_Service_Amount__c = 12000;
        newServiceContracts[0].Contract_Billing_Cycle__c = Constants.CYCLE_MONTHLY;
        newServiceContracts[0].Billing_Cycle_Type__c = Constants.CYCLE_TYPE_IN_ADVANCE;
        insert newServiceContracts;
                        
         
        Test.startTest();
            newContacts[0].Email = '';
            try{
                update newContacts;
            }catch(DmlException ex){
                System.assertEquals(String.format(System.Label.Contact_Email_Required_CL, new List<String> {'Bronze Contract0'}), ex.getDmlMessage(0));
            }
        Test.stopTest();
        
    }
}