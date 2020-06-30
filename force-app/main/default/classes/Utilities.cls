/*******************************************************************************
* @author          Cyrille Jeufo (Proquest Consulting)
* @date            10.Nov.2019        
* @description This is a helper class for the SAGE API implementation
• @revision 
• v1.0      - Refer purpose 
*******************************************************************************/
public class Utilities {
    public static final string ACCOUNT_CODE_MISSING = System.Label.Account_Code_Missing_CL;
    public static final string ACCOUNT_NOT_FOUND = System.Label.Account_Not_Found_CL;
    public static final string DUPLICATE_RECORD = System.Label.Duplicate_Record_CL ;
    public static final string MALFORMED_BODY = System.Label.Malformed_Body_CL;
    public static final string MANDATORY_ATTRIBUTES_MISSING = System.Label.Mandatory_Attributes_Missing_CL;
    public static final string MISSING_QUERY_PARAM = System.Label.Missing_Query_Parameter_CL;
    public static final string CUSTOMER = System.Label.Customer_CL;
    public static final string NOC_ADMIN_EMAIL = System.Label.NOC_Admin_Email_CL;
    public static final string SERVER_DENIED_REQUEST = System.Label.Server_Denied_Request_CL;
    public static final string TERRITORY_MISSING = System.Label.TERRITORY_MISSING_CL;
    
    //integration Statuses
    public static final string INTEGRATION_PENDING = System.Label.Integration_Status_Pending_CL;
    public static final string INTEGRATION_SUCCESSFUL = System.Label.Integration_Status_Successful_CL;
    public static final string INTEGRATION_FAILED = System.Label.Integration_Status_Failure_CL;
    public static final string UNEXPECTED_EXCEPTION = System.Label.Integration_Status_Unexpected_Exception_CL;
    public static final string INTEGRATION_CANCELLED = System.Label.Integration_Status_Cancelled_CL;
    public static final string INVALID_INDUSTRY_CODE = System.Label.Integration_Invalid_Industry_Code_CL;
    public static final string CUSTOMER_STATUS_PENDING = System.Label.Customer_Status_Pending_CL;
    public static final string INTEGRATION_DENIED = System.Label.Integration_Denied_CL;
    public static final string INTEGRATION_WAITING = System.Label.Integration_Status_Waiting_Confirmation_CL;
    public static final string INTEGRATION_PAYROLL_VALIDATED = System.Label.Integration_Status_Payroll_Validated_CL;
    
    public static boolean woliUpdateAllowed = false;
    
    //Customer Integration
    public static final string CUSTOMER_TRIGGER_POINTS = System.Label.Account_Integration_Trigger_Points_CL;
    
    public class SupplierWrapper {
        public String id;
        public String name;
        public String postal_name;
        public String postal_street;
        public String postal_city;
        
        public String postal_postal_code;
        public String postal_state;
        public String postal_country;
        public String business_name;
        public String business_street;
        
        public String business_city;
        public String business_postal_code;
        public String business_state;
        public String business_country;
        public String phone;
        
        public String fax;
        public String abn;
        public String nature_of_business;
        public String acn;
        public String account_code;
        public String territory;
        public String email;
        public Long timestamp;
        public string contact_name;
        public string status;
        public string notes;
        public String credit_limit;
    }
    
    public static SupplierWrapper getWrappedAccount(Account accountIn){
        System.debug('@@@AccountIn ' + accountIn);
        SupplierWrapper acc = new SupplierWrapper();
        acc.Id = accountIn.Id;
        acc.Name = accountIn.Name;
        acc.postal_name = accountIn.Postal_Name__c;
        acc.postal_street = accountIn.ShippingStreet;
        acc.postal_city = accountIn.ShippingCity;
        acc.postal_postal_code = accountIn.ShippingPostalCode;
        acc.postal_state = accountIn.ShippingState;
        acc.postal_country = accountIn.ShippingCountry;
        //
        acc.business_street = accountIn.BillingStreet;
        acc.business_city = accountIn.BillingCity;
        acc.business_postal_code = accountIn.BillingPostalCode;
        acc.business_state = accountIn.BillingState;
        acc.business_country = accountIn.BillingCountry;
        acc.business_name = accountIn.Registered_Business_Name__c;
        //        
        acc.phone = accountIn.Phone;
        acc.email = accountIn.Email__c;
        acc.fax = accountIn.Fax;
        acc.abn = accountIn.abn__c;
        acc.nature_of_business = accountIn.Industry;
        acc.acn = accountIn.acn__c;
        acc.notes = accountIn.Notes__c;
        acc.account_code = accountIn.Pronto_Account_Code__c;
        acc.credit_limit = accountIn.Credit_Limit__c;
        acc.status = accountIn.Customer_Status__c == 'OK' ? ' ':accountIn.Customer_Status__c;

        
        if(accountIn.LastModifiedDate != null){
            acc.timestamp = accountIn.LastModifiedDate.getTime();
            return acc;
        }
        
        if(accountIn.createdDate != null){
            acc.timestamp = accountIn.createdDate.getTime();
            return acc;
        }
        
        if(acc.timestamp == null)
        {
            acc.timestamp = System.now().getTime();
            return acc;
        }
        return null;
    }
    
    public static ID getAccountRecordType(String recordTypeName)
    {
        return Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
    }
    
    public static Account getUnwrappedAccount(SupplierWrapper wrp , Boolean isCompany){
        Account newAccount = new Account();
        
        newAccount.Id = wrp.Id;
        newAccount.Name = wrp.Name;
        newAccount.Postal_Name__c = wrp.postal_name;
        
        newAccount.ShippingStreet = wrp.postal_street;
        newAccount.ShippingCity =   wrp.postal_city;
        newAccount.ShippingPostalCode = wrp.postal_postal_code;
        newAccount.ShippingState = wrp.postal_state;
        newAccount.ShippingCountry = wrp.postal_country;
        
        newAccount.Registered_Business_Name__c =  wrp.business_name;
        
        newAccount.BillingStreet =  wrp.business_street;
        newAccount.BillingCity =  wrp.business_city;
        newAccount.BillingPostalCode =  wrp.business_postal_code;
        newAccount.BillingState =  wrp.business_state;
        newAccount.BillingCountry =  wrp.business_country;
        
        newAccount.Phone =  wrp.phone;
        newAccount.Email__c = wrp.email;
        
        newAccount.Fax = wrp.fax;
        newAccount.abn__c = wrp.abn;
        newAccount.acn__c = wrp.acn;
        newAccount.Pronto_Account_Code__c = wrp.account_code;
        newAccount.recordTypeId = getAccountRecordType(isCompany ? 'Company' : 'Supplier');
        
        return newAccount;
    }
    
    
   public static void logError(Account record , Exception ex , String recordType){
        System.debug('@@@Exception ' + ex.getMessage());
        Error_log__c logRecord = new Error_log__c(Customer__c = record.Id, Message__c   = ex.getStackTraceString(), recordTypeId = recordType, Status__c = 'Unexpected error', Status_Code__c = '-1',Subject__c = ex.getMessage() );
        insert logRecord; 
    }
    
    public static void logError(WorkOrderLineItem record , Exception ex , String recordType){
        System.debug('@@@Exception ' + ex.getMessage());
        Error_log__c logRecord = new Error_log__c(workOrderLineItem__c = record.Id, Message__c  = ex.getStackTraceString(), recordTypeId = recordType, Status__c = 'Unexpected error', Status_Code__c = '-1',Subject__c = ex.getMessage() );
        insert logRecord; 
    }
    
    public static void logError(Sales_Order__c record , Exception ex , String recordType){
        System.debug('@@@Exception ' + ex.getMessage());
        Error_log__c logRecord = new Error_log__c(Sales_Order__c = record.Id, Message__c    = ex.getStackTraceString(), recordTypeId = recordType, Status__c = 'Unexpected error', Status_Code__c = '-1',Subject__c = ex.getMessage() );
        insert logRecord; 
    }

    public static void logError(Purchase_Order__c record , Exception ex , String recordType){
        System.debug('@@@Exception ' + ex.getMessage());
        Error_log__c logRecord = new Error_log__c(Purchase_Order__c = record.Id, Message__c = ex.getStackTraceString(), recordTypeId = recordType, Status__c = 'Unexpected error', Status_Code__c = '-1',Subject__c = ex.getMessage() );
        insert logRecord; 
    }

    public static void logError(String emailBody , Exception ex , String recordType){
        System.debug('@@@Exception ' + ex.getMessage());
        Error_log__c logRecord = new Error_log__c(Message__c    = ex.getMessage(), recordTypeId = recordType, Status__c = 'Unexpected error', Status_Code__c = '-1',Subject__c = 'Email to Case Creation Failure', Email_Body__c = emailBody );
        insert logRecord; 
    }

    public static void logError(String emailBody , String errorMessage , String recordType){
        Error_log__c logRecord = new Error_log__c(Message__c    = errorMessage, recordTypeId = recordType, Status__c = 'Unexpected error', Status_Code__c = '-1',Subject__c = 'Email to Case Creation Failure', Email_Body__c = emailBody );
        insert logRecord; 
    }

    // round date time second seconds to 0
    public static DateTime DatetimeZeroSecond(DateTime dtime){
        
        datetime myDateTime = datetime.newInstance(dtime.Year(),dtime.month(), dtime.day(), dtime.hour(), dtime.minute(), 0 );
        return myDateTime;

       
    }

    public static Decimal getActualHours(Datetime startDate, Datetime endDate){
        Long dt1Long = DatetimeZeroSecond(startDate).getTime();
        Long dt2Long = DatetimeZeroSecond(endDate).getTime();
        Long milliseconds = dt2Long - dt1Long;
        Long seconds = milliseconds / 1000;
        Decimal minutes = seconds / 60;
        Decimal hours = minutes.divide(60,2);
        return hours;
        
    }

    public static Boolean isOutsidePayrollCutoffTime(Datetime timeToCheck, Datetime today){

        Datetime cutOffTime = getLastCutoffDay(today);
        Datetime startOfWeekDay = today.addDays(1 - Integer.valueOf(today.format('u')));
        Datetime startOfWeek = Datetime.newInstance(startOfWeekDay.year(), startOfWeekDay.month(), startOfWeekDay.day(), 0, 0, 0) ;    
        Datetime startOfPreviousWeek = startOfWeek.addDays(-7);
        
        System.debug('***today:'+today);
        System.debug('***timeToCheck:'+timeToCheck);
        System.debug('***cutOffTime:'+cutOffTime);
        System.debug('***startOfWeek:'+startOfWeek);
        System.debug('***startOfPreviousWeek:'+startOfPreviousWeek);

        // Start Time of the Transaction is in the current week 
        if(timeToCheck >= startOfWeek){
            return false;
        }
        // Start Time of the Transaction is before the start of the previous week
        if(timeToCheck < startOfPreviousWeek){
            return true;
        }
        // Start Time of the transaction is in the previous week
        if(timeToCheck < startOfWeek  && timeToCheck >= startOfPreviousWeek){

            if(today > cutOffTime){
                return true;            
            } else if(today < cutOffTime){
                 return false;
            }   
        }

        return false;
    }
    
    public static Datetime getLastCutoffDay(Datetime today){
        List<Payroll_Cutoff_Time__mdt> pSettings = [SELECT Id, Day_of_Week__c, Time__c, Time_Zone__c FROM Payroll_Cutoff_Time__mdt limit 1];
        String timeZone = pSettings.get(0).Time_Zone__c;
        String dayOfWeek = today.format('E'); 
        String st = pSettings.get(0).Time__c;
        Integer hr = Integer.valueOf(st.substring(0,st.indexOf(':')));
        Integer min = Integer.valueOf(st.substring(st.indexOf(':')+1,st.indexOf(' ')));
        String ampm = st.substring(st.indexOf(' ')+1,st.length());
        Datetime dt = null;

        if(ampm == 'PM') {
            if(hr != 12){
                hr += 12;               
            }
        }else if(ampm == 'AM'){
            hr = 0;
        }
        
        dt = today.addDays(Integer.valueOf(pSettings.get(0).Day_of_Week__c) - Integer.valueOf(today.format('u')));
        
        Datetime localCutOff = Datetime.newInstance(dt.year(), dt.month(), dt.day(), hr, min, 0);   
        string dateTimeStr = localCutOff.format('yyyy-MM-dd HH:mm:ss',  timeZone);
        Datetime CutOffTimezoneDateTime = DateTime.valueOf(dateTimeStr);
        
          return CutOffTimezoneDateTime;
    }
    
}