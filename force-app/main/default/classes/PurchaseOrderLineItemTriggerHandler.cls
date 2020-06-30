public class PurchaseOrderLineItemTriggerHandler {
    // public static void calculateActualHours(List<Purchase_Order_Line_Item__c> newPOLI , Map<Id , Purchase_Order_Line_Item__c> oldPOLIMap){
    //     for(Purchase_Order_Line_Item__c po : newPOLI){
    //         Purchase_Order_Line_Item__c oldPo = oldPOLIMap != null ? ((Purchase_Order_Line_Item__c) oldPOLIMap.get(po.Id)) : null;
    //         if((oldPo != null && (po.Start_Date_Time__c != oldPo.Start_Date_Time__c || po.End_Date_Time__c != oldPo.End_Date_Time__c)) ||
    //          (oldPo == null && po.Start_Date_Time__c != null && po.End_Date_Time__c != null)){
    //             po.Quantity__c = Utilities.getActualHours(po.Start_Date_Time__c, po.End_Date_Time__c);
    //         }
    //     }
    // }
}