/**
* 
@author: Cyrille Jeufo - Proquest Consulting
@description: This class handles all data retrieval relative to integrations around Pronto
* 
*/
public class SyncWithProntoDAO {
    
    /**
    * 
    @author: Cyrille Jeufo - Proquest Consulting
    @description: retrieves the HTTP settings to make a callout
    * 
    */
    public static HTTP_Request__mdt getHTTPSettings(String context){
        if(String.isNotBlank(context))
        {
            List<HTTP_Request__mdt> httpSettings = new List<HTTP_Request__mdt>();
            httpSettings = [SELECT Id, URL__c, Method__c, Subscription_Key__c, Version__c, Content_Type__c ,Conflux_River__c, DeveloperName,Timeout__c FROM HTTP_Request__mdt where DeveloperName =: context];
        	if(httpSettings.size() > 0) return httpSettings[0];
        }
        return null;

    }
    
    /**
    * 
    @author: Cyrille Jeufo - Proquest Consulting
    @description: If there is contact on the service contract, use otherwise use contact on the work order is present
    * Update: Instead of getting contact from Service Contract, get it from the Case object 
    */
   	public static String getSalesOrderContact(Sales_Order__c so){
        String contactName;
        List<ServiceContract> contracts = new List<ServiceContract>();
        List<Case> contactFromCase = new List<Case>();
        List<WorkOrder> wos = new List<WorkOrder>();
        List<Contact> contacts = new List<Contact>();
        /* If(so.Service_Contract__c != null){
       
            contracts = [Select Id , ContactId FROM ServiceContract WHERE Id =: so.Service_Contract__c  limit 1];

             if(contracts.size() > 0 ){
                contacts = [Select Id , Name From Contact where Id =: contracts[0].ContactId];
                if(contacts.size() > 0) 
				contactName = contacts[0].Name;
            } 

        } */
        
        If(so.Case__c != null){
            contactFromCase = [Select Id , Contact__c FROM Case WHERE Id =: so.Case__c  limit 1];
            if(contactFromCase.size() > 0 ){  
              contactName = contactFromCase[0].Contact__c;
            }
        }
        
        if(String.isBlank(contactName) && so.Work_Order__c != null){
            wos = [Select Id , ContactId FROM WorkOrder WHERE Id =: so.Work_Order__c  limit 1];
            if(wos.size() > 0){
                contacts = [Select Id , Name From Contact where Id =: wos[0].ContactId limit 1];
                if(contacts.size() > 0) contactName = contacts[0].Name;
            }
        }
        
        return contactName;
    }
    
}