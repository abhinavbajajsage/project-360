@isTest
public class AggregateBillingFormatControllerTest {

    @TestSetup
    static void setup() {
        id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Constants.ACC_COMPANY_RT).getRecordTypeId();
        id supRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Constants.SUPPLIER_ACCOUNT_RT).getRecordTypeId();
        
        
        List<OperatingHours> newOPs = new List<OperatingHours>(); 
        newOPs = TestDataUtility.createOperatingHour(1,'SA Operating hours', true);

        ServiceTerritory territory = new ServiceTerritory(OperatingHoursId = newOPs[0].id, Name ='SA' , Pronto_Territory_Code__c = '700', IsActive = true, Branch_Code__c = '5');
        insert territory;
         
        List<Account> newAccounts = new List<Account>(); 
        newAccounts = TestDataUtility.createAccounts(1,accRecordTypeId, false);
        newAccounts[0].Service_Territory__c = territory.id;
        insert newAccounts;

        List<Account> newSupplier = new List<Account>(); 
        newSupplier = TestDataUtility.createAccounts(1,supRecordTypeId, false);
        newSupplier[0].Service_Territory__c = territory.id;
        insert newSupplier;

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
        newServiceContracts[0].Billing_Cycle_Type__c =Constants.CYCLE_TYPE_IN_ADVANCE;
        newServiceContracts[0].Aggregate_Billing_Format__c = 'Total_Billable_Hours__c:Hours,';
        newServiceContracts[0].Billing_Terms__c = Constants.CYCLE_AGGREGATE;
        insert newServiceContracts;
        
        List<Case> newCases = new List<Case>();
        newCases = TestDataUtility.createCases(1, newAccounts[0].id, newContacts[0].id, newServiceContracts[0].id, false);
        newCases[0].Service_Territory__c = territory.id;
       
        List<WorkType> newWorkTypes = new List<WorkType>(); 
        newWorkTypes = TestDataUtility.createWorkType(1,'PLC', true);
        
        List<WorkOrder> newWorkOrders = new List<WorkOrder>();
        newWorkOrders = TestDataUtility.createWorkOrders(1, newAccounts[0].id, newContacts[0].id, newCases[0].id, newWorkTypes[0].id, newServiceContracts[0].id, true);
        newWorkOrders.get(0).Status  = Constants.WORK_ORDER_STATUS_READY_TO_INVOICE;
        update newWorkOrders;
        
        List <ServiceAppointment> generatedSAS = [SELECT id, Status FROM ServiceAppointment WHERE ParentRecordId = :newWorkOrders[0].id];
        
                        
    }

    static testmethod void testBillingFormatMethods() { 
        List<ServiceContract> serviceContracts = [Select Id From ServiceContract LIMIT 1];
        Test.startTest();
            Map<String,Aggregate_Billing_Format__mdt> billingFormats = AggregateBillingFormatController.getBillingFormatsMap();
            Map<String,Aggregate_Billing_Format__mdt> billingFormatMap = AggregateBillingFormatController.getBillingFormatsMapByMasterLabel();
            List<String> formats = AggregateBillingFormatController.getBillingFormats();
            ServiceContract sc = AggregateBillingFormatController.getServiceContract(serviceContracts.get(0).Id);
            List<AggregateBillingFormatController.BillingFormat> bilFormats = AggregateBillingFormatController.getServiceContractBillingFormat(serviceContracts.get(0).Id);
            sc = AggregateBillingFormatController.saveServiceContract(sc, '[{"value":"Billable Hours","label":"Hours"},{"value":"Salesforce Work Order Number","label":"Salesforce Work Order No"}]');
            System.assertEquals('Total_Billable_Hours__c:Hours,WorkOrderNumber:Salesforce Work Order No,', sc.Aggregate_Billing_Format__c);
        Test.stopTest();
        
        
    }
    
    static testmethod void testCreateAggregateSalesOrder() { 
        List<ServiceContract> serviceContracts = [Select Id,AccountId,Service_Territory__c From ServiceContract LIMIT 1];
        Test.startTest();
            List<WorkOrder> wOrders = AggregateBillingFormatController.getWorkOrderForContractWithStatus(serviceContracts.get(0).Id, Constants.WORK_ORDER_STATUS_READY_TO_INVOICE);
            System.assertEquals(1, wOrders.size());
        	Id soId = AggregateBillingFormatController.createSalesOrder(serviceContracts.get(0),'[\"'+wOrders.get(0).Id+'\"]');
        	System.assert(soId != null);
        	List<Sales_Order_Line_Item__c> soLines = [Select Id From Sales_Order_Line_Item__c Where Sales_Order__c = :soId AND Work_Order__c = :wOrders.get(0).Id];
        	System.assertEquals(1, soLines.size());
        	wOrders = [Select Id From WorkOrder Where ID = :wOrders.get(0).Id AND Sales_Order__c = :soId];
        	System.assertEquals(1, wOrders.size());        
        Test.stopTest();
        
        
    }
}