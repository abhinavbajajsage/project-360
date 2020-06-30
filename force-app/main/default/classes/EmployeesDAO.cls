public class EmployeesDAO {

    public static  List<Employees__c> getEmployeesUsingIds(Set<id> employeeIds){
        List<Employees__c> employees = [Select id, 
                                            Role__c 
                                     FROM Employees__c 
                                     Where Id 
                                     In :employeeIds];

        return employees;
        
    }
}