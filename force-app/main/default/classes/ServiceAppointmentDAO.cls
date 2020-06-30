public class ServiceAppointmentDAO {

    public static  List<ServiceAppointment> getServiceAppointments(Set<id> saIds){
        List<ServiceAppointment> serviceAppointments = [SELECT id, 
                                                               Site_Contact_Email__c, 
                                                               Case_Number__c, 
                                                               Site_Contact_ID__c,
                                                               ParentRecordId
                                                        FROM   ServiceAppointment 
                                                        WHERE id 
                                                        IN :saIds 
                                                        AND Site_Contact_Email__c <>NULL];

        return serviceAppointments;
        
    }
    
    public static  List<ServiceAppointment> getOpenServiceAppointments(Set<id> woIds){
        List<ServiceAppointment> serviceAppointments = [SELECT id, 
                                                               AppointmentNumber, 
                                                               Status,
                                                               ParentRecordId
                                                        FROM   ServiceAppointment 
                                                        WHERE ParentRecordId 
                                                        IN :woIds 
                                                        AND Status <> :Constants.SERVICE_APPOINMENT_STATUS_COMPLETE
                                                        AND Status <> :Constants.SERVICE_APPOINMENT_STATUS_CANNOT_COMPLETE];

        return serviceAppointments;
        
    }
}