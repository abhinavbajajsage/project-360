@isTest
Public class WorkOrderLineItemHandlerTest {

    //@description Create a Service Report and check that an email is sent to the Site Contact with the Service Report 
    static testmethod void transactionCalculationTest1() {
        Test.setMock(HttpCalloutMock.class, new CustomerHttpCalloutMock()); 
        id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Constants.ACC_COMPANY_RT).getRecordTypeId();
 
        List<Account> newAccounts = new List<Account>(); 
        newAccounts = TestDataUtility.createAccounts(1,accRecordTypeId, true);
        
        List<Contact> newContacts = new List<Contact>();
        newContacts = TestDataUtility.createContacts(1,newAccounts[0].id, false);
        newContacts.get(0).Email = 'pq@consulting.com';
        insert newContacts;

        List<OperatingHours> newOPs = new List<OperatingHours>(); 
        newOPs = TestDataUtility.createOperatingHour(1,'SA Operating hours', true);
                
        List<ServiceTerritory> newSTs = new List<ServiceTerritory>(); 
        newSTs = TestDataUtility.createSTerritories(1,'SA',newOPs[0].id , true);
        
        
        List<Product2> newProducts = new List<Product2>(); 
        newProducts = TestDataUtility.createProducts(12 , 'Test', false);
        newProducts[0].Resource_Type__c =  Constants.TYPE_TECHNICIAN;
        newProducts[0].Service_Time__c  =  Constants.SERVICE_BUSINESS;
        newProducts[0].Contract_Type__c =  Constants.TYPE_BRONZE;
        newProducts[1].Resource_Type__c =  Constants.TYPE_TECHNICIAN;
        newProducts[1].Service_Time__c  =  Constants.SERVICE_OVERTIME;   
        newProducts[1].Contract_Type__c =  Constants.TYPE_BRONZE ;
        newProducts[2].Resource_Type__c =  Constants.TYPE_TECHNICIAN;
        newProducts[2].Service_Time__c  =  Constants.SERVICE_NIGHT;   
        newProducts[2].Contract_Type__c =  Constants.TYPE_BRONZE;      
        newProducts[3].Resource_Type__c =  Constants.TYPE_ENGINEER;
        newProducts[3].Service_Time__c  =  Constants.SERVICE_BUSINESS;
        newProducts[3].Contract_Type__c =  Constants.TYPE_BRONZE;
        newProducts[4].Resource_Type__c =  Constants.TYPE_ENGINEER;
        newProducts[4].Service_Time__c  =  Constants.SERVICE_OVERTIME;   
        newProducts[4].Contract_Type__c =  Constants.TYPE_BRONZE ;
        newProducts[5].Resource_Type__c =  Constants.TYPE_ENGINEER;
        newProducts[5].Service_Time__c  =  Constants.SERVICE_NIGHT;   
        newProducts[5].Contract_Type__c =  Constants.TYPE_BRONZE;     
        insert newProducts;   
        
        Pricebook2 pricebook = new Pricebook2 (Name = 'Bronze PB', IsActive = true, Service_Territory__c = newSTs[0].id, Contract_Type__c = Constants.TYPE_BRONZE);
        
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
        newServiceContracts[0].Type__c = Constants.TYPE_BRONZE;
        newServiceContracts[0].Number_of_Pre_Purchased_Hours__c = 0;
        newServiceContracts[0].Type__c = Constants.TYPE_BRONZE;
        newServiceContracts[0].Service_Territory__c = newSTs[0].id;
        newServiceContracts[0].Next_Contract_Billing_Date__c = null;
        newServiceContracts[0].Project_Code__c = 'xyz';
        
        insert newServiceContracts;
        
      //  List<PriceBookEntry> pb = [Select id, Service_Time__c, Resource_Type__c, Contract_Type__c  FROM PricebookEntry Where Pricebook2Id = :pricebook.id];
        
        
     //   System.AssertEquals(NULL, pb);        
         
        List<Case> newCases = new List<Case>();
        newCases = TestDataUtility.createCases(1, newAccounts[0].id, newContacts[0].id, newServiceContracts[0].id, false);
        newCases[0].Service_Territory__c = newSTs[0].id;
        insert newCases;
       
        List<WorkType> newWorkTypes = new List<WorkType>(); 
        newWorkTypes = TestDataUtility.createWorkType(1,'PLC', true);
        
        List<WorkOrder> newWorkOrders = new List<WorkOrder>();
        newWorkOrders = TestDataUtility.createWorkOrders(1, newAccounts[0].id, newContacts[0].id, newCases[0].id, newWorkTypes[0].id, newServiceContracts[0].id, true);
        
        List <ServiceAppointment> generatedSA = [SELECT id FROM ServiceAppointment WHERE ParentRecordId = :newWorkOrders[0].id];
        
        List<User> newUsers = new List<User>(); 
        newUsers = TestDataUtility.createUsers(1, true);      
        
        List<ServiceResource> newSR = new List<ServiceResource>(); 
        newSR = TestDataUtility.createServiceResource(1, newUsers[0].id, true);    
        
        List<Employees__c> newEmployees = new List<Employees__c>(); 
        newEmployees = TestDataUtility.createEmployees(1, Constants.TYPE_ENGINEER, true);   
        
        DateTime start = datetime.newinstance(2019, 12, 31, 12, 0, 0);
        WorkOrderLineItem woli = new WorkOrderLineItem( WorkOrderid = newWorkOrders[0].id,
                                                        Resource__c = newSR[0].id,
                                                        Case__c = newCases[0].id, 
                                                        StartDate = start,
                                                        EndDate = start + 24/16,
                                                        Billable_Hours__c = 16,
                                                        Actual_Hours__c =16,
                                                        Service_Contract__c = newServiceContracts[0].id
                                                        );        
        insert woli;
        
        List <WorkOrderLineItem> wolis = [Select PricebookEntryId, UnitPrice FROM WorkOrderLineItem WHERE WorkOrderId = :newWorkOrders[0].id];
        
        // Check that multiple work order line items have been created for 1 record entered
        System.AssertEquals(wolis.size()>1, true);
        
        // Check that price and quantity have been assigned to the WOLI
         System.AssertNotEquals(wolis[0].PricebookEntryId, NULL);     
         System.AssertNotEquals(wolis[0].UnitPrice, NULL);   
         
        // Check that different pricing has been applied based on Service time
         System.AssertNotEquals(wolis[0].UnitPrice, wolis[1].UnitPrice);   
         
         Test.startTest();
         // Transaction starts at night scenario
        DateTime start2 = datetime.newinstance(2019, 12, 30, 4, 0, 0);
        WorkOrderLineItem woli2 = new WorkOrderLineItem( WorkOrderid = newWorkOrders[0].id,
                                                        Resource__c = newSR[0].id,
                                                        Employee__c = newEmployees[0].id,
                                                        Case__c = newCases[0].id, 
                                                        StartDate = start2,
                                                        EndDate = start2 + 24/16,
                                                        Billable_Hours__c = 16,
                                                        Actual_Hours__c =16,
                                                        Service_Contract__c = newServiceContracts[0].id
                                                        );        
        insert woli2;   
        
        woli2 = [Select PricebookEntryId, EndDate, UnitPrice FROM WorkOrderLineItem WHERE id = :woli2.id Limit 1];
        
        // Check that End date has been updated on inserted record
        System.AssertNotEquals(woli2.EndDate, start2 + 24/16);
        
        // Check that price and quantity have been assigned to the WOLI
         System.AssertNotEquals(woli2.PricebookEntryId, NULL);     
         System.AssertNotEquals(woli2.UnitPrice, NULL);   
        
         // Transaction Ending in Business Holiday scenario
        DateTime start3 = datetime.newinstance(2019, 12, 31, 20, 0, 0);
        
        WorkOrderLineItem woli3 = new WorkOrderLineItem( WorkOrderid = newWorkOrders[0].id,
                                                        Resource__c = newSR[0].id,
                                                        Employee__c = newEmployees[0].id,
                                                        Case__c = newCases[0].id, 
                                                        StartDate = start3,
                                                        EndDate = start3 + 24/16,
                                                        Billable_Hours__c = 16,
                                                        Actual_Hours__c =16,
                                                        Service_Contract__c = newServiceContracts[0].id
                                                        );        
        insert woli3;     
        
        List <WorkOrderLineItem> wolis3 = [Select PricebookEntryId, UnitPrice FROM WorkOrderLineItem WHERE WorkOrderId = :newWorkOrders[0].id];
        
        
         // Transaction Ending in Business Holiday scenario
        DateTime start4 = datetime.newinstance(2020, 1, 1, 20, 0, 0);
        WorkOrderLineItem woli4 = new WorkOrderLineItem( WorkOrderid = newWorkOrders[0].id,
                                                        Resource__c = newSR[0].id,
                                                        Employee__c = newEmployees[0].id,
                                                        Case__c = newCases[0].id, 
                                                        StartDate = start4,
                                                        EndDate = start4 + 24/16,
                                                        Billable_Hours__c = 16,
                                                        Actual_Hours__c =16,
                                                        Service_Contract__c = newServiceContracts[0].id
                                                        );        
        insert woli4;   

        
        woli4 = [Select Id, PricebookEntryId, Quantity, UnitPrice, Description FROM WorkOrderLineItem WHERE id = :woli4.id Limit 1];
        
        // Check that a transaction starting in business hours has the night rate
        System.AssertEquals(woli4.Description.contains('Night'), true);  
        
        // update WOLI scenario
        Sales_Order__c so = new Sales_Order__c(Service_Contract__c = newServiceContracts[0].id, Service_Territory__c = newSTs[0].id, Account__c = newAccounts[0].id, Work_Order__c = newWorkOrders[0].id, Integration_Status__c = Constants.INTEGRATION_STATUS_PENDING);
        insert so;
        
        Sales_Order_Line_Item__c soli = new Sales_Order_Line_Item__c(Sales_Order__c = so.id, Order_Quantity__c = woli4.Quantity, Work_Order_Line_Item__c = woli4.id);
        insert soli;
        
        newWorkOrders[0].Sales_Order__c = so.id;
        update newWorkOrders;
        
        woli4.Quantity = 5;
        woli4.Manual_Override__c = true;
        woli4.Manual_Override_Reason__c = 'test';
        update woli4;
        
        soli = [Select Order_Quantity__c FROM Sales_Order_Line_Item__c WHERE Work_Order_Line_Item__c = :woli4.id Limit 1];
        
        System.AssertEquals(soli.Order_Quantity__c,5);

        Test.stopTest();

        
    }

    static testmethod void transactionCalculationTest2() {
        Test.setMock(HttpCalloutMock.class, new CustomerHttpCalloutMock()); 
        id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Constants.ACC_COMPANY_RT).getRecordTypeId();
 
        List<Account> newAccounts = new List<Account>(); 
        newAccounts = TestDataUtility.createAccounts(1,accRecordTypeId, true);
        
        List<Contact> newContacts = new List<Contact>();
        newContacts = TestDataUtility.createContacts(1,newAccounts[0].id, false);
        newContacts.get(0).Email = 'pq@consulting.com';
        insert newContacts;

        List<OperatingHours> newOPs = new List<OperatingHours>(); 
        newOPs = TestDataUtility.createOperatingHour(1,'SA Operating hours', true);
                
        List<ServiceTerritory> newSTs = new List<ServiceTerritory>(); 
        newSTs = TestDataUtility.createSTerritories(1,'SA',newOPs[0].id , true);
        
        
        List<Product2> newProducts = new List<Product2>(); 
        newProducts = TestDataUtility.createProducts(12 , 'Test', false);
        newProducts[0].Resource_Type__c =  Constants.TYPE_TECHNICIAN;
        newProducts[0].Service_Time__c  =  Constants.SERVICE_BUSINESS;
        newProducts[0].Contract_Type__c =  Constants.TYPE_BRONZE;
        newProducts[1].Resource_Type__c =  Constants.TYPE_TECHNICIAN;
        newProducts[1].Service_Time__c  =  Constants.SERVICE_OVERTIME;   
        newProducts[1].Contract_Type__c =  Constants.TYPE_BRONZE ;
        newProducts[2].Resource_Type__c =  Constants.TYPE_TECHNICIAN;
        newProducts[2].Service_Time__c  =  Constants.SERVICE_NIGHT;   
        newProducts[2].Contract_Type__c =  Constants.TYPE_BRONZE;      
        newProducts[3].Resource_Type__c =  Constants.TYPE_ENGINEER;
        newProducts[3].Service_Time__c  =  Constants.SERVICE_BUSINESS;
        newProducts[3].Contract_Type__c =  Constants.TYPE_BRONZE;
        newProducts[4].Resource_Type__c =  Constants.TYPE_ENGINEER;
        newProducts[4].Service_Time__c  =  Constants.SERVICE_OVERTIME;   
        newProducts[4].Contract_Type__c =  Constants.TYPE_BRONZE ;
        newProducts[5].Resource_Type__c =  Constants.TYPE_ENGINEER;
        newProducts[5].Service_Time__c  =  Constants.SERVICE_NIGHT;   
        newProducts[5].Contract_Type__c =  Constants.TYPE_BRONZE;     
        insert newProducts;   
        
        Pricebook2 pricebook = new Pricebook2 (Name = 'Bronze PB', IsActive = true, Service_Territory__c = newSTs[0].id, Contract_Type__c = Constants.TYPE_BRONZE);
        
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
        newServiceContracts[0].Type__c = Constants.TYPE_BRONZE;
        newServiceContracts[0].Number_of_Pre_Purchased_Hours__c = 0;
        newServiceContracts[0].Type__c = Constants.TYPE_BRONZE;
        newServiceContracts[0].Service_Territory__c = newSTs[0].id;
        newServiceContracts[0].Next_Contract_Billing_Date__c = null;
        
        insert newServiceContracts;
        
        List<Case> newCases = new List<Case>();
        newCases = TestDataUtility.createCases(1, newAccounts[0].id, newContacts[0].id, newServiceContracts[0].id, false);
        newCases[0].Service_Territory__c = newSTs[0].id;
        insert newCases;
       
        List<WorkType> newWorkTypes = new List<WorkType>(); 
        newWorkTypes = TestDataUtility.createWorkType(1,'PLC', true);
        
        List<WorkOrder> newWorkOrders = new List<WorkOrder>();
        newWorkOrders = TestDataUtility.createWorkOrders(1, newAccounts[0].id, newContacts[0].id, newCases[0].id, newWorkTypes[0].id, newServiceContracts[0].id, true);
        
        List <ServiceAppointment> generatedSA = [SELECT id FROM ServiceAppointment WHERE ParentRecordId = :newWorkOrders[0].id];
        
        List<User> newUsers = new List<User>(); 
        newUsers = TestDataUtility.createUsers(1, true);      
        
        List<ServiceResource> newSR = new List<ServiceResource>(); 
        newSR = TestDataUtility.createServiceResource(1, newUsers[0].id, true);    
        
        List<Employees__c> newEmployees = new List<Employees__c>(); 
        newEmployees = TestDataUtility.createEmployees(1, Constants.TYPE_ENGINEER, true);   
        
        DateTime start = datetime.newinstance(2019, 12, 31, 12, 0, 0);
        
        Test.startTest();
        
        // Check logic when only 2 business hours are assigned to a Contract
        newServiceContracts[0].Normal_Time__c = normalTimeBH2.id;
        newServiceContracts[0].Overtime__c = overtimeBH2.id;
        newServiceContracts[0].Night_Time__c = NULL;  
        update newServiceContracts;  
        
        WorkOrderLineItem woli5 = new WorkOrderLineItem( WorkOrderid = newWorkOrders[0].id,
                                                        Resource__c = newSR[0].id,
                                                        Case__c = newCases[0].id, 
                                                        StartDate = start,
                                                        EndDate = start + 24/16,
                                                        Billable_Hours__c = 16,
                                                        Actual_Hours__c =16,
                                                        Service_Contract__c = newServiceContracts[0].id
                                                        );        
        insert woli5;

        // Check logic when only 2 business hours are assigned to a Contract  + Pre purchased Hours update       
        newServiceContracts[0].Number_of_Pre_Purchased_Hours__c = 200;  
        update newServiceContracts;  
        
        newWorkOrders[0].Use_Pre_purchased_Hours__c = 'Yes';
        update newWorkOrders;

        DateTime start5 = datetime.newinstance(2019, 11, 24, 20, 0, 0);
        
        WorkOrderLineItem woli6 = new WorkOrderLineItem( WorkOrderid = newWorkOrders[0].id,
                                                        Resource__c = newSR[0].id,
                                                        Case__c = newCases[0].id, 
                                                        StartDate = start5,
                                                        EndDate = start5 + 24/16,
                                                        Billable_Hours__c = 16,
                                                        Actual_Hours__c =16,
                                                        Quantity = 16,
                                                        Service_Contract__c = newServiceContracts[0].id
                                                        );        
        insert woli6;

        woli6 = [Select Consumed_Pre_Purchased_Hours__c, StartDate, PricebookEntryId , EndDate,  Quantity, Usage_per_hour__c  FROM WorkOrderLineItem WHERE id = :woli6.id Limit 1];
        
        // Check that a consumed hours have been update on transaction so it can be deducted from the work order
        System.AssertEquals(woli6.Consumed_Pre_Purchased_Hours__c, woli6.Quantity* woli6.Usage_per_hour__c); 
        
        // Update Scenario
        Id currentproductId = woli6.PricebookEntryId ;
        DateTime currentStart = woli6.StartDate;
        woli6.StartDate = woli6.StartDate + 0.5;
        woli6.EndDate = woli6.EndDate + 0.5;
        update woli6;
        
        woli6 = [Select  PricebookEntryId, StartDate   FROM WorkOrderLineItem WHERE id = :woli6.id Limit 1];
        // Check that the product has been updated on the WOLI 

        System.AssertNotEquals(woli6.StartDate, currentStart);      
        
        Test.stopTest();   
         
        
    }

    static testmethod void transactionStartDateRules() {
        id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Constants.ACC_COMPANY_RT).getRecordTypeId();
 
        List<Account> newAccounts = new List<Account>(); 
        newAccounts = TestDataUtility.createAccounts(1,accRecordTypeId, true);
        
        List<Contact> newContacts = new List<Contact>();
        newContacts = TestDataUtility.createContacts(1,newAccounts[0].id, false);
        newContacts.get(0).Email = 'pq@consulting.com';
        insert newContacts;

        List<OperatingHours> newOPs = new List<OperatingHours>(); 
        newOPs = TestDataUtility.createOperatingHour(1,'SA Operating hours', true);
                
        List<ServiceTerritory> newSTs = new List<ServiceTerritory>(); 
        newSTs = TestDataUtility.createSTerritories(1,'SA',newOPs[0].id , true);
        
        
        List<Product2> newProducts = new List<Product2>(); 
        newProducts = TestDataUtility.createProducts(12 , 'Test', false);
        newProducts[0].Resource_Type__c =  Constants.TYPE_TECHNICIAN;
        newProducts[0].Service_Time__c  =  Constants.SERVICE_BUSINESS;
        newProducts[0].Contract_Type__c =  Constants.TYPE_BRONZE;
        newProducts[1].Resource_Type__c =  Constants.TYPE_TECHNICIAN;
        newProducts[1].Service_Time__c  =  Constants.SERVICE_OVERTIME;   
        newProducts[1].Contract_Type__c =  Constants.TYPE_BRONZE ;
        newProducts[2].Resource_Type__c =  Constants.TYPE_TECHNICIAN;
        newProducts[2].Service_Time__c  =  Constants.SERVICE_NIGHT;   
        newProducts[2].Contract_Type__c =  Constants.TYPE_BRONZE;      
        newProducts[3].Resource_Type__c =  Constants.TYPE_ENGINEER;
        newProducts[3].Service_Time__c  =  Constants.SERVICE_BUSINESS;
        newProducts[3].Contract_Type__c =  Constants.TYPE_BRONZE;
        newProducts[4].Resource_Type__c =  Constants.TYPE_ENGINEER;
        newProducts[4].Service_Time__c  =  Constants.SERVICE_OVERTIME;   
        newProducts[4].Contract_Type__c =  Constants.TYPE_BRONZE ;
        newProducts[5].Resource_Type__c =  Constants.TYPE_ENGINEER;
        newProducts[5].Service_Time__c  =  Constants.SERVICE_NIGHT;   
        newProducts[5].Contract_Type__c =  Constants.TYPE_BRONZE;     
        insert newProducts;   
        
        Pricebook2 pricebook = new Pricebook2 (Name = 'Bronze PB', IsActive = true, Service_Territory__c = newSTs[0].id, Contract_Type__c = Constants.TYPE_BRONZE);
        
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
        newServiceContracts[0].Type__c = Constants.TYPE_BRONZE;
        newServiceContracts[0].Number_of_Pre_Purchased_Hours__c = 0;
        newServiceContracts[0].Type__c = Constants.TYPE_BRONZE;
        newServiceContracts[0].Service_Territory__c = newSTs[0].id;
        newServiceContracts[0].Next_Contract_Billing_Date__c = null;
        
        insert newServiceContracts;
        
        List<Case> newCases = new List<Case>();
        newCases = TestDataUtility.createCases(1, newAccounts[0].id, newContacts[0].id, newServiceContracts[0].id, false);
        newCases[0].Service_Territory__c = newSTs[0].id;
        insert newCases;
       
        List<WorkType> newWorkTypes = new List<WorkType>(); 
        newWorkTypes = TestDataUtility.createWorkType(1,'PLC', true);
        
        List<WorkOrder> newWorkOrders = new List<WorkOrder>();
        newWorkOrders = TestDataUtility.createWorkOrders(1, newAccounts[0].id, newContacts[0].id, newCases[0].id, newWorkTypes[0].id, newServiceContracts[0].id, true);
        
        List <ServiceAppointment> generatedSA = [SELECT id FROM ServiceAppointment WHERE ParentRecordId = :newWorkOrders[0].id];
        
        List<User> newUsers = new List<User>(); 
        newUsers = TestDataUtility.createUsers(1, true);      
        
        List<ServiceResource> newSR = new List<ServiceResource>(); 
        newSR = TestDataUtility.createServiceResource(1, newUsers[0].id, true);    
        
        List<Employees__c> newEmployees = new List<Employees__c>(); 
        newEmployees = TestDataUtility.createEmployees(1, Constants.TYPE_ENGINEER, true);   
        
        DateTime start = datetime.newinstance(2019, 12, 31, 12, 0, 0);
        Test.startTest();
            WorkOrderLineItem woli = new WorkOrderLineItem( WorkOrderid = newWorkOrders[0].id,
                                                            Resource__c = newSR[0].id,
                                                            Case__c = newCases[0].id, 
                                                            StartDate = start,
                                                            EndDate = start + 24/16,
                                                            Billable_Hours__c = 16,
                                                            Actual_Hours__c =16,
                                                            Service_Contract__c = newServiceContracts[0].id
                                                            ); 
            insert woli;    

            Sales_Order__c sOrder = new Sales_Order__c(Service_Contract__c = newServiceContracts[0].Id);
            insert sOrder;

            Sales_Order_Line_Item__c soli = new Sales_Order_Line_Item__c(Sales_Order__c = sOrder.Id, Work_Order_Line_Item__c = woli.Id);
            insert soli;

            sOrder.Integration_Status__c = Utilities.INTEGRATION_SUCCESSFUL;
            update sOrder;

            Datetime today = Datetime.now();
            woli.StartDate = Datetime.newInstance(today.year(), today.month(), today.day(), 10, 0, 0);
            try{
                update woli;    
            }catch(DmlException ex){
                System.assert(ex.getDmlMessage(0).contains(System.Label.WorkOrderLineItem_StartDate_Update_NotAllowed_CL));
            }
        
        Test.stopTest();
           
         
        
    }

    static testmethod void testPayrolCutoffTime() {
        List<Payroll_Cutoff_Time__mdt> pSettings = [SELECT Id, Day_of_Week__c, Time__c FROM Payroll_Cutoff_Time__mdt limit 1];

        // Assume the current time is 2020/05/04 (Monday) 1.00 PM - test a date before the current time but in the previous week

        Datetime today = Datetime.newInstance(2020, 5, 4, 13, 0, 0);
        Datetime testDate = Datetime.newInstance(2020, 5, 1, 13, 0, 0);
        System.assertEquals(false, Utilities.isOutsidePayrollCutoffTime(testDate, today));

        // Assume the current time is 2020/05/04 (Monday) 1.00 PM - test a date before the current time but in a date before the previous week
        today = Datetime.newInstance(2020, 5, 4, 13, 0, 0);
        testDate = Datetime.newInstance(2020, 4, 1, 13, 0, 0);
        System.assertEquals(true, Utilities.isOutsidePayrollCutoffTime(testDate, today));

        // Assume the current time is 2020/05/04 (Monday) 1.00 PM - test a date after the current time
        today = Datetime.newInstance(2020, 5, 4, 13, 0, 0);
        testDate = Datetime.newInstance(2020, 5, 8, 13, 0, 0);
        System.assertEquals(false, Utilities.isOutsidePayrollCutoffTime(testDate, today));

        // Assume the current time is 2020/05/04 (Monday) 1.00 PM - test a date after the current time
        today = Datetime.newInstance(2020, 5, 4, 13, 0, 0);
        testDate = Datetime.newInstance(2020, 5, 4, 11, 30, 0);
        System.assertEquals(false, Utilities.isOutsidePayrollCutoffTime(testDate, today));

        // Assume the current time is 2020/05/04 (Monday) 6.00 PM - test a date before the current time but in the previous week
        today = Datetime.newInstance(2020, 5, 4, 18, 0, 0);
        testDate = Datetime.newInstance(2020, 5, 1, 13, 0, 0);
        System.assertEquals(true, Utilities.isOutsidePayrollCutoffTime(testDate, today));

        // Assume the current time is 2020/05/04 (Monday) 6.00 PM - test a date before the current time but in a date before the previous week
        today = Datetime.newInstance(2020, 5, 4, 18, 0, 0);
        testDate = Datetime.newInstance(2020, 4, 1, 13, 0, 0);
        System.assertEquals(true, Utilities.isOutsidePayrollCutoffTime(testDate, today));

        // Assume the current time is 2020/05/04 (Monday) 6.00 PM - test a date after the current time
        today = Datetime.newInstance(2020, 5, 4, 18, 0, 0);
        testDate = Datetime.newInstance(2020, 5, 8, 13, 0, 0);
        System.assertEquals(false, Utilities.isOutsidePayrollCutoffTime(testDate, today));

        // Assume the current time is 2020/05/04 (Monday) 6.00 PM - test a date after the current time
        today = Datetime.newInstance(2020, 5, 4, 18, 0, 0);
        testDate = Datetime.newInstance(2020, 5, 4, 18, 30, 0);
        System.assertEquals(false, Utilities.isOutsidePayrollCutoffTime(testDate, today));
        

    }
}