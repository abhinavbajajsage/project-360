public class WorkOrderDetailsExtn {
    public Id serviceContractId;
    public ServiceContract serviceContractRecord {get;set;}
    public WorkOrder workOrderFilter {get;set;}
    public List<WorkOrder> workOrderList = new List<WorkOrder>();
    public List<WorkOrderWrapper> workOrderWrapperList {get;set;}
    public Boolean isOpenSendEmailModal {get;set;}
    
    public String emailAddress {get;set;}
    public String emailSubject {get;set;}
    public String emailBody {get;set;}
    public String emailAddressCC {get;set;}
    
    public WorkOrderDetailsExtn(ApexPages.StandardController sc) {
        serviceContractId = sc.getId();
        serviceContractRecord = new ServiceContract();
        workOrderFilter = new WorkOrder(Filter_Start_Date__c = Date.today(), Filter_End_Date__c = Date.today());
        workOrderList = new List<WorkOrder>();
        workOrderWrapperList = new List<WorkOrderWrapper>();
        isOpenSendEmailModal = false;
        emailAddress = '';
        emailSubject = '';
        emailBody = '';
        emailAddressCC = '';
        
        List<ServiceContract> tempServiceContractList = [SELECT Id, Account.Name FROM ServiceContract WHERE Id = :serviceContractId];
        if(tempServiceContractList.size() > 0) {
            serviceContractRecord = tempServiceContractList[0];
        }
        // Service Report Summary for {!Account Name} from {Mon 'YY} to {Mon 'YY} 
    }
    
    public PageReference fetchWorkOrder() {
        workOrderList = new List<WorkOrder>();
        workOrderWrapperList = new List<WorkOrderWrapper>();
        isOpenSendEmailModal = false;
        emailAddress = '';
        emailSubject = '';
        emailBody = '';
        emailAddressCC = '';
        
        List<String> sObjectFieldsList = new List<String>();
        sObjectFieldsList = getsObjectFields(new WorkOrder());
        if(sObjectFieldsList.size() > 0 ) {
            String query = '';
            query = 'SELECT ' + String.join(sObjectFieldsList, ',') + ', CreatedBy.Name, (SELECT Id, Service_Resource_Name__c FROM Service_Appointments__r) FROM WorkOrder WHERE ServiceContractId = :serviceContractId';
            if(workOrderFilter.Filter_Start_Date__c != null && workOrderFilter.Filter_End_Date__c != null && workOrderFilter.Filter_Start_Date__c <= workOrderFilter.Filter_End_Date__c) {
                DateTime startDate = workOrderFilter.Filter_Start_Date__c;
                DateTime endDate = workOrderFilter.Filter_End_Date__c.addDays(1);
                query += ' AND CreatedDate >= :startDate AND CreatedDate <= :endDate';
                workOrderList = Database.query(query);
            } else {
                ApexPages.addMessage(new ApexPages.Message(Apexpages.Severity.ERROR, 'Please fill the correct date.'));
                return null;
            }
            
            if(workOrderList.size() > 0) {
                for(WorkOrder wo : workOrderList) {
                    Set<string> technicialNameSet = new Set<string>();
                    List<string> technicialNameList = new List<string>();
                    if(wo.Service_Appointments__r != null && wo.Service_Appointments__r.size() > 0) {
                        for(ServiceAppointment sa : wo.Service_Appointments__r) {
                            if(String.isNotBlank(sa.Service_Resource_Name__c)) {
                                technicialNameSet.add(sa.Service_Resource_Name__c);
                            }
                        }
                        if(technicialNameSet.size() > 0) {
                            technicialNameList = new List<string> (technicialNameSet);
                        }
                    }
                    System.debug('====technicialNameList====' + technicialNameList);
                    if(technicialNameList.size() > 0) {
                        workOrderWrapperList.add(new WorkOrderWrapper(wo, String.join(technicialNameList, ', ')));
                    } else {
                        workOrderWrapperList.add(new WorkOrderWrapper(wo, ''));
                    }
                }
            }
        }
        return null;
    }
    
    public void openSendEmailModal() {
        isOpenSendEmailModal = true;
        List<EmailTemplate> emailTemplateList = [SELECT Id, Name, Subject FROM EmailTemplate WHERE Name = 'ServiceSummaryReport_TE'];
        if(!emailTemplateList.isEmpty()){
            string templateId = emailTemplateList[0].Id;
            Messaging.SingleEmailMessage msg = Messaging.renderStoredEmailTemplate(templateId, null, null);
            emailbody = msg.getHTMLBody();
            emailSubject = emailTemplateList[0].Subject;
        } 
    }
    
    public void closeSendEmailModal() {
        isOpenSendEmailModal = false;
        emailbody = '';
    }
    
    public PageReference sendEmail() {
        if(workOrderWrapperList.size() > 0 && serviceContractId != null) {
            try {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                
                PageReference redirectPage = Page.WorkOrderDetailsPDF;
                redirectPage.getParameters().put('id', serviceContractId);
                redirectPage.getParameters().put('startdate', String.valueOf(workOrderFilter.Filter_Start_Date__c));
                redirectPage.getParameters().put('enddate', String.valueOf(workOrderFilter.Filter_End_Date__c));
                blob b;
                if(Test.isRunningTest()) {
                    b = blob.valueOf('Test');    
                } else {
                    b = redirectPage.getContent();
                }
                
                string startDate = DateTime.newInstance(workOrderFilter.Filter_Start_Date__c.year(), workOrderFilter.Filter_Start_Date__c.month(), workOrderFilter.Filter_Start_Date__c.day()).format('dd-MM-yyyy');
                string endDate = DateTime.newInstance(workOrderFilter.Filter_End_Date__c.year(), workOrderFilter.Filter_End_Date__c.month(), workOrderFilter.Filter_End_Date__c.day()).format('dd-MM-yyyy');
                string fileName = 'Service Report Summary for ' + serviceContractRecord.Account.Name + ' from ' + startDate + ' to ' + endDate + '.pdf';
                ContentVersion cvHtmlBody = createContentVersion(fileName, b, serviceContractId, false, 'Service Report');
                insert cvHtmlBody;
                
                List<Messaging.EmailFileAttachment> efaList = new List<Messaging.EmailFileAttachment>();
                if(cvHtmlBody != null && cvHtmlBody.VersionData != null) {
                    Messaging.EmailFileAttachment efa1 = new Messaging.EmailFileAttachment();
                    efa1.setFileName(cvHtmlBody.Title + '.pdf');
                    efa1.setBody(cvHtmlBody.VersionData);
                    efaList.add(efa1);
                }
                
                if(efaList.size() > 0 ) {
                    email.setFileAttachments(efaList);
                }
                
                email.setHTMLBody(emailBody);
                if(String.isNotBlank(emailSubject)) {
                    email.setSubject(emailSubject);
                } else {
                    ApexPages.addMessage(new ApexPages.message(Apexpages.Severity.Error, 'Please fill "Email Subject" field'));
                    return null;
                }
                email.setSaveAsActivity(true);
                email.setWhatId(serviceContractId);
                if(String.isNotBlank(emailAddress)) {
                    List<String> emailAddressList = emailAddress.split(';');
                    if(emailAddressList.size() > 0) {
                        email.setToAddresses(emailAddressList);    
                    }
                } else {
                    ApexPages.addMessage(new ApexPages.message(Apexpages.Severity.Error, 'Please fill "To" Email Address field'));
                    return null;
                }
                
                if(String.isNotBlank(emailAddressCC)) {
                    List<String> ccEmailAddressList = emailAddressCC.split(';');
                    if(ccEmailAddressList.size() > 0) {
                        email.setCcAddresses(ccEmailAddressList);    
                    }
                }
                
                // Send the email
                if (!Test.isRunningTest()) Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
                
                ApexPages.addMessage(new ApexPages.message(Apexpages.Severity.CONFIRM, 'Email sent successfully.'));
                isOpenSendEmailModal = false;
                return null;
            } catch(Exception e) {
                ApexPages.addMessage(new ApexPages.message(Apexpages.Severity.Error, e.getMessage() + e.getLineNumber()));
                return null;
            }
        }
        return null;
    }
    
    public PageReference openAndSavePDF() {
        PageReference redirectPage = Page.WorkOrderDetailsPDF;
        redirectPage.getParameters().put('id', serviceContractId);
        redirectPage.getParameters().put('startdate', String.valueOf(workOrderFilter.Filter_Start_Date__c));
        redirectPage.getParameters().put('enddate', String.valueOf(workOrderFilter.Filter_End_Date__c));
        blob b;
        if(Test.isRunningTest()) {
            b = blob.valueOf('Test');    
        } else {
            b = redirectPage.getContent();
        }
        
        string startDate = DateTime.newInstance(workOrderFilter.Filter_Start_Date__c.year(), workOrderFilter.Filter_Start_Date__c.month(), workOrderFilter.Filter_Start_Date__c.day()).format('dd-MM-yyyy');
        string endDate = DateTime.newInstance(workOrderFilter.Filter_End_Date__c.year(), workOrderFilter.Filter_End_Date__c.month(), workOrderFilter.Filter_End_Date__c.day()).format('dd-MM-yyyy');
        string fileName = 'Service Report Summary for ' + serviceContractRecord.Account.Name + ' from ' + startDate + ' to ' + endDate + '.pdf';
        ContentVersion cvHtmlBody = createContentVersion(fileName, b, serviceContractId, false, 'Service Report');
        insert cvHtmlBody;
        
        redirectPage = null;
        
        PageReference redirectMainPage = Page.WorkOrderDetailsPDFMain;
        redirectMainPage.getParameters().put('id', serviceContractId);
        redirectMainPage.getParameters().put('startdate', String.valueOf(workOrderFilter.Filter_Start_Date__c));
        redirectMainPage.getParameters().put('enddate', String.valueOf(workOrderFilter.Filter_End_Date__c));
        redirectMainPage.setRedirect(true);
        System.debug('=======openAndSavePDF=====');
        
        return redirectMainPage;
    }
    
    public static ContentVersion createContentVersion(string fileName, Blob body, String parentId, Boolean isPrivate, String description) {
        ContentVersion cv = new ContentVersion();
        cv.pathOnClient = '/' + fileName;
        cv.Title = fileName.substringBeforeLast('.');
        cv.Description = description;
        cv.Origin = 'H'; 
        cv.FirstPublishLocationId = parentId;
        cv.SharingPrivacy = 'N';
        if(body == null || Blob.valueOf('') == body) {
            cv.VersionData = Blob.valueOf('null');
        } else {
            cv.VersionData = body;
        }
        if(isPrivate) {
            cv.SharingPrivacy = 'P';
        } 
        return cv;
    }
    
    
    private List<string> getsObjectFields(sObject obj) {
        Set<String> sObjectFieldsSet = new Set<String>();
        Map<String, Schema.SobjectField> fields = obj.getSObjectType().getDescribe().fields.getMap();
        for (String s : fields.keySet()) {
            if (fields.get(s).getDescribe().isAccessible()) {
                sObjectFieldsSet.add(s);
            }
        }
        sObjectFieldsSet.add('Account.Name');
        
        return new List<string> (sObjectFieldsSet);
    }
    
    public Class WorkOrderWrapper {
        public WorkOrder workOrderRecord {get;set;}
        public string technicianName {get;set;}
        public WorkOrderWrapper(WorkOrder workOrderRecord, string technicianName) {
            this.workOrderRecord = workOrderRecord;
            this.technicianName = technicianName;
        }
    }
}