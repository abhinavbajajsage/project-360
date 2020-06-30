public class SalesOrderLineItemTriggerHandler {

    public static void populateDescription(List<Sales_Order_Line_Item__c> newSalesOrderLines){
        Set<Id> salesOrderIds = new Set<Id>();
        Set<Id> workOrderIds = new Set<Id>();
        for(Sales_Order_Line_Item__c soli : newSalesOrderLines){
            if(soli.Work_Order__c != null ){
                salesOrderIds.add(soli.Sales_Order__c);
                workOrderIds.add(soli.Work_Order__c);
            }
        }

        if(!salesOrderIds.isEmpty()){
            Map<Id,Sales_Order__c> salesOrders = new Map<Id,Sales_Order__c>(SalesOrderDAO.getSalesOrdersForBillingTerm(salesOrderIds, Constants.CYCLE_AGGREGATE));
            Map<Id,WorkOrder> workOrders = new Map<Id,WorkOrder>(WorkOrderDAO.getWorkOrdersUsingIds(workOrderIds));
            for(Sales_Order_Line_Item__c soli : newSalesOrderLines){
                Sales_Order__c sOrder = salesOrders.get(soli.Sales_Order__c);
                if(soli.Work_Order__c != null && sOrder.Service_Contract__r.Aggregate_Billing_Format__c != ''){
                    soli.Notes__c = getSOLIDescription(sOrder.Service_Contract__r.Aggregate_Billing_Format__c, workOrders.get(soli.Work_Order__c));
                }
            }
        }
    }

    private static String getSOLIDescription(String format, WorkOrder wOrder){
        String description = '';
        if(format != null && format != ''){
            //Total_Billable_Hours__c:Hours,WorkOrderNumber:Salesforce Work Order No,
            for(String fSplit : format.split(',')){
                List<String> lSplits = fSplit.split(':');
                description += (lSplits.size() > 1 ? (lSplits.get(1) + ' - ') : '')  + (wOrder.get(lSplits.get(0)) != null ? wOrder.get(lSplits.get(0)) : '')+'<br/>';
            }
        }
        return description;
    }
}