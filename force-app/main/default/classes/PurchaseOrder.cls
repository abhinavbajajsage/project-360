/**
* 
@author: Imalka Fernando - Proquest Consulting
@description: classes wrapping Purchase order and Purchase Order line items
* 
*/
public class PurchaseOrder {

    public String id {get;set;} 
    public String work_order {get;set;} 
    public String sf_order_number {get;set;} 
    public String account_code {get;set;} 
    public String line_of_business_code {get;set;} 
    public String order_type {get; set;}
    public String order_date {get;set;} 
    public String arrival_date {get;set;} 
    public String delivery_instructions {get;set;} 
    public String warehouse {get;set;} 
    public String currency_code {get;set;} 
    public Double currency_rate {get;set;} 
    public String user {get;set;} 
    public String project_code {get;set;} 
    public String company {get;set;} 
    public String territory_company {get;set;} 
    public String postal_name {get;set;} 
    public String postal_street {get;set;} 
    public String postal_city {get;set;} 
    public String postal_state {get;set;} 
    public String postal_country {get;set;} 
    public String postal_postal_code {get;set;}
    public String notes {get;set;} 
    public List<PurchaseOrderItems> purchase_order_items {get;set;} 
    public Long timestamp {get;set;} 
    
    public class PurchaseOrderItems {
        public String id {get;set;} 
        public Integer salesforce_line_id {get;set;} 
        public String supplier_code {get;set;} 
        public Double qty {get;set;} 
        public Double price {get;set;} 
        public String measure {get;set;} 
        public Double tax_rate {get;set;} 
        public String date_expected {get;set;} 
        public String item_description {get;set;} 
    }
    
    public static PurchaseOrder WrappedPO(Purchase_Order__c poIn){
        PurchaseOrder poWrapped = new PurchaseOrder();
        
        poWrapped.id = poIn.Id;
        poWrapped.work_order = (poIn.Work_Order__c != null ? [SELECT WorkOrderNumber FROM WorkOrder WHERE ID =: poIn.Work_Order__c ].WorkOrderNumber : null);
        poWrapped.sf_order_number = poIn.Name;
        poWrapped.account_code = poIn.Account_Code__c;
        poWrapped.line_of_business_code = poIn.Line_of_Business_Code__c;
        poWrapped.order_type = poIn.Type__c;
        //date format: year/month/day
        poWrapped.order_date = (poIn.Order_Date__c != null ? string.valueOf(date.newinstance(poIn.Order_Date__c.year(), poIn.Order_Date__c.month(), poIn.Order_Date__c.day())) : null );
        poWrapped.arrival_date = (poIn.Due_Date__c != null ? string.valueOf(date.newinstance(poIn.Due_Date__c.year(), poIn.Due_Date__c.month(), poIn.Due_Date__c.day())) : null );
        poWrapped.delivery_instructions = poIn.Delivery_Instructions__c;
        
        poWrapped.warehouse = poIn.Warehouse_Code__c ;
        poWrapped.currency_code = poIn.Currency__c;
        poWrapped.currency_rate = poIn.Currency_Rate__c;
        poWrapped.user = poIn.User__c;
        poWrapped.project_code = poIn.SC_Project_Code__c;
        poWrapped.company = poIn.Company__c;
        poWrapped.territory_company = poIn.TECH_Work_Order_Territory_Branch_Code__c;
        poWrapped.postal_name = poIn.Delivery_Address_Name__c;
        poWrapped.postal_street = poIn.Postal_Street__c;
        poWrapped.postal_city = poIn.Postal_City__c;
        poWrapped.postal_state = poIn.Postal_State__c;
        poWrapped.postal_country = poIn.Postal_Country__c;
        poWrapped.postal_postal_code = poIn.Postal_Postcode__c;
        poWrapped.notes = poIn.Notes__c != null ? poIn.Notes__c.replaceAll('<br>','\n') : '';

        if(poIn.LastModifiedDate != null){
            poWrapped.timestamp = poIn.LastModifiedDate.getTime();
        }
        
        if(poIn.createdDate != null){
            poWrapped.timestamp = poIn.createdDate.getTime();
        }
        
        if(poWrapped.timestamp == null)
        {
            poWrapped.timestamp = System.now().getTime();
        }
        return poWrapped;
    }
    
    public static PurchaseOrderItems WrappedPOLI(Purchase_Order_Line_Item__c poliIn){
        PurchaseOrderItems poliWrapped = new PurchaseOrderItems();
        
        poliWrapped.id = poliIn.Id;
        poliWrapped.salesforce_line_id = Integer.valueOf(poliIn.POLI_Number__c);
        poliWrapped.supplier_code = poliIn.Supplier_Code__c;
        poliWrapped.qty = poliIn.Quantity__c;
        poliWrapped.price = poliIn.Cost__c;
        poliWrapped.measure = poliIn.Units__c;
        poliWrapped.tax_rate = poliIn.Tax_Rate__c;
        poliWrapped.date_expected = (poliIn.Date_Expected__c != null ? string.valueOf(date.newinstance(poliIn.Date_Expected__c.year(), poliIn.Date_Expected__c.month(), poliIn.Date_Expected__c.day())) : null );
        poliWrapped.item_description = poliIn.Description__c;

        return poliWrapped;
    }
}