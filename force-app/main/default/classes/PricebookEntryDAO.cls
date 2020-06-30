public class PricebookEntryDAO {

    public static  List<PricebookEntry> getEntriesUsingPricebookIds(Set<id> pricebookIds){
        List<PricebookEntry> entries = [SELECT id, 
                                               Resource_Type__c, 
                                               Contract_Type__c, 
                                               Service_Time__c,
                                               UnitPrice,
                                               Usage_per_hour__c 
                                        FROM   PricebookEntry 
                                        WHERE  Pricebook2Id 
                                        IN     :pricebookIds];

        return entries;
        
    }
}