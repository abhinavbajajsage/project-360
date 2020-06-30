public class Constants {

    public static final String ORG_EMAIL_SAGE_SERVICE = 'sageservice@gotosage.com';
    
    // Resource Type Global Picklist
    public static final String TYPE_ENGINEER = 'Engineer';
    public static final String TYPE_TECHNICIAN = 'Technician';
    
    // Contract Type Global Picklist
    public static final String TYPE_BRONZE = 'Bronze Support';
    public static final String TYPE_SILVER = 'Silver Support';
    
    // Product Service Time Picklist
    public static final String SERVICE_BUSINESS = 'Business Hours';
    public static final String SERVICE_OVERTIME = 'Overtime';
    public static final String SERVICE_NIGHT = 'Night Time';

    //Timezone Key
    public static final String TIMEZONE_ADELAIDE = 'Australia/Adelaide';
    
    
    // Account Record Type label
    public static final String ACC_COMPANY_RT = 'Company';  
    public static final String SUPPLIER_ACCOUNT_RT = 'Supplier'; 
    public static final String CASH_ACCOUNT_RT = 'Cash Account';  
    
    // Service Contract Record Type label
    public static final String SCO_CustomerContract_RT = 'Customer Contract'; 
    public static final String SCO_TemplateContract_RT = 'Template Contract'; 
    
    // Service Contract Billing Cycle Picklist
    public static final String CYCLE_YEARLY = 'Yearly';
    public static final String CYCLE_MONTHLY = 'Monthly';
    public static final String CYCLE_QUATERLY = 'Quarterly';
    public static final String CYCLE_HALFYEARLY = 'Half Yearly';
    public static final String CYCLE_AGGREGATE= 'Aggregated Billing';
    public static final String CYCLE_INDIVIDUAL = 'Individual Work Orders';

    // Service Contract Billing Cycle Type Picklist
    public static final String CYCLE_TYPE_IN_ADVANCE = 'In Advance';
    public static final String CYCLE_TYPE_IN_ARREARS = 'In Arrears';
    
    // Sales Order Record Type DevelopperName 
     public static final String SOR_DEV_ContractFees_RT = 'ContractFees_SalesOrder_RT';
   
    
    // Error Logs Record Type DevelopperName
     public static final String ERR_DEV_ContractFees_RT = 'ContractFees_ErrorLog_RT';
     public static final String ERR_DEV_Case_RT = 'Case_ErrorLog_RT';
   
    // Sales Order Units Picklist
    public static final String UNITS_EACH = 'EACH';  

    // Service Appointment Statuses
    public static final String SERVICE_APPOINMENT_STATUS_ACCEPTED = 'Accepted';
    public static final String SERVICE_APPOINMENT_STATUS_INPROGRESS = 'In Progress';
    public static final String SERVICE_APPOINMENT_STATUS_ARRIVED = 'Arrived On Site';
    public static final String SERVICE_APPOINMENT_STATUS_COMPLETE = 'Completed';
    public static final String SERVICE_APPOINMENT_STATUS_CANNOT_COMPLETE = 'Cannot Complete';

    //Purchase Order Status
    public static final String PURCHASE_ORDER_STATUS_APPROVED = 'Approved';
    public static final String PURCHASE_ORDER_STATUS_PENDING_APPROVED = 'Approval Pending';
    public static final String PURCHASE_ORDER_STATUS_CANCELLED = 'Cancelled';
    
    //Work Order Status
    public static final String WORK_ORDER_STATUS_READY_TO_INVOICE = 'Ready To Invoice';
    
    //Integration Status Global picklist
    public static final String INTEGRATION_STATUS_PENDING = 'Integration Pending';
    public static final String INTEGRATION_STATUS_FAILED = 'Failed';
 
}