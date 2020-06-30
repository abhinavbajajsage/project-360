/**
* 
@author: Cyrille Jeufo - Proquest Consulting
@initial version: 18/11/2019 - Initial version - This a mock class to return fake callout responses to test methods
* 
*/
@isTest
global class CustomerHttpCalloutMock implements HttpCalloutMock {
    
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest request) {
        System.debug('CustomerHttpCalloutMock sent: ' );
        HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
        if(request.getEndpoint().endsWith('api/customer/')){
            response.setBody('');
            response.setStatusCode(200);
        }else if(request.getMethod() == 'GET'){
            response.setBody('{ "code": 200, "status": "success", "message": "null", "data": { "valid": true } }');
            response.setStatusCode(200);
            System.debug('response sent: ' +response );
        }
        return response; 
    }
}