public class WorkOrderDAO {

    public static  List<WorkOrder> getWorkOrdersUsingIds(Set<id> woIds){
        List<WorkOrder> wos = [SELECT id, 
                                             ServiceContractId, 
                                             ServiceContract.Type__c, 
                                             ServiceContract.Normal_Time__c, 
                                             ServiceContract.Overtime__c, 
                                             ServiceContract.Night_Time__c, 
                                             ServiceContract.Pricebook2Id,
                                             ServiceContract.Number_of_Pre_Purchased_Hours__c , 
                                             ServiceContract.RecordTypeId,
                                             Use_Pre_purchased_Hours__c,
                                             Customer_Purchase_Order_number__c,
                                             WorkOrderNumber,
                                             Subject,
                                             Total_Billable_Hours__c,
                                             Materials_Total__c,
                                             Subtotal,
                               				 Sales_Order__c	
                                      FROM   WorkOrder 
                                      WHERE  Id IN :woIds];

        return wos;
        
    }
}