/**
* 
@author: Imalka fernando - Proquest Consulting
@description: This class handles all data retrieval relative to work order line items
* 
*/
public class WorkOrderLineItemDAO {
    public static  Map<Id,WorkOrderLineItem> getWorkOrderLineItemsUsingWoIds(Set<id> woIds){
        return new Map<Id,WorkOrderLineItem>([  SELECT  Id,
                                                        Within_Current_Payroll_Period__c,
                                                        Sync_With_Pronto__c,
                                                        Actual_Hours__c,
                                                        WorkOrder.WorkOrderNumber,
                                                        LineItemNumber,
                                                        Description,
                                                        StartDate,
                                                        Pronto_Account_Code__c,
                                                        Resource__c,
                                                        Employee__r.Department_Code__c,
                                                        Employee__r.Employee_Code__c,
                                              			Employee__r.Company_Code__c,
                                                        Pronto_Record_Id__c,
                                                        SC_Project_Code__c,
                                                        Resource__r.RelatedRecordId,
                                                        CreatedDate,
                                                        LastModifiedDate,
                                                        SA_Completed__c,
                                                        Send_Timesheet__c,
                                                        Purchase_Order__c,
                                                        TECH_Work_Order_Territory_Branch_Code__c,
                                                        Integration_Status__c
                                                FROM    WorkOrderLineItem 
                                                WHERE   WorkOrderId IN :woIds
                                                AND     StartDate != null
                                                AND     Purchase_Order__c = null]);

    }

    public static List<WorkOrderLineItem> getWorkOrderLineItemsUsingIds(Id woliId){
        return [    SELECT  Id,
                            Within_Current_Payroll_Period__c,
                            Sync_With_Pronto__c,
                            Actual_Hours__c,
                            WorkOrder.WorkOrderNumber,
                            LineItemNumber,
                            Description,
                            StartDate,
                            Pronto_Account_Code__c,
                            Resource__c,
                            Employee__r.Department_Code__c,
                            Employee__r.Employee_Code__c,
                			Employee__r.Company_Code__c,
                            Pronto_Record_Id__c,
                            SC_Project_Code__c,
                            Resource__r.RelatedRecordId,
                            CreatedDate,
                            LastModifiedDate,
                            SA_Completed__c,
                            Send_Timesheet__c,
                            Purchase_Order__c,
                            TECH_Work_Order_Territory_Branch_Code__c
                    FROM    WorkOrderLineItem 
                    WHERE   Id = :woliId];

    }
}