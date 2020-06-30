/*******************************************************************************
* @author          Cyrille Jeufo (Proquest Consulting)
* @date            10.Nov.2019        
* @description  	   Testing the SupplierAPI class
• @revision 
• v1.0      - Refer purpose 
*******************************************************************************/
@IsTest
public class SupplierAPITest {

    @isTest static void testCreateSupplierWithNoBody(){
        RestRequest request = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.response = res;
        request.requestUri  = URL.getSalesforceBaseUrl().toExternalForm()+ '/services/apexrest/Supplier';
        request.httpMethod = 'POST';
        RestContext.request = request;
        SupplierAPI.createSupplier();
    }
    
    //Successfully creates a supplier
    @isTest static void testCreateSupplierPositive(){
        RestRequest request = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.response = res;
        request.requestBody =  Blob.valueOf('{"name":"API Supplier Test 98","postal_name":"Test","postal_street":"Test","postal_city":"Test","postal_postal_code":"Test","postal_state":"Test","postal_country":"Australia","business_name":"name","business_street":"street","business_city":"City","business_postal_code":"2020","business_state":"NSW","business_country":"Australia","phone":"0867899334","fax":"","email":"email@email.com","abn":"","nature_of_business":"","acn":"","account_code":"ABN1234","territory":"","contact_name":"","status":"","notes":"","timestamp":1571113639974}');
        request.requestUri  = URL.getSalesforceBaseUrl().toExternalForm()+ '/services/apexrest/Supplier';
        request.httpMethod = 'POST';
        RestContext.request = request;
        SupplierAPI.createSupplier();
        System.assert(res.statusCode == 200);
        
    }
    
    @isTest static void testCreateSupplierNoAccountCode(){
        RestRequest request = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.response = res;
        request.requestBody =  Blob.valueOf('{"name":"API Supplier Test 0","postal_name":"","postal_street":"","postal_city":"","postal_postal_code":"","postal_state":"","postal_country":"","business_name":"","business_street":"","business_city":"","business_postal_code":"","business_state":"","business_country":"","phone":"","fax":"","email":"","abn":"","nature_of_business":"","acn":"","account_code":"","territory":"","contact_name":"","status":"","notes":"","timestamp":1571113639974}');
        request.requestUri  = URL.getSalesforceBaseUrl().toExternalForm()+ '/services/apexrest/Supplier';
        request.httpMethod = 'POST';
        RestContext.request = request;
        SupplierAPI.createSupplier();
        System.assert(res.statusCode == 400);
    }
    
    //Create a supplier, then attempt to create a supplier with the same Account Code
    @isTest static void testCreateSupplierWithDuplicates(){
        RestRequest request = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.response = res;
        //first record
        request.requestBody =  Blob.valueOf('{"name":"API Supplier Test 98","postal_name":"Test","postal_street":"Test","postal_city":"Test","postal_postal_code":"Test","postal_state":"Test","postal_country":"Australia","business_name":"name","business_street":"street","business_city":"City","business_postal_code":"2020","business_state":"NSW","business_country":"Australia","phone":"0867899334","fax":"","email":"email@email.com","abn":"","nature_of_business":"","acn":"","account_code":"ABN1234","territory":"","contact_name":"","status":"","notes":"","timestamp":1571113639974}');
        request.requestUri  = URL.getSalesforceBaseUrl().toExternalForm()+ '/services/apexrest/Supplier';
        request.httpMethod = 'POST';
        RestContext.request = request;
        SupplierAPI.createSupplier(); 
        System.assert(res.statusCode == 200);
        
        //second record
        res.statusCode = 0; 
        request.requestBody =  Blob.valueOf('{"name":"API Supplier Test 98","postal_name":"Test","postal_street":"Test","postal_city":"Test","postal_postal_code":"Test","postal_state":"Test","postal_country":"Australia","business_name":"name","business_street":"street","business_city":"City","business_postal_code":"2020","business_state":"NSW","business_country":"Australia","phone":"0867899334","fax":"","email":"email@email.com","abn":"","nature_of_business":"","acn":"","account_code":"ABN1234","territory":"","contact_name":"","status":"","notes":"","timestamp":1571113639974}');
        request.requestUri  = URL.getSalesforceBaseUrl().toExternalForm()+ '/services/apexrest/Supplier';
        request.httpMethod = 'POST';
        RestContext.request = request;
        SupplierAPI.createSupplier();
        System.assert(res.statusCode == 500);
        
    } 
    
    
    //UPDATE SUPPLIER
    //Successfully creates a supplier
    @isTest static void testUpdateSupplierPositive(){
        RestRequest request = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        //create supplier
        request.requestBody =  Blob.valueOf('{"name":"API Supplier Test 98","postal_name":"Test","postal_street":"Test","postal_city":"Sydney","postal_postal_code":"Test","postal_state":"Test","postal_country":"Australia","business_name":"name","business_street":"street","business_city":"City","business_postal_code":"2020","business_state":"NSW","business_country":"Australia","phone":"0867899334","fax":"","email":"email@email.com","abn":"","nature_of_business":"","acn":"","account_code":"ABN1234","territory":"","contact_name":"","status":"","notes":"","timestamp":1571113639974}');
        request.requestUri  = URL.getSalesforceBaseUrl().toExternalForm()+ '/services/apexrest/Supplier';
        request.httpMethod = 'POST';
        RestContext.request = request;
        SupplierAPI.createSupplier();
        System.assert(res.statusCode == 200);
        
        
        //No account code or SFID passed - change to postal_city will be denied
        res.statusCode = 0; 
        Account brisbaneSupplier = [Select Id , ShippingCity From Account where Pronto_Account_Code__c = 'ABN1234' ];
        request.requestBody =  Blob.valueOf('{"name":"API Supplier Test 98","postal_name":"Test","postal_street":"Test","postal_city":"Test","postal_postal_code":"Test","postal_state":"Test","postal_country":"Australia","business_name":"name","business_street":"street","business_city":"City","business_postal_code":"2020","business_state":"NSW","business_country":"Australia","phone":"0867899334","fax":"","email":"email@email.com","abn":"","nature_of_business":"","acn":"","territory":"","contact_name":"","status":"","notes":"","timestamp":1571113639974}');
        request.requestUri  = URL.getSalesforceBaseUrl().toExternalForm()+ '/services/apexrest/Supplier/';
        request.httpMethod = 'PATCH';
        RestContext.request = request;
        SupplierAPI.updateSupplier();
        System.assert(res.statusCode == 400 , res.statusCode );  
        System.assert(brisbaneSupplier.ShippingCity == 'Sydney');
        
        //successful update of supplier record
        res.statusCode = 0; 
        Account sydneySupplier = [Select Id , ShippingCity From Account where Pronto_Account_Code__c = 'ABN1234' ];
        System.assert(sydneySupplier.ShippingCity == 'Sydney');
        request.requestBody =  Blob.valueOf('{"name":"API Supplier Test 98","postal_name":"Test","postal_street":"Test","postal_city":"Melbourne","postal_postal_code":"Test","postal_state":"Test","postal_country":"Australia","business_name":"name","business_street":"street","business_city":"City","business_postal_code":"2020","business_state":"NSW","business_country":"Australia","phone":"0867899334","fax":"","email":"email@email.com","abn":"","nature_of_business":"","acn":"","account_code":"ABN1234","territory":"","contact_name":"","status":"","notes":"","timestamp":1571113639974}');
        request.requestUri  = URL.getSalesforceBaseUrl().toExternalForm()+ '/services/apexrest/Supplier/ABN1234';
        request.httpMethod = 'PATCH';
        RestContext.request = request;
        SupplierAPI.updateSupplier();
        Account melbourneSupplier = [Select Id , ShippingCity From Account where Pronto_Account_Code__c = 'ABN1234' ];
        System.assert(res.statusCode == 200);  
        System.assert(melbourneSupplier.ShippingCity == 'Melbourne');
        
        
        //trying to update an account that does not exists
        //successful update of supplier record
        request.requestBody =  Blob.valueOf('{"name":"API Supplier Test 4","postal_name":"","postal_street":"","postal_city":"Melbourne","postal_postal_code":"","postal_state":"","postal_country":"","business_name":"","business_street":"","business_city":"","business_postal_code":"","business_state":"","business_country":"","phone":"","fax":"","email":"","abn":"","nature_of_business":"","acn":"","account_code":"ABN120348","territory":"","contact_name":"","status":"","notes":"","timestamp":1571113639974}');
        request.requestUri  = URL.getSalesforceBaseUrl().toExternalForm()+ '/services/apexrest/Supplier/ABN120348';
        request.httpMethod = 'PATCH';
        RestContext.request = request;
        SupplierAPI.updateSupplier();
        System.assert(res.statusCode == 404);  
        System.assert(melbourneSupplier.ShippingCity == 'Melbourne');
        
    }
    
    //UPDATE LIST OF SUPPLIERS
    @isTest static void testUpdateSuppliers(){
        RestRequest request = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        //create supplier 1
        request.requestBody =  Blob.valueOf('{"name":"API Supplier Test 98","postal_name":"Test","postal_street":"Test","postal_city":"Test","postal_postal_code":"Test","postal_state":"Test","postal_country":"Australia","business_name":"name","business_street":"street","business_city":"City","business_postal_code":"2020","business_state":"NSW","business_country":"Australia","phone":"0867899334","fax":"","email":"email@email.com","abn":"","nature_of_business":"","acn":"","account_code":"ABN1234","territory":"","contact_name":"","status":"","notes":"","timestamp":1571113639974}');
        request.requestUri  = URL.getSalesforceBaseUrl().toExternalForm()+ '/services/apexrest/Supplier';
        request.httpMethod = 'POST';
        RestContext.request = request;
        SupplierAPI.createSupplier();
                
        //create supplier 2
        request.requestBody =  Blob.valueOf('{"name":"API Supplier Test 99","postal_name":"Test","postal_street":"Test","postal_city":"Test","postal_postal_code":"Test","postal_state":"Test","postal_country":"Australia","business_name":"name","business_street":"street","business_city":"City","business_postal_code":"2020","business_state":"NSW","business_country":"Australia","phone":"0867899334","fax":"","email":"email@email.com","abn":"","nature_of_business":"","acn":"","account_code":"ABN12349","territory":"","contact_name":"","status":"","notes":"","timestamp":1571113639974}');
        request.requestUri  = URL.getSalesforceBaseUrl().toExternalForm()+ '/services/apexrest/Supplier';
        request.httpMethod = 'POST';
        RestContext.request = request;
        SupplierAPI.createSupplier();
        

        List<Utilities.SupplierWrapper> sw = new List<Utilities.SupplierWrapper>();
        Account firstSupplier = [Select Id , Name from Account where name = 'API Supplier Test 98'];
        Utilities.SupplierWrapper acc = new Utilities.SupplierWrapper();
        acc.Id = firstSupplier.Id;
        acc.Name = 'Paris';
        
        Account secondSupplier = [Select Id , Name from Account where name = 'API Supplier Test 99'];
        Utilities.SupplierWrapper account = new Utilities.SupplierWrapper();
        account.Id = secondSupplier.Id;
        account.Name = 'London';
        sw.add(acc);
        sw.add(account);
        String payload = Json.serialize(sw); 
        request.requestBody =  Blob.valueOf(payload);
        request.httpMethod = 'PUT';
        RestContext.request = request;
        SupplierAPI.updateSuppliers();
        secondSupplier = [Select Id , Name from Account where Id =: account.Id];
        firstSupplier = [Select Id , Name from Account where Id =: acc.Id];
        System.assert(res.statusCode == 200);  
    }
    
       
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}