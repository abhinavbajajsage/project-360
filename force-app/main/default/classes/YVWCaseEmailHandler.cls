global class YVWCaseEmailHandler implements Messaging.InboundEmailHandler{
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        String emailBody = email.htmlBody;
        System.debug('****emailBody:'+emailBody);
        parseEmailBody(emailBody);
        return result;
    }

    public static void parseEmailBody(String emailBody){
        String source = '';
        String strdatetime = '';
        String priority = '';
        String errorEmailBody = '';
        try{
            List<String> emailBodyParts = emailBody.split('<br>');
            for(String eBody : emailBodyParts){
                if(eBody.stripHtmlTags() != ''){
                    errorEmailBody += eBody.stripHtmlTags()+', ';
                }
            }
            
            for(String eBody : emailBodyParts){
                String emailHtmlBody = eBody.stripHtmlTags();
                List<String> caseDetails = emailHtmlBody.split(':');
                if(caseDetails.get(0).contains(System.Label.YVW_Source_CL)){
                    source = caseDetails.get(1);
                }
                if(caseDetails.get(0).contains(System.Label.YVW_Priority_CL)){
                    priority = caseDetails.get(1);
                }
                if(caseDetails.get(0).contains(System.Label.YVW_Datetime_CL)){
                    strdatetime = caseDetails.get(1).trim()+':'+caseDetails.get(2)+' '+caseDetails.get(3).split(' ').get(1);
                }
            }
            System.debug(source.trim()+' '+priority.trim()+' '+strdatetime);

            Case currentCase = new Case();
            String errorMessage = '';
            
            //Populate account
            List<Account> acc = AccountDAO.getAccountByProntoCode(System.Label.YVW_Account_Code_CL);
            if(!acc.isEmpty()){
                currentCase.AccountId = acc.get(0).Id;
            }else{
                errorMessage += String.format(System.Label.YVW_Account_Missing_CL, new List<String> {System.Label.YVW_Account_Code_CL});
            }
            
            if(errorMessage == ''){
                //Populate Contract
                List<ServiceContract> contracts = ServiceContractDAO.getContractByProntoCode(System.Label.YVW_Pronto_Contract_No_CL);
                if(!contracts.isEmpty()){
                    currentCase.Service_Contract__c = contracts.get(0).Id;
                    currentCase.Service_Territory__c = contracts.get(0).Service_Territory__c;
                }else{
                    errorMessage += String.format(System.Label.YVW_Contract_Missing_CL, new List<String> {System.Label.YVW_Pronto_Contract_No_CL});
                }
            }

            if(errorMessage == ''){
                //Populate Priority
                System.debug('Priority');
                List<YVW_Email_Priority__mdt> bSettings = [SELECT Id, MasterLabel, DeveloperName FROM YVW_Email_Priority__mdt];
                for(YVW_Email_Priority__mdt bSet : bSettings ){
                    System.debug(bSet.DeveloperName+' - '+priority);
                    if(bSet.DeveloperName.equals(priority.trim()) ){
                        currentCase.Priority = bSet.MasterLabel;
                        System.debug(bSet.MasterLabel);
                        break;
                    }
                }
            }

            //Populate Description
            currentCase.Description = source.trim()+', '+priority.trim()+', '+strdatetime;
            currentCase.Origin = 'Email';
            currentCase.YVW_Email_to_Case__c = true;
            List<WorkType> otherType = WorkTypeDAO.getWorkTypeByName('Other');
            currentCase.Work_Type__c = otherType.size() > 0 ? otherType.get(0).Id : null;

            if(errorMessage == ''){
                insert currentCase;
            }else{
                Utilities.logError(errorEmailBody.substring(0,255), errorMessage, Schema.SObjectType.Error_Log__c.getRecordTypeInfosByDeveloperName().get(Constants.ERR_DEV_Case_RT).getRecordTypeId());
            }
        }catch(Exception ex){
            Utilities.logError(errorEmailBody.substring(0,255), ex, Schema.SObjectType.Error_Log__c.getRecordTypeInfosByDeveloperName().get(Constants.ERR_DEV_Case_RT).getRecordTypeId());
        }
        
    }
}