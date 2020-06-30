public class BusinessHoursDAO {

    public static  BusinessHours getBUUsingName(String name){
        BusinessHours bu = [SELECT id 
                            FROM   BusinessHours 
                            WHERE  Name = :name 
                            Limit  1];

        return bu;
        
    }
}