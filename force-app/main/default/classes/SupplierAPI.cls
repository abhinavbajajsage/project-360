/*******************************************************************************
* @author          Cyrille Jeufo (Proquest Consulting)
* @date            10.Nov.2019        
* @description  	   Supplier API. This class handles requests from Pronto
• @revision 
• v1.0      - Refer purpose 
*******************************************************************************/

@RestResource(urlMapping='/Supplier/*')
global with sharing class SupplierAPI {
    private static String supplierRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Supplier').getRecordTypeId();
    
    @HttpPut
    global static void updateSuppliers() {
        RestRequest request = RestContext.request;
        RestResponse res = RestContext.response;
        String jsonResponse = '';
        try {
            
            String content = request.requestbody.tostring();
            List<Utilities.SupplierWrapper> accwrpList = (List<Utilities.SupplierWrapper>)JSON.deserialize(content, List<Utilities.SupplierWrapper>.class);
            
            List<Account> suppliers = new List<Account>();
            
            //Get a list of accounts
            for(Utilities.SupplierWrapper acc : accwrpList){
                suppliers.add(Utilities.getUnwrappedAccount(acc , false));
            }
            
            System.debug('$$$ ' + suppliers);
            
            Database.update(suppliers , true);
            
            jsonResponse = Json.serialize(suppliers);
            res.statusCode = 200;
            res.responseBody = blob.valueOf(jsonResponse);
            
            return;
        } catch ( Exception ex ) {
            res.statusCode = 500;
            jsonResponse = '{"response": {"Status": "Failure", "message": "' + ex + '"}}';
            res.responseBody = blob.valueOf(jsonResponse);
            return;
        }
        
    }
    
    @HttpPost
    global static void createSupplier() {
        RestRequest request = RestContext.request;
        RestResponse res = RestContext.response;
        String jsonResponse = '';
        try {
            
            String content = request.requestbody.tostring();
            Utilities.SupplierWrapper accwrp = (Utilities.SupplierWrapper)JSON.deserialize(content, Utilities.SupplierWrapper.class);
            
            System.debug('$$$Wrapper ' + accwrp);
            Account acc = Utilities.getUnwrappedAccount(accwrp , false);
            
            //mandatory field
            if(String.isEmpty(acc.Pronto_Account_Code__c) || String.isEmpty(acc.Name)){
                res.statusCode = 400;
                res.responseBody = blob.valueOf(Utilities.MANDATORY_ATTRIBUTES_MISSING);
                return;
            }
            
            List<Account> accs = [Select Id , Name, Pronto_Account_Code__c from Account where Pronto_Account_Code__c = :acc.Pronto_Account_Code__c or name = :acc.name];
            if(accs.size() > 0){
                res.statusCode = 500;
                String message = '{"response": {"Status": "Failure", "message": "Duplicate record found based on the name or the account code", "DuplicateRecords" : ' + accs + '}}';
                res.responseBody = blob.valueOf(message);
                return;
            }
            
            insert acc;
            
            jsonResponse = Json.serialize(acc);
            res.statusCode = 200;
            res.responseBody = blob.valueOf(jsonResponse);
            
            return;
        } catch ( Exception ex ) {
            res.statusCode = 500;
            jsonResponse = '{"response": {"Status": "Failure", "message": "' + ex + '"}}';
            res.responseBody = blob.valueOf(jsonResponse);
            return;
        }
        
    }
    
    @HttpPatch
    global static void updateSupplier() {
        RestRequest request = RestContext.request;
        RestResponse res = RestContext.response;
        String jsonResponse = '';
        try{
            String key = request.requestURI.substring(
                request.requestURI.lastIndexOf('/')+1);
            
            //account code or SFID is mandatory	
            if(String.isEmpty(key)) {
                res.statusCode = 400;
                res.responseBody = blob.valueOf(Utilities.MISSING_QUERY_PARAM);
                return;
            }
            
            ID sfId;
            String accountCode;
            
            //Is Salesforce Id or account code?
            If(key.startsWithIgnoreCase('001')){
                sfId = key;
            }else{
                accountCode = key;
            }
            
            List<Account> accounts = searchAccount(sfId , accountCode);
            
            if(accounts.size() == 0) {
                res.statusCode = 404;
                res.responseBody = blob.valueOf(Utilities.ACCOUNT_NOT_FOUND);
                return;
            }
            
            String content = request.requestbody.tostring();
            
            Utilities.SupplierWrapper accwrp = (Utilities.SupplierWrapper)JSON.deserialize(content, Utilities.SupplierWrapper.class);
            
            Account acc = Utilities.getUnwrappedAccount(accwrp , false); 
            //check query parameter payload
            if(sfId != null && acc.Id != null){
                if(sfId != acc.Id){
                    res.statusCode = 403;
                    res.responseBody = blob.valueOf(Utilities.SERVER_DENIED_REQUEST);
                    return;
                    
                }
            }
            
            //check query parameter payload
            if(accountCode != null && String.isNotBlank(acc.Pronto_Account_Code__c)){
                if(accountCode != acc.Pronto_Account_Code__c){
                    res.statusCode = 403;
                    res.responseBody = blob.valueOf(Utilities.SERVER_DENIED_REQUEST);
                    return;
                    
                }
            }
            if(String.isNotBlank(acc.Id)){
                upsert acc acc.Id;
            }else{
                upsert acc acc.Pronto_Account_Code__c;
            }
            
            System.debug('####### acc ' +acc);
            
            res.statusCode = 200;
            res.responseBody = blob.valueOf(Json.serialize(acc));
            
        }catch(Exception ex){
            res.statusCode = 500;
            jsonResponse = '{"response": {"status": "Failure", "message": "' + ex + '"}}';
            res.responseBody = blob.valueOf(jsonResponse);
        }
    }
    
    //this method returns a list of account based on the keys on the account object
    private static List<Account> searchAccount(String sfId , String accountCode){
        List<Account> accounts = new List<Account>();
        if(String.isNotBlank(accountCode) && String.isNotBlank(sfId)){
            accounts = [SELECT Id , Pronto_Account_Code__c FROM Account WHERE Pronto_Account_Code__c = :accountCode AND Id =: sfId AND recordTypeId = :supplierRecordTypeId];
        }else if(String.isNotBlank(sfId)){
            accounts = [SELECT Id , Pronto_Account_Code__c FROM Account WHERE Id =: sfId AND recordTypeId = :supplierRecordTypeId];
        }else if(String.isNotBlank(accountCode)){
            accounts = [SELECT Id ,  Pronto_Account_Code__c FROM Account WHERE Pronto_Account_Code__c =: accountCode AND recordTypeId = :supplierRecordTypeId];
        }
        
        return accounts;
    }
    
    
}