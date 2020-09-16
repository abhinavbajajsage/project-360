/**
* 
@author: Imalka Fernando - Proquest Consulting
@description: classes wrapping Work Order line item
* 
*/
public class Timesheet {
    public String id {get;set;} 
    public Decimal hours {get;set;} 
    public Decimal overtime_hours {get;set;} 
    public Decimal double_time_hours {get;set;} 
    public Decimal public_holiday_hours {get;set;}
    public String work_order {get;set;} 
    public String trans_number {get;set;} 
    public String description {get;set;} 
    public String work_date {get;set;} 
    public String company {get;set;} 
    public String territory_company {get;set;} 
    public String line_of_business_code {get;set;} 
    public String employee_code {get;set;} 
    public String record_id {get;set;} 
    public String project_code {get;set;}
    public Long timestamp; 

    public static Timesheet WrappedWOLI(WorkOrderLineItem woliIn, User resource){
        Timesheet woliWrapped = new Timesheet();
        
        woliWrapped.id = woliIn.Id;
        //woliWrapped.hours = woliIn.Actual_Hours__c.setScale(2);
        
        woliWrapped.hours = woliIn.Normal_Time__c.setScale(2);
        woliWrapped.overtime_hours = woliIn.Overtime__c.setScale(2);
        woliWrapped.double_time_hours = woliIn.Double_Time__c.setScale(2);
        woliWrapped.public_holiday_hours = woliIn.Public_Holiday__c.setScale(2);
        
        woliWrapped.work_order = woliIn.WorkOrder.WorkOrderNumber;
        woliWrapped.trans_number = woliIn.LineItemNumber;
        woliWrapped.description = woliIn.Description;
        if(woliIn.StartDate != null){
            //date format: year/month/day
            woliWrapped.work_date = (woliIn.StartDate != null ? string.valueOf(date.newinstance(woliIn.StartDate.year(), woliIn.StartDate.month(), woliIn.StartDate.day())) : null );
        }
        
        woliWrapped.company = woliIn.Employee__c != null ? woliIn.Employee__r.Company_Code__c : resource.Company_Code__c;
        woliWrapped.territory_company = woliIn.TECH_Work_Order_Territory_Branch_Code__c ;
        woliWrapped.line_of_business_code = woliIn.Employee__c != null ? woliIn.Employee__r.Department_Code__c : resource.Line_of_Business_Code__c;
        woliWrapped.employee_code = woliIn.Employee__c != null ? woliIn.Employee__r.Employee_Code__c : resource.EmployeeNumber;
        woliWrapped.project_code = woliIn.SC_Project_Code__c;

        if(woliIn.LastModifiedDate != null){
            woliWrapped.timestamp = woliIn.LastModifiedDate.getTime();
        }
        
        if(woliIn.createdDate != null){
            woliWrapped.timestamp = woliIn.createdDate.getTime();
        }
        
        if(woliWrapped.timestamp == null)
        {
            woliWrapped.timestamp = System.now().getTime();
        }
        
        return woliWrapped;
    }
}