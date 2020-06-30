public class ContactDAO {
    public static  List<Contact> getContactsByPhone(String phoneNo){
        List<Contact> conts = [  Select  Id, 
                                        Name, 
                                        AccountId 
                                From    Contact 
                                Where   Phone LIKE :phoneNo 
                                OR      MobilePhone LIKE :phoneNo];

        return conts;
        
    }
}