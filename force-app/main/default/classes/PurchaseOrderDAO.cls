public class PurchaseOrderDAO {
    
    public static  List<Purchase_Order__c> getOpenPOs(Set<id> woIds){
        List<Purchase_Order__c> pos = [SELECT  id, 
                                               Status__c, 
                                               Name, 
                                               Work_Order__c 
                                       FROM    Purchase_Order__c 
                                       WHERE   Work_Order__c 
                                       IN      :woIds 
                                       AND     Status__c = :Constants.PURCHASE_ORDER_STATUS_PENDING_APPROVED];

        return pos;
        
    }
}