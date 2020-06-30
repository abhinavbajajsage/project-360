@isTest(SeeAllData=true) 
public class ServiceAppointmentTriggerHandlerTest {
    static testmethod void serviceAppointmentCompletionTest(){
        id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Constants.ACC_COMPANY_RT).getRecordTypeId();
        
        ServiceTerritory territory = [Select Id From ServiceTerritory Where Name = 'SA'];
         
        List<Account> newAccounts = new List<Account>(); 
        newAccounts = TestDataUtility.createAccounts(1,accRecordTypeId, false);
        newAccounts[0].Service_Territory__c = territory.id;
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
        
        Pricebook2 pricebook = new Pricebook2 (Name = 'Silver PB', IsActive = true, Service_Territory__c = territory.id, Contract_Type__c = Constants.TYPE_SILVER);
        
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
        newServiceContracts = TestDataUtility.createServiceContract(1, newAccounts[0].id, newContacts[0].id, territory.id, false);
        newServiceContracts[0].Normal_Time__c = normalTimeBH.id;
        newServiceContracts[0].Overtime__c = overtimeBH.id;
        newServiceContracts[0].Night_Time__c = nighttimeBH.id;
        newServiceContracts[0].Type__c = Constants.TYPE_SILVER;
        newServiceContracts[0].Number_of_Pre_Purchased_Hours__c = 0;
        newServiceContracts[0].Service_Territory__c =territory.id;
        newServiceContracts[0].Next_Contract_Billing_Date__c = System.Today();
        newServiceContracts[0].Annual_Service_Amount__c = 12000;
        newServiceContracts[0].Contract_Billing_Cycle__c = Constants.CYCLE_MONTHLY;
        newServiceContracts[0].Billing_Cycle_Type__c = Constants.CYCLE_TYPE_IN_ADVANCE;

        insert newServiceContracts;
                        
         
        List<Case> newCases = new List<Case>();
        newCases = TestDataUtility.createCases(1, newAccounts[0].id, newContacts[0].id, newServiceContracts[0].id, false);
        newCases[0].Service_Territory__c = territory.id;
       
        List<WorkType> newWorkTypes = new List<WorkType>(); 
        newWorkTypes = TestDataUtility.createWorkType(1,'PLC', true);
        
        List<WorkOrder> newWorkOrders = new List<WorkOrder>();
        newWorkOrders = TestDataUtility.createWorkOrders(1, newAccounts[0].id, newContacts[0].id, newCases[0].id, newWorkTypes[0].id, newServiceContracts[0].id, true);
        
        List <ServiceAppointment> generatedSAS = [SELECT id, ParentRecordId , Status FROM ServiceAppointment WHERE ParentRecordId = :newWorkOrders[0].id];
        
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
                                                        Within_Current_Payroll_Period__c = true,
                                                        Service_Contract__c = newServiceContracts[0].id
                                                        );        
        insert woli;
        
        List <WorkOrderLineItem> wolis = [Select PricebookEntryId, UnitPrice FROM WorkOrderLineItem WHERE WorkOrderId = :newWorkOrders[0].id];
        
        // Check that multiple work order line items have been created for 1 record entered
        System.AssertEquals(wolis.size()>1, true);
        
        
        //Create Service Contract line item only for 1 contract
        Service_Contract_Line_Item__c scli = new Service_Contract_Line_Item__c (Quantity__c =1, Service_Contract__c= newServiceContracts[0].id ,  Service_Rate__c = 12000, Item_Code__c = 'EQU001');
        insert  scli;
        
        
        // Launch Nightly job for SA
        String CRON_EXP = '0 0 0 15 3 ? 2022';
        String jobId = System.schedule('ScheduledSAContractFees', CRON_EXP, new ContractFeesJobSA());   
        
        CreateContractFeesBatch  sabatchToExecute = new CreateContractFeesBatch (territory.id); 
        Id batchId = Database.executeBatch(sabatchToExecute);
        
        ServiceAppointment generatedSA = generatedSAS.get(0);
        generatedSA.Status = Constants.SERVICE_APPOINMENT_STATUS_ACCEPTED;
        update generatedSA;

        generatedSA.Status = Constants.SERVICE_APPOINMENT_STATUS_INPROGRESS;
        update generatedSA;
        
        // Test SA validation Complete WO start
        
        ServiceAppointment sa = new ServiceAppointment(parentrecordid =generatedSA.parentrecordid);
        insert sa;
        
        generatedSA.Status = Constants.SERVICE_APPOINMENT_STATUS_COMPLETE;
        generatedSA.Action_Taken__c = 'Actions';
        generatedSA.Work_Order_Completed__c = 'Yes';
        generatedSA.Transaction_Completed__c = true;
        
        try{
            update generatedSA;     
        }  
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('You cannot Complete the work order as other Service Appointments are still opened') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        } 
        
        sa  = [SELECT id  FROM ServiceAppointment WHERE ParentRecordId = :newWorkOrders[0].id AND Status = 'None' limit 1];
        delete sa;        
        // Test SA validation Complete WO end

        // Test SA validation Complete Where Open PO exist start
		Purchase_Order__c po = new Purchase_Order__c (Service_Appointment__c = generatedSA.id, Work_Order__c =newWorkOrders[0].id , Service_Territory__c = territory.id);
        insert po;
        
        Purchase_Order_Line_Item__c poli = new Purchase_Order_Line_Item__c(Cost__c = 3500, Quantity__c = 6, Purchase_Order__c = po.id );
        insert poli;
        
        po.Status__c = 'Approval Pending';
        update po;
        
        try{
            update generatedSA;     
        }  
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('You cannot Complete the work order as some Purchase Orders are still opened') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        } 
        
        delete po;
        
        // Test SA validation Complete Where Open PO exist end

        generatedSA.Status = Constants.SERVICE_APPOINMENT_STATUS_INPROGRESS;
        generatedSA.Action_Taken__c = 'Actions';
        update generatedSA;
        generatedSA.Work_Order_Completed__c = 'Yes';
        generatedSA.Transaction_Completed__c = true;
        generatedSA.Status = Constants.SERVICE_APPOINMENT_STATUS_COMPLETE;
        update generatedSA;
        

        WorkOrderLineItem generatedWOLI = [SELECT id, Status FROM WorkOrderLineItem LIMIT 1];
        generatedWOLI = WorkOrderLineItemDAO.getWorkOrderLineItemsUsingIds(generatedWOLI.Id).get(0);
        Test.startTest();
            SynchWithPronto syncjob = new SynchWithPronto(generatedWOLI , 'WorkOrderLineItem', null);
            ID syncjobID = System.enqueueJob(syncjob);
        Test.stopTest();
        
    }
}