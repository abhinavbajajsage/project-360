@isTest
private class CreateContractFeesBatchTest {
    @testSetup 
    static void setup() {
        id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Constants.ACC_COMPANY_RT).getRecordTypeId();
 
        List<Account> newAccounts = new List<Account>(); 
        newAccounts = TestDataUtility.createAccounts(2,accRecordTypeId, true);
        
        List<Contact> newContacts = new List<Contact>();
        newContacts = TestDataUtility.createContacts(1,newAccounts[0].id, false);
        newContacts.get(0).Email = 'pq@consulting.com';
        insert newContacts;
        
        List<Contact> newContacts2 = new List<Contact>();
        newContacts = TestDataUtility.createContacts(1,newAccounts[1].id, false);
        newContacts.get(0).Email = 'pq@consulting.com';
        insert newContacts2;

        List<OperatingHours> newOPs = new List<OperatingHours>(); 
        newOPs = TestDataUtility.createOperatingHour(1,'SA Operating hours', true);
                
        
        ServiceTerritory territory = new ServiceTerritory(OperatingHoursId =newOPs[0].id, Name ='SA');
        insert territory;
        
        /*  List<ServiceTerritory> newSTs = new List<ServiceTerritory>(); 
        newSTs = TestDataUtility.createSTerritories(1,'SA',newOPs[0].id , true);
        newSTs[0].Name = 'SA';
        Update newSTs; */
        
        List<Product2> newProducts = new List<Product2>(); 
        newProducts = TestDataUtility.createProducts(12 , 'Test', false);
        newProducts[0].Resource_Type__c =  Constants.TYPE_TECHNICIAN;
        newProducts[0].Service_Time__c  =  Constants.SERVICE_BUSINESS;
        newProducts[0].Contract_Type__c =  Constants.TYPE_SILVER;    
        insert newProducts;   
        
        Pricebook2 pricebook = new Pricebook2 (Name = 'Sil PB', IsActive = true, Service_Territory__c = territory.id, Contract_Type__c = Constants.TYPE_SILVER);
        
        insert pricebook;
        
        Pricebook2 Standardpricebook = new Pricebook2( id = Test.getStandardPricebookId());
        update Standardpricebook ; 
        
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
        
        // Retrieve Business Hours
        BusinessHours normalTimeBH  = BusinessHoursDAO.getBUUsingName('Adelaide Time: 07:30-16:00 Mon-Fri');        
        BusinessHours overtimeBH    = BusinessHoursDAO.getBUUsingName('Adelaide Time: 16:00-00:00 Mon-Fri 7:30-00:00 Sat-Sun'); 
        BusinessHours nighttimeBH   = BusinessHoursDAO.getBUUsingName('Adelaide Time: 00:00-07:30 Mon-Sun'); 
        
        BusinessHours normalTimeBH2 = BusinessHoursDAO.getBUUsingName('Adelaide Time: 06:00-18:00 Mon-Fri');    
        BusinessHours overtimeBH2   = BusinessHoursDAO.getBUUsingName('Adelaide Time: Any time after Business Hours');         
        
        // Create Service Contract
        List<ServiceContract> newServiceContracts = new List<ServiceContract>();
        newServiceContracts = TestDataUtility.createServiceContract(2, newAccounts[0].id, newContacts[0].id, territory.id, false);
        newServiceContracts[0].Normal_Time__c = normalTimeBH.id;
        newServiceContracts[0].Overtime__c = overtimeBH.id;
        newServiceContracts[0].Night_Time__c = nighttimeBH.id;
        newServiceContracts[0].Type__c = Constants.TYPE_SILVER;
        newServiceContracts[0].Number_of_Pre_Purchased_Hours__c = 0;
        newServiceContracts[0].Service_Territory__c = territory.id;
        newServiceContracts[0].Next_Contract_Billing_Date__c = System.Today();
        newServiceContracts[0].Annual_Service_Amount__c = 12000;
        newServiceContracts[0].Contract_Billing_Cycle__c = Constants.CYCLE_MONTHLY;
        newServiceContracts[0].Billing_Cycle_Type__c = Constants.CYCLE_TYPE_IN_ADVANCE;
        
        newServiceContracts[1].AccountId = newAccounts[1].id;
        newServiceContracts[1].Normal_Time__c = normalTimeBH.id;
        newServiceContracts[1].Overtime__c = overtimeBH.id;
        newServiceContracts[1].Night_Time__c = nighttimeBH.id;
        newServiceContracts[1].Type__c = Constants.TYPE_SILVER;
        newServiceContracts[1].Number_of_Pre_Purchased_Hours__c = 0;
        newServiceContracts[1].Service_Territory__c = territory.id;
        newServiceContracts[1].Next_Contract_Billing_Date__c = System.Today();
       newServiceContracts[1].Annual_Service_Amount__c = 12000;
        newServiceContracts[1].Contract_Billing_Cycle__c = Constants.CYCLE_QUATERLY;
        newServiceContracts[1].Billing_Cycle_Type__c = Constants.CYCLE_TYPE_IN_ADVANCE;
        insert newServiceContracts;
        
        //Create Service Contract line item only for 1 contract
        Service_Contract_Line_Item__c scli = new Service_Contract_Line_Item__c (Quantity__c =1, Service_Contract__c= newServiceContracts[1].id ,  Service_Rate__c = 12000, Item_Code__c = 'EQU001');
        insert  scli;
    }
    static testmethod void saNightlyJob() {        
        Test.startTest();
        
        List <ServiceContract> newServiceContracts = [Select StartDate, EndDate, id FROM ServiceContract];
        
        newServiceContracts[0].StartDate = System.today();
        newServiceContracts[0].EndDate = System.today()+28;
        update newServiceContracts;
        
        ServiceTerritory territory = [Select id FROM ServiceTerritory WHERE Name = 'SA'];
        
        // Launch Nightly job for SA
        String CRON_EXP = '0 0 0 15 3 ? 2022';
        String jobId = System.schedule('ScheduledSAContractFees', CRON_EXP, new ContractFeesJobSA());   

        CreateContractFeesBatch  sabatchToExecute = new CreateContractFeesBatch (territory.id); 
        Id batchId = Database.executeBatch(sabatchToExecute);
            
        // Verify the batch has not run yet.
        List<Sales_Order__c> sa = [SELECT Id FROM Sales_Order__c];
        System.assertEquals(0, sa.size(), 'Sales Order does not exist before job has run'); 

        Test.stopTest(); 
        // after the testing stops, assert records were created properly
        sa = [SELECT Id FROM Sales_Order__c];
        System.assertEquals(2, sa.size(), 'Sales Orders created after job has run');
        
        List <Sales_Order_Line_Item__c> soli = [Select id FROM Sales_Order_Line_Item__c];
        System.assertEquals(2, soli.size(), 'Sales Orders line items created after job has run');
        
    }

    static testmethod void saNightlyJobInArrear() {        
        Test.startTest();
        
        List <ServiceContract> newServiceContracts = [Select StartDate, EndDate, id FROM ServiceContract];
        
        newServiceContracts[0].Billing_Cycle_Type__c = Constants.CYCLE_TYPE_IN_ARREARS;
        newServiceContracts[0].StartDate = System.today();
        newServiceContracts[0].EndDate = System.today()+365;
        newServiceContracts[1].Billing_Cycle_Type__c = Constants.CYCLE_TYPE_IN_ARREARS;
        newServiceContracts[1].StartDate = System.today();
        newServiceContracts[1].EndDate = System.today()+365;
        update newServiceContracts;
        
        System.assertEquals(2, newServiceContracts.size());
        
        ServiceTerritory territory = [Select id FROM ServiceTerritory WHERE Name = 'SA'];
        
        // Launch Nightly job for SA
        String CRON_EXP = '0 0 0 15 3 ? 2022';
        String jobId = System.schedule('ScheduledSAContractFees', CRON_EXP, new ContractFeesJobSA());   

        CreateContractFeesBatch  sabatchToExecute = new CreateContractFeesBatch (territory.id); 
        Id batchId = Database.executeBatch(sabatchToExecute);
            
        // Verify the batch has not run yet.
        List<Sales_Order__c> sa = [SELECT Id FROM Sales_Order__c];
        System.assertEquals(0, sa.size(), 'Sales Order does not exist before job has run'); 

        Test.stopTest(); 
        // after the testing stops, check next billing date has been updated properly
        newServiceContracts = [Select StartDate, EndDate, Next_Contract_Billing_Date__c, id FROM ServiceContract];
      //  System.assertEquals(newServiceContracts.get(0).Next_Contract_Billing_Date__c, system.today().Addmonths(1)-1);
      //  System.assertEquals(newServiceContracts.get(1).Next_Contract_Billing_Date__c, system.today().Addmonths(3)-1);
        
        List <Sales_Order_Line_Item__c> soli = [Select id FROM Sales_Order_Line_Item__c];
        System.assertEquals(2, soli.size(), 'Sales Orders line items created after job has run');
        
    }

    static testmethod void nswNightlyJob() {        
        Test.startTest();
        
        ServiceTerritory territory = [Select id FROM ServiceTerritory WHERE Name = 'SA'];
        territory.Name = 'NSW';
        update territory;
        
        // Scenario change where the Contract without billing cycle does not have lin items
        List <Service_Contract_Line_Item__c> sclis = [Select id FROM Service_Contract_Line_Item__c ];
        delete sclis;
        
        // Launch Nightly job for NSW
        String CRON_EXP = '0 0 0 15 3 ? 2022';
        String jobId = System.schedule('ScheduledSAContractFees', CRON_EXP, new ContractFeesJobNSW());   

        CreateContractFeesBatch  sabatchToExecute = new CreateContractFeesBatch (territory.id); 
        Id batchId = Database.executeBatch(sabatchToExecute);
            
        // Verify the batch has not run yet.
        List<Sales_Order__c> sa = [SELECT Id FROM Sales_Order__c];
        System.assertEquals(0, sa.size(), 'Sales Order does not exist before job has run'); 

        Test.stopTest(); 
        // after the testing stops, assert records were created properly
        sa = [SELECT Id FROM Sales_Order__c];
        System.assertEquals(2, sa.size(), 'Sales Orders created after job has run');
    }
    
    static testmethod void vicNightlyJob() {        
        Test.startTest();
        
        ServiceTerritory territory = [Select id FROM ServiceTerritory WHERE Name = 'SA'];
        territory.Name = 'VIC';
        update territory;
        
        // Scenario change add line item to the contract with a contract billable cycle
        ServiceContract sc = [Select id FROM ServiceContract WHERE Contract_Billing_Cycle__c = :Constants.CYCLE_MONTHLY];
        Service_Contract_Line_Item__c scli1 = new Service_Contract_Line_Item__c(Quantity__c =1, Service_Contract__c = sc.id, Service_Rate__c = 12000, Item_Code__c = 'EQU001');
        insert scli1;
        
        // Launch Nightly job for VIC
        String CRON_EXP = '0 0 0 15 3 ? 2022';
        String jobId = System.schedule('ScheduledSAContractFees', CRON_EXP, new ContractFeesJobVIC());   

        CreateContractFeesBatch  sabatchToExecute = new CreateContractFeesBatch (territory.id); 
        Id batchId = Database.executeBatch(sabatchToExecute);
            
        // Verify the batch has not run yet.
        List<Sales_Order__c> sa = [SELECT Id FROM Sales_Order__c];
        System.assertEquals(0, sa.size(), 'Sales Order does not exist before job has run'); 

        Test.stopTest(); 
        // after the testing stops, assert records were created properly
        sa = [SELECT Id FROM Sales_Order__c];
        System.assertEquals(2, sa.size(), 'Sales Orders created after job has run');
    }
    
    static testmethod void waNightlyJob() {        
        Test.startTest();
        
        ServiceTerritory territory = [Select id FROM ServiceTerritory WHERE Name = 'SA'];
        territory.Name = 'WA';
        update territory;
        
        // Scenario change: Make Contract Quaterly
        ServiceContract sc = [Select id FROM ServiceContract WHERE Contract_Billing_Cycle__c = :Constants.CYCLE_MONTHLY];
        sc.Contract_Billing_Cycle__c = Constants.CYCLE_QUATERLY;
        update sc;
        
        // Launch Nightly job for WA
        String CRON_EXP = '0 0 0 15 3 ? 2022';
        String jobId = System.schedule('ScheduledSAContractFees', CRON_EXP, new ContractFeesJobWA());   

        CreateContractFeesBatch  sabatchToExecute = new CreateContractFeesBatch (territory.id); 
        Id batchId = Database.executeBatch(sabatchToExecute);
            
        // Verify the batch has not run yet.
        List<Sales_Order__c> sa = [SELECT Id FROM Sales_Order__c];
        System.assertEquals(0, sa.size(), 'Sales Order does not exist before job has run'); 

        Test.stopTest(); 
        // after the testing stops, assert records were created properly
        sa = [SELECT Id FROM Sales_Order__c];
        System.assertEquals(2, sa.size(), 'Sales Orders created after job has run');
    }
    
    static testmethod void qldNightlyJob() {        
        Test.startTest();
        
        ServiceTerritory territory = [Select id FROM ServiceTerritory WHERE Name = 'SA'];
        territory.Name = 'QLD';
        update territory;
        
        // Scenario change: Make Contract YEARLY but contract ends soon
        ServiceContract sc = [Select id, Next_Contract_Billing_Date__c FROM ServiceContract WHERE Contract_Billing_Cycle__c = :Constants.CYCLE_MONTHLY];
        sc.Contract_Billing_Cycle__c = Constants.CYCLE_YEARLY;
        sc.EndDate = System.Today()+20;
        update sc;
        
        // Launch Nightly job for WA
        String CRON_EXP = '0 0 0 15 3 ? 2022';
        String jobId = System.schedule('ScheduledSAContractFees', CRON_EXP, new ContractFeesJobQLD());   

        CreateContractFeesBatch  sabatchToExecute = new CreateContractFeesBatch (territory.id); 
        Id batchId = Database.executeBatch(sabatchToExecute);
            
        // Verify the batch has not run yet.
        sc = [Select id, Next_Contract_Billing_Date__c FROM ServiceContract WHERE Contract_Billing_Cycle__c = :Constants.CYCLE_YEARLY];
        System.assertNotEquals(NULL, sc.Next_Contract_Billing_Date__c, 'Next billing date is still populated'); 

        Test.stopTest(); 
        // after the testing stops, assert records were created properly
        sc = [Select id, Next_Contract_Billing_Date__c FROM ServiceContract WHERE Contract_Billing_Cycle__c = :Constants.CYCLE_YEARLY];
        System.assertEquals(NULL, sc.Next_Contract_Billing_Date__c, 'Next billing date is blank'); 
    }
    
    static testmethod void ntNightlyJobANDretry() {        
        Test.startTest();
        
        ServiceTerritory territory = [Select id FROM ServiceTerritory WHERE Name = 'SA'];
        territory.Name = 'NT';
        update territory;
        
        // Scenario change: Make Contract YEARLY but contract ends soon
        List <ServiceContract> sc = [Select id, Next_Contract_Billing_Date__c FROM ServiceContract];
        String contractId = sc[0].id;
        
        // Launch Nightly job for WA
        String CRON_EXP = '0 0 0 15 3 ? 2022';
        String jobId = System.schedule('ScheduledSAContractFees', CRON_EXP, new ContractFeesJobNT());   

        CreateContractFeesBatch  sabatchToExecute = new CreateContractFeesBatch (contractId); 
        Id batchId = Database.executeBatch(sabatchToExecute);
            
        Test.stopTest(); 

    }
    
    static testmethod void halfYearlyContractInAdvance() {        
        Test.startTest();
        
        // Scenario change: Make Contract HALF YEARLY with in advance billing type
        ServiceContract sc = [Select id, Next_Contract_Billing_Date__c, Contract_Billing_Cycle__c FROM ServiceContract WHERE Contract_Billing_Cycle__c = :Constants.CYCLE_MONTHLY];
        sc.Contract_Billing_Cycle__c = Constants.CYCLE_HALFYEARLY;
        sc.Billing_Cycle_Type__c = Constants.CYCLE_TYPE_IN_ADVANCE;
        sc.EndDate = System.Today()+365;
        update sc;
        
        String contractId = sc.id;
        
        // Launch Nightly job for SA
        String CRON_EXP = '0 0 0 15 3 ? 2022';
        String jobId = System.schedule('ScheduledSAContractFees', CRON_EXP, new ContractFeesJobSA());   

        CreateContractFeesBatch  sabatchToExecute = new CreateContractFeesBatch (contractId); 
        Id batchId = Database.executeBatch(sabatchToExecute);
            
        Test.stopTest(); 

    }

    static testmethod void halfYearlyContractInArrears() {        
        Test.startTest();  
        
        // Scenario change: Make Contract HALF YEARLY with in arrears billing type
        ServiceContract sc = [Select id, Next_Contract_Billing_Date__c, Contract_Billing_Cycle__c FROM ServiceContract WHERE Contract_Billing_Cycle__c = :Constants.CYCLE_MONTHLY];
        sc.Contract_Billing_Cycle__c = Constants.CYCLE_HALFYEARLY;
        sc.Billing_Cycle_Type__c = Constants.CYCLE_TYPE_IN_ARREARS;
        sc.EndDate = System.Today()+365;
        update sc;
        
        String contractId = sc.id;
        
        // Launch Nightly job for SA
        String CRON_EXP = '0 0 0 15 3 ? 2022';
        String jobId = System.schedule('ScheduledSAContractFees', CRON_EXP, new ContractFeesJobSA());   

        CreateContractFeesBatch  sabatchToExecute = new CreateContractFeesBatch (contractId); 
        Id batchId = Database.executeBatch(sabatchToExecute);
            
        Test.stopTest(); 

    }
    
    static testmethod void YearlyContractInArrears() {        
        Test.startTest();  
        
        // Scenario change: Make Contract HALF YEARLY with in arrears billing type
        ServiceContract sc = [Select id, Next_Contract_Billing_Date__c, Contract_Billing_Cycle__c FROM ServiceContract WHERE Contract_Billing_Cycle__c = :Constants.CYCLE_MONTHLY];
        sc.Contract_Billing_Cycle__c = Constants.CYCLE_YEARLY;
        sc.Billing_Cycle_Type__c = Constants.CYCLE_TYPE_IN_ARREARS;
        sc.EndDate = System.Today()+365;
        update sc;
        
        String contractId = sc.id;
        
        // Launch Nightly job for SA
        String CRON_EXP = '0 0 0 15 3 ? 2022';
        String jobId = System.schedule('ScheduledSAContractFees', CRON_EXP, new ContractFeesJobSA());   

        CreateContractFeesBatch  sabatchToExecute = new CreateContractFeesBatch (contractId); 
        Id batchId = Database.executeBatch(sabatchToExecute);
            
        Test.stopTest(); 

    }

}