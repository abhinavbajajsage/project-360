public class SalesOrderDAO {
    public static  List<Sales_Order__c> getSalesOrdersForBillingTerm(Set<Id> soIds, String billingTerm){
        List<Sales_Order__c> salesOrders = [SELECT  id, 
                                                    Service_Contract__c,
                                                    Service_Contract__r.Aggregate_Billing_Format__c,
                                                    Service_Contract__r.Billing_Terms__c
                                            FROM    Sales_Order__c 
                                            WHERE   Id IN :soIds
                                            AND     Service_Contract__r.Billing_Terms__c = :billingTerm];

        return salesOrders;
        
    }
}