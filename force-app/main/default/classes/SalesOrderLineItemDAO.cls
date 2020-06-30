public class SalesOrderLineItemDAO {
    public static  List<Sales_Order_Line_Item__c> getSalesOrdersLinesForWOLI(Set<Id> woliIds){
        List<Sales_Order_Line_Item__c> salesOrderLines = [  SELECT  id, 
                                                                    Work_Order_Line_Item__c
                                                            FROM    Sales_Order_Line_Item__c 
                                                            WHERE   Work_Order_Line_Item__c IN :woliIds
                                                            AND     Sales_Order__r.Integration_Status__c = :Utilities.INTEGRATION_SUCCESSFUL];

        return salesOrderLines;
        
    }

    public static  List<Sales_Order_Line_Item__c> getSOLinesForWOLI(Set<Id> woliIds){
        List<Sales_Order_Line_Item__c> salesOrderLines = [  SELECT  id, 
                                                                    Work_Order_Line_Item__c,
                                                                    Sales_Order__c
                                                            FROM    Sales_Order_Line_Item__c 
                                                            WHERE   Work_Order_Line_Item__c IN :woliIds];

        return salesOrderLines;
        
    }
}