/**
* 
@author: Cyrille Jeufo - Proquest Consulting
@description: This class retrieves all records matching a query passed from SyncWithProntoJob and
			  set Sync_With_Pronto__c to true so that the relevant trigger starts the integration
* 
*/
global class SyncWithProntoBatch implements Database.Batchable<sObject> , Database.AllowsCallouts , Database.Stateful{
    global final String Query;
    public String customer_recordtype = Schema.SObjectType.Error_log__c.getRecordTypeInfosByDeveloperName ().get('Account_ErrorLog_RT').getRecordTypeId();
    public String transaction_recordtype = Schema.SObjectType.Error_log__c.getRecordTypeInfosByDeveloperName ().get('Transaction_ErrorLog_RT').getRecordTypeId();
    private static String salesOrderRecordtypeId = Schema.SObjectType.Sales_Order__c.getRecordTypeInfosByDeveloperName ().get('WorkOrder_SalesOrder_RT').getRecordTypeId();
    public static String so_recordtype = Schema.SObjectType.Error_log__c.getRecordTypeInfosByDeveloperName ().get('SalesOrder_ErrorLog_RT').getRecordTypeId();

    public Set<String> processed = new Set<String>();
    public List<Account> accounts = new List<Account>();
    public List<WorkOrderLineItem> wolis = new List<WorkOrderLineItem>();
    public List<Sales_Order__c> salesOrders = new List<Sales_Order__c>();
    
    
    public List<Error_log__c> logs = new List<Error_log__c>();
    public Set<Id> logAlreadyCreated = new Set<Id>();
    global SyncWithProntoBatch(String queryIn){
        Query = queryIn;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, 
                        List<sObject> scope){

        for(Sobject obj : scope){
            //accounts
            if(obj.getSObjectType().getDescribe().getName() == 'Account'){
                Account acc = (Account)obj;
                if(processed.contains(acc.Id)) continue;
                acc.Sync_With_Pronto__c = true;
                acc.Integration_Status__c = Utilities.INTEGRATION_PENDING;
                accounts.add(acc);
                processed.add(acc.Id);
            }else if(obj.getSObjectType().getDescribe().getName() == 'WorkOrderLineItem'){
                WorkOrderLineItem woli = (WorkOrderLineItem)obj;
                if(processed.contains(woli.Id)) continue;

                woli.Sync_With_Pronto__c = true;
                woli.Integration_Status__c = Utilities.INTEGRATION_PENDING;
                woli.Send_Timesheet__c = false;
                
                SynchWithPronto syncjob = new SynchWithPronto(woli , 'WorkOrderLineItem', true);
                ID jobID = System.enqueueJob(syncjob);

                processed.add(woli.Id);
            }else if(obj.getSObjectType().getDescribe().getName() == 'Sales_Order__c'){
                Sales_Order__c so = (Sales_Order__c)obj;
                //do not sync if created from work order or already synced
                if(processed.contains(so.Id)) continue;
                SynchWithPronto syncjob = new SynchWithPronto(so , 'SalesOrder');
                ID jobID = System.enqueueJob(syncjob);
                processed.add(so.Id);
            }else if(obj.getSObjectType().getDescribe().getName() == 'Purchase_Order__c'){
                Purchase_Order__c po = (Purchase_Order__c)obj;
                if(processed.contains(po.Id)) continue;
                SynchWithPronto syncjob = new SynchWithPronto(po , 'PurchaseOrder');
                ID jobID = System.enqueueJob(syncjob);
                processed.add(po.Id);
            }
        }
                            
        System.debug('$$$accounts size ' + accounts.size());
        if(accounts.size() > 0) {
            List<Database.SaveResult> result = Database.update(accounts , false);  
            // Iterate through each returned result
            System.debug('@@@ accounts result ' + result );
            for (Database.SaveResult sr : result) {
                for (Integer i = 0; i < accounts.size(); i++) {
                	if (!sr.isSuccess() && !logAlreadyCreated.contains(accounts[i].Id)) {
                        for(Database.Error err : sr.getErrors()){
                            Error_log__c logRecord = new Error_log__c(Customer__c = accounts[i].Id , Message__c	=   err.message, recordTypeId = customer_recordtype, Subject__c = String.valueOf(err.statusCode));
                            logs.add(logRecord);
                        }
                        logAlreadyCreated.add(accounts[i].Id);
                    }
                }
            }
        }
        
        // System.debug('$$$wolis ' + wolis);
        // System.debug('$$$wolis size ' + wolis.size());
        // if(wolis.size() > 0) {
        //     List<Database.SaveResult> result = Database.update(wolis , false) ;  
        //     // Iterate through each returned result
        //     System.debug('@@@wolis result ' + result );
        //     for (Database.SaveResult sr : result) {
        //         for (Integer i = 0; i < wolis.size(); i++) {
        //         	if (!sr.isSuccess() && !logAlreadyCreated.contains(wolis[i].Id)) {
        //                 for(Database.Error err : sr.getErrors()){
        //                     Error_log__c logRecord = new Error_log__c(workOrderLineItem__c = wolis[i].Id, Message__c	=   err.message, recordTypeId = transaction_recordtype, Subject__c = String.valueOf(err.statusCode));
        //                     logs.add(logRecord);
        //                 }
        //                 logAlreadyCreated.add(wolis[i].Id);
        //             }
        //         }
        //     }
        // }
                            
    }
    
    global void finish(Database.BatchableContext BC){
        if(logs.size() > 0) Database.insert(logs , false) ;  
    }
    
}