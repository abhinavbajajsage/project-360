/**
* 
@author: Cyrille Jeufo - Proquest Consulting
@initial version: 18/11/2019 - Initial version - Logic determines whether to make a callout or not
Cyrille Jeufo 	- 20/11/2019 -   added method to queue job from after trigger
* 
*/
public class AccountTriggerHandler {
    private static String companyRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName ().get('Company_Account_RT').getRecordTypeId();
    private static String soleTraderRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName ().get('Sole_Trader_Account_RT').getRecordTypeId();
    private static String partnershipRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName ().get('Partnership_Account_RT').getRecordTypeId();
    
    public static void checkAccountTriggerPoints(List<Account> newAccounts , Map<Id , Account> oldAccountMap){
        
        //check that we have some trigger points
        if(String.isNotBlank(Utilities.CUSTOMER_TRIGGER_POINTS)){ 
            
            //This list will be used to store all field that can cause trigger Salesforce => Pronto callout
            Set<String> triggerPoints = new Set<String>();
            if(Utilities.CUSTOMER_TRIGGER_POINTS.Trim().containsIgnoreCase(',')){
                for(String value : Utilities.CUSTOMER_TRIGGER_POINTS.trim().split(',')){
                    triggerPoints.add(value.trim());
                }
            }else{
                triggerPoints.add(Utilities.CUSTOMER_TRIGGER_POINTS.trim());
            }
            
            System.debug('&&&&Trigger points ' + triggerPoints);
            
            //Manual run from the 'Update Pronto' button
            //Or from Batch job
            for(Account acc : newAccounts){ 
                 if(!checkRecursive.SetOfIDs.contains(acc.Id)){
                     //if customer status pending abort
                     if(acc.Customer_Status__c == Utilities.CUSTOMER_STATUS_PENDING) 
                     {
                         acc.Sync_With_Pronto__c = false;
                         acc.Integration_Status__c = Utilities.INTEGRATION_DENIED;
                         continue;
                     }
                    
                     
                    if(acc.Sync_With_Pronto__c == true){
                        acc.Integration_Status__c = Utilities.INTEGRATION_PENDING;
                        continue;
                    }
                     
                    //only Company/Partnership/Sole Trader recordTypes
                    if(acc.RecordTypeId == companyRecordTypeId || acc.RecordTypeId == soleTraderRecordTypeId || acc.RecordTypeId == partnershipRecordTypeId )
                    {
                        for (Schema.SObjectField accField : Schema.SObjectType.Account.fields.getMap().values()) {
                            Schema.DescribeFieldResult describeResult = accField.getDescribe();
                            
                            //for each record look for the trigger point
                            if(triggerPoints.contains(describeResult.getName().trim())){
                                    //for updates we check if any change took place
                                    if(Trigger.isUpdate){
                                        Account oldAccount = (Account) oldAccountMap.get(acc.Id);
                                        if(oldAccount.get(describeResult.getName())  != acc.get(describeResult.getName())){
                                            acc.Sync_With_Pronto__c = true;
                                            System.debug('&&&&Trigger points 2');
                                        }
                                    }
                                //A trigger point was set during record creation
                                if(Trigger.isInsert && acc.get(describeResult.getName()) != null){
                                    acc.Sync_With_Pronto__c = true;
                                    acc.Integration_Status__c = Utilities.INTEGRATION_PENDING;
                                }
                                
                                
                            }
                        }
                    }
                     checkRecursive.SetOfIDs.add(acc.Id);
                 }
            }
            
        }
    }
    
    /**
    * Method to enqueue jobs whenever Sync_With_Pronto__c flag is to true
    * 
    */
    public static void syncWithPronto(List<Account> newAccounts , Map<Id , Account> newAccountMap){
        for(Account acc : newAccounts){
            if(acc.Sync_With_Pronto__c == true){
                if(Limits.getQueueableJobs() == Limits.getLimitQueueableJobs()) continue;
                SynchWithPronto syncjob = new SynchWithPronto(acc , 'Account');
                ID jobID = System.enqueueJob(syncjob);
            }
        }
    }
}