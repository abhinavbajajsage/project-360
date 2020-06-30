public class TestDataUtility {

    public static List<Account> createAccounts(Integer noOfAccounts, id recordTypeId, Boolean doInsert) {
        
        List<Account> newAccounts = new List<Account>();
        for(Integer i=0; i<noOfAccounts; i++) {
            newAccounts.add(new Account(Name = 'Proquest'+i, 
                                        RecordTypeId =recordTypeId,
                                        BillingStreet = '37 pitt Street',
                                        BillingCity = 'Sydney',
                                        BillingState = 'NSW',
                                        BillingPostalCode ='2000',
                                        BillingCountry = 'Australia',
                                        ShippingStreet = '37 pitt Street',
                                        ShippingCity = 'Sydney',
                                        ShippingState = 'NSW',
                                        ShippingPostalCode ='2000',
                                        ShippingCountry = 'Australia',
                                        Customer_Status__c = 'N'
                                        ));
        }
        if (doInsert) {
            insert newAccounts;
        }
        return newAccounts;
    }

    public static List<Contact> createContacts(Integer noOfContacts, id AccountId, Boolean doInsert) {
        
        List<Contact> newContacts = new List<Contact>();
        for(Integer i=0; i<noOfContacts; i++) {
            newContacts.add(new Contact(Firstname ='Tom', LastName = 'Helene'+i, 
                                        Accountid = AccountId));
        }
        if (doInsert) {
            insert newContacts;
        }
        return newContacts;
    }

    public static List<OperatingHours> createOperatingHour(Integer noOfOP, String opName, Boolean doInsert) {
        
        List<OperatingHours> newOPs = new List<OperatingHours>();
        for(Integer i=0; i<noOfOP; i++) {
            newOPs.add(new OperatingHours(Name = opName +i , 
                                          TimeZone = 'Australia/Adelaide' ));
        }
        if (doInsert) {
            insert newOPs;
        }
        return newOPs;
    }
    
    public static List<ServiceTerritory> createSTerritories(Integer noOfST, String stName, Id opHoursId, Boolean doInsert) {
        
        List<ServiceTerritory> newSTs = new List<ServiceTerritory>();
        for(Integer i=0; i<noOfST; i++) {
            newSTs.add(new ServiceTerritory(Name = stName +i , 
                                            OperatingHoursId = opHoursId,
                                            IsActive = true));
        }
        if (doInsert) {
            insert newSTs;
        }
        return newSTs;
    }
    
    
    public static List<Product2> createProducts(Integer noOfST, String stName, Boolean doInsert) {
        
        List<Product2> newProducts = new List<Product2>();
        for(Integer i=0; i<noOfST; i++) {
            newProducts.add(new Product2(Name = stName +i ));
        }
        if (doInsert) {
            insert newProducts;
        }
        return newProducts;
    }

    
    public static List<ServiceContract> createServiceContract(Integer noOfSR, id AccountId, id ContactId, id serviceTerritoryId, Boolean doInsert) {
        
        List<ServiceContract> newServiceContracts = new List<ServiceContract>();
        for(Integer i=0; i<noOfSR; i++) {
            newServiceContracts.add(new ServiceContract(Name = 'Bronze Contract'+i, 
                                                        Accountid = AccountId, 
                                                        Contactid = ContactId, 
                                                        Service_Territory__c = serviceTerritoryId,
                                                        ShippingStreet = '37 pitt street',
                                                        ShippingCity = 'Sydney CBD',
                                                        ShippingPostalCode = '2000',
                                                        ShippingState = 'NSW',
                                                        ShippingCountry = 'Australia',
                                                        StartDate = System.Today()-300,
                                                        EndDate = System.Today()+300));
        }
        if (doInsert) {
            insert newServiceContracts;
        }
        return newServiceContracts;
    }
    
    public static List<Case> createCases(Integer noOfCases, id AccountId, id ContactId, id scId, Boolean doInsert) {
        
        List<Case> newCases = new List<Case>();
        for(Integer i=0; i<noOfCases; i++) {
            newCases.add(new Case(Subject = 'Problem'+i, 
                                  Accountid = AccountId, 
                                  ContactId = ContactId, 
                                  Site_Contact__c = ContactId , 
                                  Service_Contract__c = scId));
        }
        if (doInsert) {
            insert newCases;
        }
        return newCases;
    }
    
    public static List<WorkType> createWorkType(Integer noOfWorkTypes, String workTypeName, Boolean doInsert) {
        
        List<WorkType> newWorkTypes = new List<WorkType>();
        for(Integer i=0; i<noOfWorkTypes; i++) {
            WorkType newWorkType = new WorkType();
            newWorkType.Name = workTypeName;
            newWorkType.EstimatedDuration = 8;
            newWorkType.DurationType = 'Hours';
            newWorkTypes.add(newWorkType);
            newWorkType.ShouldAutoCreateSvcAppt = true;
        }
        if (doInsert) {
            insert newWorkTypes;
        }
        return newWorkTypes;
    }
    
    public static List<WorkOrder> createWorkOrders(Integer noOfWorkOrders, id AccountId, id ContactId, id CaseId, id WorkTypeId, id scId, Boolean doInsert) {
        
        List<WorkOrder> newWorkOrders = new List<WorkOrder>();
        for(Integer i=0; i<noOfWorkOrders; i++) {
            newWorkOrders.add(new WorkOrder(Subject = 'Problem'+i, 
                                            Accountid = AccountId, 
                                            ContactId = ContactId, 
                                            Site_Contact__c = ContactId, 
                                            CaseId = CaseId, 
                                            WorkTypeId = WorkTypeId,
                                            ServiceContractId = scId,
                                            Use_Pre_purchased_Hours__c = 'N/A',
                                            Initial_Findings__c = 'Finding 1'));
        }
        if (doInsert) {
            insert newWorkOrders;
        }
        return newWorkOrders;
    } 
    
    public static List<ContentVersion> createContentVersion(Integer noOfContentVersions, String Title, Boolean doInsert) {
        
        List<ContentVersion> newContentVersions = new List<ContentVersion>();
        for(Integer i=0; i<noOfContentVersions; i++) {
            newContentVersions.add(new ContentVersion(Title = Title +i, 
                                                      PathOnClient = 'ServiceReport.jpg', 
                                                      VersionData = Blob.valueOf('Test Content'), 
                                                      IsMajorVersion = true));
        }
        if (doInsert) {
            insert newContentVersions;
        }
        return newContentVersions;
    }
    
    
    public static List<ContentDocumentLink> createContentDocumentLink(Integer noOfContentDocumentLinks, id linkedEntityId, id contentDocumentId, Boolean doInsert) {
        
        List<ContentDocumentLink> newContentDocumentLinks = new List<ContentDocumentLink>();
        for(Integer i=0; i<noOfContentDocumentLinks; i++) {
            newContentDocumentLinks.add(new ContentDocumentLink(LinkedEntityId = linkedEntityId , 
                                                                ContentDocumentId = contentDocumentId, 
                                                                shareType = 'V'));
        }
        if (doInsert) {
            insert newContentDocumentLinks;
        }
        return newContentDocumentLinks;
    }


    public static List<User> createUsers (Integer noOfUsers, Boolean doInsert){

        List<User> newUsers = new List<User>();
        for(Integer i=0; i<noOfUsers; i++){
            newUsers.add(
                new User(
                    ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                    LastName = 'last',
                    Email = 'testuser000@tccs.com',
                    Username = 'testuser000@sage.com.testclass' + System.currentTimeMillis(),
                    CompanyName = 'TEST',
                    Title = 'title',
                    Alias = 'alias',
                    TimeZoneSidKey = 'Australia/Sydney',
                    EmailEncodingKey = 'UTF-8',
                    LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_AU',
                    EmployeeNumber = '1000'
                )
            );
        }
        if(doInsert){
            insert newUsers;
        }
        return newUsers;
    }
    
    public static List<ServiceResource> createServiceResource (Integer noOfSRs , Id userId, Boolean doInsert){

        List<ServiceResource> newSRs = new List<ServiceResource>();
        for(Integer i=0; i<noOfSRs; i++){
            newSRs.add(
                new ServiceResource(
                    IsActive = true,
                    Name = 'Test',
                    ResourceType = 'T',
                    RelatedRecordId = userId,
                    Role__c = 'Technician'
                )
            );
        }
        if(doInsert){
            insert newSRs;
        }
        return newSRs;
    }
    
    public static List<Employees__c> createEmployees (Integer noOfEmployees, String role,  Boolean doInsert){

        List<Employees__c> newEmployees = new List<Employees__c>();
        for(Integer i=0; i<noOfEmployees; i++){
            newEmployees.add(
                new Employees__c( Active__c = true,
                               Name = 'Test',
                               Role__c = role,
                               Employee_Code__c = '000'
                )
            );
        }
        if(doInsert){
            insert newEmployees;
        }
        return newEmployees;
    }

}