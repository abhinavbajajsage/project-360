public class UserDAO {
    public static Map<Id,User> getUsers(Set<Id> usersIds) {
        return new Map<Id,User>([   Select  Id,
                                            Line_of_Business_Code__c,
                                            EmployeeNumber,
                                 			Company_Code__c
                                    From    User
                                    Where   ID IN :usersIds]);
    }
}