public class ServiceTerritoryDAO {

    public static  ServiceTerritory getServiceTerritoryWithName(String name){
        ServiceTerritory st = [SELECT id
                                FROM   ServiceTerritory 
                                WHERE Name = :name 
                                Limit 1];

        return st;
        
    }
}