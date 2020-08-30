@isTest
public class CaseEmailHandlerTest {

    @TestSetup
    static void setup() {
        id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Constants.ACC_COMPANY_RT).getRecordTypeId();
        id supRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Constants.SUPPLIER_ACCOUNT_RT).getRecordTypeId();
        id cashAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Constants.CASH_ACCOUNT_RT).getRecordTypeId();
        
        
        List<OperatingHours> newOPs = new List<OperatingHours>(); 
        newOPs = TestDataUtility.createOperatingHour(1,'SA Operating hours', true);

        ServiceTerritory territory = new ServiceTerritory(OperatingHoursId = newOPs[0].id, Name ='SA' , Pronto_Territory_Code__c = '700', IsActive = true, Branch_Code__c = '5');
        insert territory;

        List<Account> newCashAccounts = new List<Account>(); 
        newCashAccounts = TestDataUtility.createAccounts(1,cashAccountRecordTypeId, false);
        newCashAccounts[0].Name = 'Cash Sales SA';
        newCashAccounts[0].Service_Territory__c = territory.id;
        insert newCashAccounts;

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
        
        Pricebook2 pricebook = new Pricebook2 (Name = 'Silver PB', IsActive = true, Service_Territory__c = territory.id, Contract_Type__c = Constants.TYPE_BRONZE);
        
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
        newServiceContracts[0].Type__c = Constants.TYPE_BRONZE;
        newServiceContracts[0].Number_of_Pre_Purchased_Hours__c = 0;
        newServiceContracts[0].Service_Territory__c =territory.id;
        newServiceContracts[0].Next_Contract_Billing_Date__c = null;
        newServiceContracts[0].Annual_Service_Amount__c = 12000;
        newServiceContracts[0].RecordTypeId = Schema.SObjectType.ServiceContract.getRecordTypeInfosByName().get(Constants.SCO_TemplateContract_RT).getRecordTypeId();

        insert newServiceContracts;
    }

    static testmethod void testCreationOfCaseScenario1(){
        id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Constants.ACC_COMPANY_RT).getRecordTypeId();

        List<ServiceContract> newServiceContracts = [Select Id,ShippingStreet,ShippingCity,ShippingPostalCode, ShippingState From ServiceContract];
        newServiceContracts[0].ShippingStreet = '9 AINTREE ST';
        newServiceContracts[0].ShippingCity = 'BRUNSWICK EAST';
        newServiceContracts[0].ShippingPostalCode = '3057';
        newServiceContracts[0].ShippingState = 'SA';
        update newServiceContracts;

        //create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        // setup the data for the email
        email.subject = System.Label.Case_Email_Subject_CL;
        email.fromname = 'Call Service';
        env.fromAddress = 'message@callservice.com.au';
        email.htmlBody = '<div dir="ltr"><div class="gmail_quote">1- SA, MERRI KASIC, CALL SERVICE, 0393871000, 9 AINTREE ST, BRUNSWICK EAST, 3057, THIS IS A TEST MESSAGE ONLY<br>------- End of Message -------<br>Dispatched:22/01/2020 17:38:19<br></div></div>';
        // call the email service class and test it with the data in the testMethod
        CaseEmailHandler emailProcess = new CaseEmailHandler();
        emailProcess.handleInboundEmail(email, env);
        
        List<Account> createdAccount = [Select Id From Account Where RecordTypeId = :accRecordTypeId];
        System.assertEquals(1, createdAccount.size());

        List<Contact> createdContact = [Select Id From Contact Where AccountId = :createdAccount.get(0).Id AND Phone = '0393871000'];
        System.assertEquals(1, createdContact.size());

        List<Case> createdCase = [Select Id From Case Where ContactId = :createdContact.get(0).Id AND AccountId = :createdAccount.get(0).Id];
        System.assertEquals(1, createdCase.size());
    }

    static testmethod void testCreationOfCaseScenario2(){
        id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Constants.ACC_COMPANY_RT).getRecordTypeId();
        
        ServiceTerritory territory = [Select Id From ServiceTerritory Where Name = 'SA'];
        
        List<Account> newAccounts = new List<Account>(); 
        newAccounts = TestDataUtility.createAccounts(1,accRecordTypeId, false);
        newAccounts[0].Service_Territory__c = territory.id;
        newAccounts[0].Name = 'CALL SERVICE';
        insert newAccounts;

        List<Contact> newContacts = new List<Contact>();
        newContacts = TestDataUtility.createContacts(1,newAccounts[0].id, false);
        newContacts.get(0).Phone = '0393871000';
        newContacts.get(0).Email = 'sfuser@proquestit.com';
        insert newContacts;

        BusinessHours normalTimeBH  = BusinessHoursDAO.getBUUsingName('Adelaide Time: 07:30-16:00 Mon-Fri');        
        BusinessHours overtimeBH    = BusinessHoursDAO.getBUUsingName('Adelaide Time: 16:00-00:00 Mon-Fri 7:30-00:00 Sat-Sun'); 
        BusinessHours nighttimeBH   = BusinessHoursDAO.getBUUsingName('Adelaide Time: 00:00-07:30 Mon-Sun'); 
        
        List<ServiceContract> newServiceContracts = new List<ServiceContract>();
        newServiceContracts = TestDataUtility.createServiceContract(1, newAccounts[0].id, newContacts[0].id, territory.id, false);
        newServiceContracts[0].Normal_Time__c = normalTimeBH.id;
        newServiceContracts[0].Overtime__c = overtimeBH.id;
        newServiceContracts[0].Night_Time__c = nighttimeBH.id;
        newServiceContracts[0].Type__c = Constants.TYPE_BRONZE;
        newServiceContracts[0].Number_of_Pre_Purchased_Hours__c = 0;
        newServiceContracts[0].Service_Territory__c =territory.id;
        newServiceContracts[0].Next_Contract_Billing_Date__c = null;
        newServiceContracts[0].Annual_Service_Amount__c = 12000;
        newServiceContracts[0].RecordTypeId = Schema.SObjectType.ServiceContract.getRecordTypeInfosByName().get(Constants.SCO_CustomerContract_RT).getRecordTypeId();

        insert newServiceContracts;

        //create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        // setup the data for the email
        email.subject = System.Label.Case_Email_Subject_CL;
        email.fromname = 'Call Service';
        env.fromAddress = 'message@callservice.com.au';
        email.htmlBody = '<div dir="ltr"><div class="gmail_quote">1- SA, MERRI KASIC, CALL SERVICE, 0393871000, 9 AINTREE ST, BRUNSWICK EAST, 3057, THIS IS A TEST MESSAGE ONLY<br>------- End of Message -------<br>Dispatched:22/01/2020 17:38:19<br></div></div>';
        // call the email service class and test it with the data in the testMethod
        CaseEmailHandler emailProcess = new CaseEmailHandler();
        emailProcess.handleInboundEmail(email, env);
        
        List<Account> createdAccount = [Select Id From Account Where Name = 'CALL SERVICE'];
        System.assertEquals(1, createdAccount.size());

        List<Contact> createdContact = [Select Id From Contact Where Phone = '0393871000' AND AccountId = :createdAccount.get(0).Id];
        System.assertEquals(1, createdContact.size());

        List<Case> createdCase = [Select Id From Case Where ContactId = :createdContact.get(0).Id AND AccountId = :createdAccount.get(0).Id];
        System.assertEquals(1, createdCase.size());
    } 

    static testmethod void testCreationOfCaseScenario3(){
        id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Constants.ACC_COMPANY_RT).getRecordTypeId();
        
        ServiceTerritory territory = [Select Id From ServiceTerritory Where Name = 'SA'];

        List<Account> newAccounts = new List<Account>(); 
        newAccounts = TestDataUtility.createAccounts(1,accRecordTypeId, false);
        newAccounts[0].Service_Territory__c = territory.id;
        newAccounts[0].Name = 'CALL SERVICE';
        insert newAccounts;

        //create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        // setup the data for the email
        email.subject = System.Label.Case_Email_Subject_CL;
        email.fromname = 'Call Service';
        env.fromAddress = 'message@callservice.com.au';
        email.htmlBody = '<div dir="ltr"><div class="gmail_quote">1- SA, MERRI KASIC, CALL SERVICE, 0393871000, 9 AINTREE ST, BRUNSWICK EAST, 3057, THIS IS A TEST MESSAGE ONLY<br>------- End of Message -------<br>Dispatched:22/01/2020 17:38:19<br></div></div>';
        // call the email service class and test it with the data in the testMethod
        CaseEmailHandler emailProcess = new CaseEmailHandler();
        emailProcess.handleInboundEmail(email, env);
        
        List<Account> createdAccount = [Select Id From Account Where Name = 'CALL SERVICE'];
        System.assertEquals(1, createdAccount.size());

        List<Contact> createdContact = [Select Id From Contact Where Name = 'MERRI KASIC' AND Phone = '0393871000' AND AccountId = :createdAccount.get(0).Id];
        System.assertEquals(1, createdContact.size());

        List<Case> createdCase = [Select Id From Case Where ContactId = :createdContact.get(0).Id AND AccountId = :createdAccount.get(0).Id];
        System.assertEquals(1, createdCase.size());
    } 

    static testmethod void testCreationOfCaseScenario4(){
        //create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        // setup the data for the email
        email.subject = System.Label.Case_Email_Subject_CL;
        email.fromname = 'Call Service';
        env.fromAddress = 'message@callservice.com.au';
        email.htmlBody = '<div dir="ltr"><div class="gmail_quote">1- SA, MERRI KASIC, CALL SERVICE, 0393871000, 9 AINTREE ST, BRUNSWICK EAST, 3057, THIS IS A TEST MESSAGE ONLY<br>------- End of Message -------<br>Dispatched:22/01/2020 17:38:19<br></div></div>';
        // call the email service class and test it with the data in the testMethod
        CaseEmailHandler emailProcess = new CaseEmailHandler();
        emailProcess.handleInboundEmail(email, env);

        List<Account> createdAccount = [Select Id From Account Where Name = 'CALL SERVICE'];
        System.assertEquals(1, createdAccount.size());

        List<Contact> createdContact = [Select Id From Contact Where Name = 'MERRI KASIC' AND Phone = '0393871000' AND AccountId = :createdAccount.get(0).Id];
        System.assertEquals(1, createdContact.size());

        List<Case> createdCase = [Select Id From Case Where ContactId = :createdContact.get(0).Id AND AccountId = :createdAccount.get(0).Id];
        System.assertEquals(1, createdCase.size());

        
    } 

    static testmethod void testCreationOfYVWCaseScenario1(){
        //create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        // setup the data for the email
        email.subject = System.Label.Case_Email_Subject_CL;
        email.fromname = 'Call Service';
        env.fromAddress = 'SCADA@yvw.com.au';
        //email.htmlBody = 'System: ENTERPRISE<br>Source: Sewer.Epping.SPS721.SCADA Equipment.RTU.Data Comms.Fail<br>Message: State changed from Clear to Failed, value is 1 (Current data)<br>DateTime: 24/03/2020 10:14:17.459 AM<br>Priority: R2<br>Cookie Id: 112513<br>JOBPLAN: COMMSFAIL<br>Special Instruction: <br>';
      
        email.plainTextBody = 'SYSTEM: Enterprise FULLNAME: Water.Montrose.WPS088.SCADA Equipment.RTU.Data Comms.Fail ALARM_DESCRIPTION: TODO LOCATION_ID: WPS088 ID: -338435493 WO_ID: 7316467 STATUS: PROCESSED APOLLO_ID: 0 PRIORITY: 2 JOBPLAN_ID: COMMSFAIL LOCATION_DESCRIPTION: TODO REPORTED_DATE: 29-08-2020 14:47:07.000 FAILED_DATE: 28-08-2020 04:14:39.000 ERROR_CODE: ERROR_MSG:';
        // call the email service class and test it with the data in the testMethod
        YVWCaseEmailHandler emailProcess = new YVWCaseEmailHandler();
        emailProcess.handleInboundEmail(email, env);

        List<Case> createdCase = [Select Id, Priority, Description From Case];
        System.assertEquals(0, createdCase.size());

        String errorMessage = String.format(System.Label.YVW_Account_Missing_CL, new List<String> {System.Label.YVW_Account_Code_CL});
        List<Error_log__c> errorLog = [Select Id, Message__c From Error_Log__c];
        System.assertEquals(errorMessage, errorLog.get(0).Message__c);
    } 

    static testmethod void testCreationOfYVWCaseScenario2(){
        id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Constants.ACC_COMPANY_RT).getRecordTypeId();

        List<Account> newCashAccounts = [Select Id,Pronto_Account_Code__c From Account Where RecordTypeId = :accRecordTypeId]; 
        newCashAccounts[0].Pronto_Account_Code__c = System.Label.YVW_Account_Code_CL;
        update newCashAccounts;

        //create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        // setup the data for the email
        email.subject = System.Label.Case_Email_Subject_CL;
        email.fromname = 'Call Service';
        env.fromAddress = 'SCADA@yvw.com.au';
        //email.htmlBody = 'System: ENTERPRISE<br>Source: Sewer.Epping.SPS721.SCADA Equipment.RTU.Data Comms.Fail<br>Message: State changed from Clear to Failed, value is 1 (Current data)<br>DateTime: 24/03/2020 10:14:17.459 AM<br>Priority: R2<br>Cookie Id: 112513<br>JOBPLAN: COMMSFAIL<br>Special Instruction: <br>';
        email.plainTextBody = 'SYSTEM: Enterprise FULLNAME: Water.Montrose.WPS088.SCADA Equipment.RTU.Data Comms.Fail ALARM_DESCRIPTION: TODO LOCATION_ID: WPS088 ID: -338435493 WO_ID: 7316467 STATUS: PROCESSED APOLLO_ID: 0 PRIORITY: 2 JOBPLAN_ID: COMMSFAIL LOCATION_DESCRIPTION: TODO REPORTED_DATE: 29-08-2020 14:47:07.000 FAILED_DATE: 28-08-2020 04:14:39.000 ERROR_CODE: ERROR_MSG:';
        // call the email service class and test it with the data in the testMethod
        YVWCaseEmailHandler emailProcess = new YVWCaseEmailHandler();
        emailProcess.handleInboundEmail(email, env);

        List<Case> createdCase = [Select Id, Priority, Description From Case];
        System.assertEquals(0, createdCase.size());

        String errorMessage = String.format(System.Label.YVW_Contract_Missing_CL, new List<String> {System.Label.YVW_Pronto_Contract_No_CL});
        List<Error_log__c> errorLog = [Select Id, Message__c From Error_Log__c];
        System.assertEquals(errorMessage, errorLog.get(0).Message__c);
    } 

    static testmethod void testCreationOfYVWCaseScenario3(){
        id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Constants.ACC_COMPANY_RT).getRecordTypeId();

        List<Account> newCashAccounts = [Select Id,Pronto_Account_Code__c From Account Where RecordTypeId = :accRecordTypeId]; 
        newCashAccounts[0].Pronto_Account_Code__c = System.Label.YVW_Account_Code_CL;
        update newCashAccounts;

        List<ServiceContract> newServiceContracts = [Select Id From ServiceContract Where AccountId = :newCashAccounts[0].id];
        newServiceContracts[0].Pronto_Contract_No__c = System.Label.YVW_Pronto_Contract_No_CL;
        update newServiceContracts;

        //create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        // setup the data for the email
        email.subject = System.Label.Case_Email_Subject_CL;
        email.fromname = 'Call Service';
        env.fromAddress = 'SCADA@yvw.com.au';
        //email.htmlBody = 'System: ENTERPRISE<br>Source: Sewer.Epping.SPS721.SCADA Equipment.RTU.Data Comms.Fail<br>Message: State changed from Clear to Failed, value is 1 (Current data)<br>DateTime: 24/03/2020 10:14:17.459 AM<br>Priority: R2<br>Cookie Id: 112513<br>JOBPLAN: COMMSFAIL<br>Special Instruction: <br>';
        email.plainTextBody = 'SYSTEM: Enterprise FULLNAME: Water.Montrose.WPS088.SCADA Equipment.RTU.Data Comms.Fail ALARM_DESCRIPTION: TODO LOCATION_ID: WPS088 ID: -338435493 WO_ID: 7316467 STATUS: PROCESSED APOLLO_ID: 0 PRIORITY: 2 JOBPLAN_ID: COMMSFAIL LOCATION_DESCRIPTION: TODO REPORTED_DATE: 29-08-2020 14:47:07.000 FAILED_DATE: 28-08-2020 04:14:39.000 ERROR_CODE: ERROR_MSG:';
        // call the email service class and test it with the data in the testMethod
        YVWCaseEmailHandler emailProcess = new YVWCaseEmailHandler();
        emailProcess.handleInboundEmail(email, env);
        List<Case> createdCase = [Select Id, Priority, Description From Case];
        System.assertEquals('2', createdCase.get(0).Priority);
    } 

    static testmethod void testOutsideBusinessHours(){
        id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Constants.ACC_COMPANY_RT).getRecordTypeId();
        List<Account> newAccounts = [Select Id From Account Where RecordTypeId = :accRecordTypeId];

        List<Contact> newContacts = [Select Id From Contact Where AccountId = :newAccounts.get(0).Id];

        BusinessHours normalTimeBH  = BusinessHoursDAO.getBUUsingName('Adelaide Time: 07:30-16:00 Mon-Fri');        
        
        List<ServiceTerritory> territory = [Select Id, Business_Hours__c From ServiceTerritory];
        territory.get(0).Business_Hours__c = normalTimeBH.Id;
        update territory;

        List<ServiceContract> newServiceContracts = [Select Id From ServiceContract];

        List<Case> newCases = new List<Case>();
        newCases = TestDataUtility.createCases(1, newAccounts[0].id, newContacts[0].id, newServiceContracts[0].id, false);
        newCases[0].Service_Territory__c = territory.get(0).id;
        insert newCases;
        System.debug('***normalTimeBH:'+normalTimeBH);
        List<Case> createdCase = [Select Id, Outside_Business_Hours__c From Case Where ContactId = :newContacts.get(0).Id AND AccountId = :newAccounts.get(0).Id];
        System.assertEquals(1, createdCase.size());
        System.assertEquals(true, createdCase.get(0).Outside_Business_Hours__c);
    }
}