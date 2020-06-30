public class AccountDAO {
    public static  List<Account> getAccountByName(String accountName){
        List<Account> accs = [   Select  Id, 
                                                Name 
                                        From    Account 
                                        Where   Account_Name_Lower__c = :accountName];

        return accs;
        
    }

    public static List<Account> getCaseAccountByTerritory(String serviceTerritory){
        List<Account> customers = [ Select  Id 
                                    From    Account 
                                    Where   Name LIKE 'Cash Sales%' 
                                    AND     Service_Territory__r.Name = :serviceTerritory];
        return customers;
    }

    public static List<Account> getAccountByProntoCode(String accCode){
        List<Account> customers = [ Select  Id
                                    From    Account
                                    Where   Pronto_Account_Code__c = :accCode ];
        return customers;                                    
    }
}