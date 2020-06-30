/**
* 
@author: Cyrille Jeufo - Proquest Consulting
@description: classes wrapping sales order and Sales Order line items
* 
*/
public class SalesOrder {

    public String id {get;set;} 
    public String account_code {get;set;} 
    public String action_taken {get;set;} 
    public String caseNumber {get;set;} // in json: case
    public String company {get;set;} 
    public String territory_company {get; set;}
    public String contact_name {get;set;} 
    public String customer_ref {get;set;} 
    public String initial_findings {get;set;} 
    public String order_date {get;set;} 
    public String project_code {get;set;} 
    public String reported_fault {get;set;} 
    public List<SalesOrderItems> sales_order_items {get;set;} 
    public String site {get;set;} 
    public String suggested_followup {get;set;} 
    public String work_order {get;set;} 
    public Long timestamp {get;set;} 
    
    public class SalesOrderItems {
        public String id {get;set;} 
        public String description {get;set;} 
        public String notes {get;set;} 
        public String measure {get;set;} 
        public Double price {get;set;} 
        public Double price_per_measure {get;set;} 
        public Double qty {get;set;} 
        public Double tax_rate {get;set;} 
        public String technician {get;set;} 
        public String work_order {get;set;} 
    }
    
    public static SalesOrder WrappedSO(Sales_Order__c soIn){
        SalesOrder soWrapped = new SalesOrder();
        
        soWrapped.id = soIn.Id;
        soWrapped.account_code = soIn.Customer_No__c;
        soWrapped.action_taken = soIn.Action_Taken__c;
        soWrapped.caseNumber = soIn.Case_Number__c;
        soWrapped.company = soIn.TECH_Company_Code__c;
        soWrapped.territory_company = soIn.TECH_Work_Order_Territory_Branch_Code__c;
        soWrapped.customer_ref = soIn.Customer_Reference__c;
        soWrapped.initial_findings = soIn.Initial_Findings__c;
        //date format: year/month/day
        soWrapped.order_date = (soIn.Order_Date__c != null ? string.valueOf(date.newinstance(soIn.Order_Date__c.year(), soIn.Order_Date__c.month(), soIn.Order_Date__c.day())) : null );
        soWrapped.project_code = soIn.SC_Project_Code__c ;
        soWrapped.reported_fault = soIn.Reported_Fault__c;
        soWrapped.site = soIn.Site__c;
        soWrapped.suggested_followup = soIn.Suggested_Follow_up__c;
        soWrapped.work_order = (soIn.Work_Order__c != null ? [SELECT WorkOrderNumber FROM WorkOrder WHERE ID =: soIn.Work_Order__c ].WorkOrderNumber : null);
        if(soIn.LastModifiedDate != null){
            soWrapped.timestamp = soIn.LastModifiedDate.getTime();
        }
        
        if(soIn.createdDate != null){
            soWrapped.timestamp = soIn.createdDate.getTime();
        }
        
        if(soWrapped.timestamp == null)
        {
            soWrapped.timestamp = System.now().getTime();
        }
        return soWrapped;
    }
    
    public static SalesOrderItems WrappedSOLI(Sales_Order_Line_Item__c soliIn){
        SalesOrderItems soliWrapped = new SalesOrderItems();
        
        soliWrapped.id = soliIn.Id;
        soliWrapped.description = soliIn.Description__c;
        soliWrapped.notes = soliIn.Notes__c != null ? soliIn.Notes__c.replaceAll('<br>','\r\n') : '';
        soliWrapped.measure = soliIn.Units__c;
        soliWrapped.price = soliIn.Item_Price__c.setScale(2);
        soliWrapped.qty = soliIn.Order_Quantity__c;
        soliWrapped.work_order = (soliIn.Work_Order_Line_Item__c != null ? [SELECT Id, LineItemNumber FROM WorkOrderLineItem WHERE ID =: soliIn.Work_Order_Line_Item__c ].LineItemNumber : null);
        soliWrapped.technician = soliIn.Technician__c;
        soliWrapped.tax_rate = soliIn.Tax_Rate__c != null ? soliIn.Tax_Rate__c : 10.0;

        return soliWrapped;
    }
}