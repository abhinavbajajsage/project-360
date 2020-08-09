@isTest
public class WorkOrderDetailsPDFExtnTest {
    
    @testSetup
     static void createTestData() {
        List<OperatingHours> newOPs = new List<OperatingHours>(); 
        newOPs = TestDataUtility.createOperatingHour(1,'SA Operating hours', true);
         
        ServiceTerritory territory = new ServiceTerritory(OperatingHoursId = newOPs[0].id, Name ='SA' , Pronto_Territory_Code__c = '700', IsActive = true, Branch_Code__c = '5');
        insert territory;
         
        id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Constants.ACC_COMPANY_RT).getRecordTypeId();
        List<Account> acc = new List<Account>();
        acc = TestDataUtility.createAccounts(1,accRecordTypeId, true);
        
        List<Contact> cts = new List<Contact>();
        cts = TestDataUtility.createContacts(1, acc[0].Id, false);
        cts[0].Email = 'test@test.com';
        insert cts[0];
         
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
         
        List<ServiceContract> serviceContractRecord = new List<ServiceContract>(); 
        serviceContractRecord = TestDataUtility.createServiceContract(1, acc[0].Id, cts[0].Id, territory.Id, false); 
        serviceContractRecord[0].Normal_Time__c = normalTimeBH.id;
        serviceContractRecord[0].Overtime__c = overtimeBH.id;
        serviceContractRecord[0].Night_Time__c = nighttimeBH.id;
        serviceContractRecord[0].Type__c = Constants.TYPE_SILVER;
        serviceContractRecord[0].Number_of_Pre_Purchased_Hours__c = 0;
        serviceContractRecord[0].Service_Territory__c =territory.id;
        serviceContractRecord[0].Next_Contract_Billing_Date__c = System.Today();
        serviceContractRecord[0].Annual_Service_Amount__c = 12000;
        serviceContractRecord[0].Contract_Billing_Cycle__c = Constants.CYCLE_MONTHLY;
        serviceContractRecord[0].Billing_Cycle_Type__c = Constants.CYCLE_TYPE_IN_ADVANCE;
         
        insert serviceContractRecord;

        
        WorkOrder workOrderRecord = new WorkOrder(
            AccountId = acc[0].Id
            , ServiceContractId = serviceContractRecord[0].Id
        );
        insert workOrderRecord;
    }
    
	private static testMethod void test1() {
        List<ServiceContract> scList = [SELECT Id FROM ServiceContract LIMIT 1];
        if(scList.size() > 0) {
            ServiceContract scRecord = scList[0];
            Test.startTest();
                Test.setCurrentPageReference(new PageReference('Page.WorkOrderDetailsPDF'));
                System.currentPageReference().getParameters().put('id', scRecord.Id);
                System.currentPageReference().getParameters().put('startdate', String.valueOf(Date.today()));
                System.currentPageReference().getParameters().put('enddate', String.valueOf(Date.today()));
                ApexPages.StandardController controller = new ApexPages.StandardController(scRecord);
                WorkOrderDetailsPDFExtn objExtn = new WorkOrderDetailsPDFExtn(controller);
            Test.stopTest();
        }
	}


}