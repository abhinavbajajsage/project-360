/**
* @description Trigger Handler on Service Report that handles automatic email to Contract Contact with the attached Service report 
This functionality has been temporarily updated to only send the document to the generator of the service report.
*/
public class ServiceReportHandler {

    public static void sendServiceReportToContractContact(List <ServiceReport> serviceReports) {
        
        // Identify if the service report has been created against the Service Appointment   
        Set <Id> saIds = new Set <Id>();
        Map <Id,Id> saToContentVersionIdMap = new Map <Id,Id>();
        Map <Id,Id> srToDocumentIdMap = new Map <Id,Id>();
         
        for(ServiceReport sr :serviceReports){      
            String stringID = ''+ sr.parentid;
            if(stringID.startsWith('08p')){
                saIds.add(sr.parentid);
                saToContentVersionIdMap.put(sr.parentid, sr.contentVersionDocumentId);                               
            }  
        }
        
        List <ContentVersion> cvs = new List <ContentVersion>();
        if(saToContentVersionIdMap.size()>0){
            cvs = ContentVersionDAO.getContentVersionUsingIds(saToContentVersionIdMap.values());
        }
        
        for(ContentVersion cv :cvs){
            srToDocumentIdMap.put(cv.id, cv.ContentDocumentId);
        }
        
        // Get recipients and sender for email
        List <ServiceAppointment> serviceAppointments = new List <ServiceAppointment>();
        List <OrgWideEmailAddress> orgEmailAddresses = new List <OrgWideEmailAddress>();
        Id senderEmailSAGEService;
        
        if(saIds.size()>0){
            serviceAppointments = ServiceAppointmentDAO.getServiceAppointments(saIds);
            orgEmailAddresses = OrgWideEmailAddressDAO.getEmails(Constants.ORG_EMAIL_SAGE_SERVICE);
            
        }
        if(orgEmailAddresses.size()>0){
            senderEmailSAGEService = orgEmailAddresses.get(0).id;
        }
        
        // Get Info from Service Appointment for Email body
        Map <Id,String> saToContactMap = new Map <Id,String>();    
        Map <Id,String> saToCaseMap = new Map <Id,String>();   
        Map <Id,Id> saToContactId = new Map <Id,Id>();
        Map <Id,Id> saToWOidMap = new Map <Id, Id>();
          
        if(serviceAppointments.size()>0){
            for(ServiceAppointment sa :serviceAppointments){
                saToContactMap.put(sa.id, sa.Site_Contact_Email__c);
                saToContactId.put(sa.id,sa.Site_Contact_ID__c);
                saToWOidMap.put(sa.id, sa.parentrecordid);
            }
        }
        
        // Email + create file link to work order
        List<String> ccs = new List<String>();
        
        ccs.add(Label.ServiceReportEmailCC);
        //ccs.add(UserInfo.getUserEmail());
        List<Messaging.SingleEmailMessage> mails =  new List<Messaging.SingleEmailMessage>();
        List<ContentDocumentLink> documentLink = new List<ContentDocumentLink>();
        
        for(ServiceReport sr : serviceReports){
            if(saToContactMap.get(sr.parentid)<>NULL){
                List <Id> contentVersionIds = new List <Id>();
                contentVersionIds.add(saToContentVersionIdMap.get(sr.parentId));
                //List<String> sendTo = new List<String>();                            
                // SendTo.add(saToContactMap.get(sr.parentid));
                
                Messaging.SingleEmailMessage mail =  new Messaging.SingleEmailMessage();
                //mail.setToAddresses(sendTo);
                mail.setTargetObjectId(UserInfo.getUserId());
                //mail.setWhatId(sr.parentid);
                mail.setTemplateId(Label.ServiceReportEmailTemplateId);
                mail.setEntityAttachments(contentVersionIds);
                mail.setOrgWideEmailAddressId(senderEmailSAGEService);
                mail.setCcAddresses(ccs);
                // this was added as the recipient is no longer a contact
                mail.setSaveAsActivity(false);
                
                mails.add(mail);
                
                ContentDocumentLink link = new ContentDocumentLink(ContentDocumentId = srToDocumentIdMap.get(sr.contentVersionDocumentId), 
                                                                   LinkedEntityId = saToWOidMap.get(sr.parentid) , 
                                                                   ShareType ='V',
                                                                   Visibility = 'AllUsers');
               documentLink.add(link);
                
            }
        }
        if(mails.size()>0){
            Messaging.sendEmail(mails);
        }
        if(documentLink.size()>0){
            insert documentLink;
        } 
    
       
    }
}