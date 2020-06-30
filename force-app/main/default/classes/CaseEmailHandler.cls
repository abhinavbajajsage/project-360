global class CaseEmailHandler implements Messaging.InboundEmailHandler{
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();

        if(email.subject.contains(System.Label.Case_Email_Subject_CL)){

            List<String> emailBodyParts = email.htmlBody.split('<br>');
            String emailBody = email.htmlBody;
            System.debug('****emailBody:'+emailBody);
            String emailHtmlBody = emailBodyParts.get(0).stripHtmlTags();
            System.debug('****NOHTMLL:'+emailHtmlBody);
            parseEmailBody(emailHtmlBody);
        }
        return result;
    }

    public static void parseEmailBody(String emailHtmlBody){
        List<String> caseDetails = emailHtmlBody.split(',');
        String serviceTerritory = caseDetails.get(0).substring(caseDetails.get(0).indexOf(' '),caseDetails.get(0).length()).trim();
        System.debug('****serviceTerriotry:'+serviceTerritory+'*****');
        String contactName = caseDetails.get(1).trim();
        System.debug('****contactName:'+contactName+'*****');
        String accountName = caseDetails.get(2).trim();
        System.debug('****accountName:'+accountName+'*****');
        String phoneNo = caseDetails.get(3).trim();
        System.debug('****phoneNo:'+phoneNo+'*****');
        String street = caseDetails.get(4).trim();
        System.debug('****street:'+street+'*****');
        String suburb = caseDetails.get(5).trim().remove('&nbsp;');
        System.debug('****suburb:'+suburb+'*****');
        String postcode = caseDetails.get(6).trim();
        System.debug('****postcode:'+postcode+'*****');
        List<String> caseSubject = caseDetails.get(7).trim().split('<br>');
        System.debug('****caseSubject:'+caseSubject+'*****');

        
        createNewCase(emailHtmlBody, serviceTerritory, contactName, accountName, phoneNo, street, suburb, postcode, caseSubject.get(0));

    }

    public static void createNewCase(String emailBody, String serviceTerritory, String contactName, String accountName, String phoneNo, String street, String suburb, String postcode, String caseSubject){
        try{
            //Create case
            Case newCase = new Case();
            newCase.Subject = caseSubject;
            newCase.Description = caseSubject;
            newCase.Origin = 'Email';
            newCase.Tech_Email_to_Case__c = true;
            List<WorkType> otherType = WorkTypeDAO.getWorkTypeByName('Other');
            newCase.Work_Type__c = otherType.size() > 0 ? otherType.get(0).Id : null;
            //Find the Service Contract from the address
            List<ServiceContract> serviceContracts = ServiceContractDAO.getContractByAddress(street.toLowerCase(),suburb.toLowerCase(),postcode,serviceTerritory);
            
            //If Service Contract Found
            if(serviceContracts.size() > 0){
                //Link the case to the Service Contract
                newCase.Service_Contract__c = serviceContracts.get(0).Id;
                newcase.AccountId = serviceContracts.get(0).AccountId;

                System.debug('*****serviceContracts:'+serviceContracts);
                //Link the case to the Service Contract's contact and match the phone number
                List<Contact> contacts = new List<Contact>();
                if(Test.isRunningTest()){
                    contacts = ContactDAO.getContactsByPhone(phoneNo);
                }else{
                    List<List<SObject>> searchList = [FIND :phoneNo IN PHONE FIELDS RETURNING Contact(Id,AccountId)];
                    contacts = (List<Contact>)searchList.get(0);
                }
                System.debug('*****contacts:'+contacts);
                if(contacts.size() > 0 && contacts.get(0).AccountId == serviceContracts.get(0).AccountId){
                    newcase.ContactId = contacts.get(0).Id;
                    
                }else{
                    Contact newContact = phoneNo.startsWith('04') ? (new Contact(AccountId = serviceContracts.get(0).AccountId, LastName = contactName, MobilePhone = phoneNo, Contact_Type__c = 'Service Contact' )) : (new Contact(AccountId = serviceContracts.get(0).AccountId, LastName = contactName, Phone = phoneNo, Contact_Type__c = 'Service Contact' ));
                    insert newContact;
                    newcase.ContactId = newContact.Id;
                }
                //Link the case to the Service Contract's Service Territory
                newcase.Service_Territory__c = serviceContracts.get(0).Service_Territory__c;
                populateSiteContact(newcase, serviceContracts.get(0));

            }
            //If Service Contract Not Found
            else{
                //Find the contact with the same phone number
                List<Contact> contacts = new List<Contact>();
                if(Test.isRunningTest()){
                    contacts = ContactDAO.getContactsByPhone(phoneNo);
                }else{
                    List<List<SObject>> searchList = [FIND :phoneNo IN PHONE FIELDS RETURNING Contact(Id,AccountId)];
                    contacts = (List<Contact>)searchList.get(0);
                }
                
                //If contact Found
                if(contacts.size() > 0){
                    //Link the case to the contact
                    newcase.ContactId = contacts.get(0).Id;
                    //Link the case to the contacts account
                    newcase.AccountId = contacts.get(0).AccountId;
                    //Link the Bronze Service Contract to the case
                    serviceContracts = ServiceContractDAO.getContractByType(Constants.TYPE_BRONZE,Constants.SCO_TemplateContract_RT,serviceTerritory);
                    System.debug('****serviceContracts:'+serviceContracts);
                    if(serviceContracts.size() > 0){
                        newcase.Service_Contract__c = serviceContracts.get(0).Id;
                        populateSiteContact(newcase, serviceContracts.get(0));
                    }else{
                        newcase.Site_Contact__c = newcase.ContactId;
                    }
                }
                //If contact not found
                else{
                    //Find the account with the same name
                    System.debug('ACC:'+accountName.toLowerCase());
                    List<Account> accounts = AccountDAO.getAccountByName(accountName.toLowerCase());
                    System.debug('accounts:'+accounts);                    
                    //If account found
                    if(accounts.size() > 0){
                        //Link case to the account
                        newcase.AccountId = accounts.get(0).Id;
                        //Create contact and link to the account and case
                        Contact newContact = phoneNo.startsWith('04') ? (new Contact(AccountId = newCase.AccountId, LastName = contactName, MobilePhone = phoneNo, Contact_Type__c = 'Service Contact' )) : (new Contact(AccountId = newCase.AccountId, LastName = contactName, Phone = phoneNo, Contact_Type__c = 'Service Contact' ));
                        insert newContact;
                        newCase.ContactId = newContact.Id;
                        //Find the Bronze Service Contract to the Account
                        serviceContracts = ServiceContractDAO.getContractByAccountAndType(newcase.AccountId,Constants.TYPE_BRONZE);
                        //Is Service Contract is Found
                        if(serviceContracts.size() > 0){
                            newcase.Service_Contract__c = serviceContracts.get(0).Id;
                            populateSiteContact(newcase, serviceContracts.get(0));
                        }
                        //Is Service Contract is not found
                        else{
                            //Find the service contract with the record type 'Template Contract' for the service territory
                            serviceContracts = ServiceContractDAO.getContractByType(Constants.TYPE_BRONZE,Constants.SCO_TemplateContract_RT,serviceTerritory);
                            System.debug('****serviceContracts:'+serviceContracts);
                            if(serviceContracts.size() > 0){
                                newcase.Service_Contract__c = serviceContracts.get(0).Id;
                                populateSiteContact(newcase, serviceContracts.get(0));
                            }else{
                                newcase.Site_Contact__c = newcase.ContactId;
                            }
                        }
                    }
                    //If account not Found
                    else{
                        //Find Parent Cash Account for the State
                        List<Account> customers = AccountDAO.getCaseAccountByTerritory(serviceTerritory);
                        //Create cash account
                        Account cashAccount = new Account(Name = accountName, RecordTypeId = Utilities.getAccountRecordType('Cash Account'), ParentId = (customers.size() > 0 ? customers.get(0).Id: null), Site_Street__c = street, Site_City_Suburb__c = suburb, Site_Postcode__c = postcode, Site_State__c = serviceTerritory, Customer_Status__c = 'Pending');
                        insert cashAccount;
                        //Link case to the cash account
                        newCase.AccountId = cashAccount.Id;
                        //Create contact and link to the account and case
                        Contact newContact = phoneNo.startsWith('04') ? (new Contact(AccountId = cashAccount.Id, LastName = contactName, MobilePhone = phoneNo, Contact_Type__c = 'Service Contact' )) : (new Contact(AccountId = cashAccount.Id, LastName = contactName, Phone = phoneNo, Contact_Type__c = 'Service Contact' ));
                        insert newContact;
                        newCase.ContactId = newContact.Id;
                        //Link the Bronze Service Contract to the case
                        //Find the service contract with the record type 'Template Contract' for the service territory
                        serviceContracts = ServiceContractDAO.getContractByType(Constants.TYPE_BRONZE,Constants.SCO_TemplateContract_RT,serviceTerritory);
                        System.debug('****serviceContracts:'+serviceContracts);
                        if(serviceContracts.size() > 0){
                            newcase.Service_Contract__c = serviceContracts.get(0).Id;
                            populateSiteContact(newcase, serviceContracts.get(0));
                        }else{
                            newcase.Site_Contact__c = newcase.ContactId;
                        }
                    }
                }
            }
            System.debug('****newCase:'+newCase);
            insert newCase;
        }catch(Exception ex){
            System.debug('**Exception:'+ex.getMessage());
            Utilities.logError(emailBody, ex, Schema.SObjectType.Error_Log__c.getRecordTypeInfosByDeveloperName().get(Constants.ERR_DEV_Case_RT).getRecordTypeId());
        }
        
    }

    public static void populateSiteContact(Case newCase, ServiceContract serviceContract){
        if(serviceContract.RecordType.Name == Constants.SCO_TemplateContract_RT){
            newcase.Site_Contact__c = newcase.ContactId;
        }else{
            newcase.Site_Contact__c = serviceContract.ContactId;
        }
    }

}