/**
* 
@author: Imalka Fernando - Proquest Consulting
@description: classes wrapping Purchase order for cancellation
* 
*/
public class PurchaseOrderCancel {
    public String id {get;set;} 
    public String external_order_number {get;set;} 
    public String cancellation_reason {get;set;} 
    public String account_code {get;set;} 
    public Long timestamp {get;set;} 

    public static PurchaseOrderCancel WrappedPO(Purchase_Order__c poIn){
        PurchaseOrderCancel poWrapped = new PurchaseOrderCancel();
        
        poWrapped.id = poIn.Id;
        poWrapped.external_order_number = poIn.Name;
        poWrapped.account_code = poIn.Account_Code__c;
        poWrapped.cancellation_reason = poIn.Cancellation_Reason__c;
        
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
}