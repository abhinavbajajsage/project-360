public class OrgWideEmailAddressDAO {

    public static  List<OrgWideEmailAddress> getEmails(String address){
        List<OrgWideEmailAddress> emails = [SELECT id 
                                            FROM OrgWideEmailAddress 
                                            WHERE Address = :address];

        return emails;
        
    }
}