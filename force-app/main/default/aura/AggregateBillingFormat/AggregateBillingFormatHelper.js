({
	getServiceContract : function(component ) {
		//Calling server side controller's fetchStudentDetails() method.
        var action = component.get("c.getServiceContract");
        //Set method parameter of updateStudent() method, where "v.recordId" returns object record id of current screen.
        action.setParams({"contractId": component.get("v.recordId")});
        
        action.setCallback(this, function(response){
            //<response.getState()> return response status as SUCCESS/ERROR/INCOMPLETE etc.
            var state = response.getState();
            console.log("state="+state)
            //If response from server side is <SUCCESS>, then we will set the component attribute "studentObj".
            if (state === "SUCCESS"){
                var responseStudentRecord = response.getReturnValue();
                component.set("v.contractRecord", responseStudentRecord);
            }else if (state === "INCOMPLETE") {
                //Offline message display logic.
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "OFFLINE!",
                    "message": "You are in offline."
                });
                toastEvent.fire();
            }else if (state === "ERROR") {
                //Error message display logic.
                var errors = response.getError();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "ERROR!",
                    "message": errors[0].message
                });
                toastEvent.fire();
            }else {
                //Unknown message display logic.
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "UNKOWN!",
                    "message": "Unknown error."
                });
                toastEvent.fire();
            }
        });
        
        $A.enqueueAction(action);
	},
    getAggregateFormats: function(component) { 
        var options = [];
        var action = component.get("c.getBillingFormats");
        component.set("v.listOptions", options);
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state == 'SUCCESS') {   
                var resultArray = response.getReturnValue();
                var options = [];
                resultArray.forEach(function(result)  { 
                    options.push({ value: result, label: result});
                });
                component.set("v.listOptions", options);
            } else {
                console.log('Failed with state: ' + state);
            }
        });
        $A.enqueueAction(action); 
    },
    getServiceContractBillingFormat: function(component) { 
        var options = [];
        var action = component.get("c.getServiceContractBillingFormat");
        action.setParams({"contractId": component.get("v.recordId")});
        component.set("v.defaultOptions", options);
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state == 'SUCCESS') {   
                var resultArray = response.getReturnValue();
                var options = [];
                var defoptions = [];                
                resultArray.forEach(function(result)  { 
                    defoptions.push(result.value);
                    options.push({ value: result.value, label: result.label});
                });
                component.set("v.defaultOptions", defoptions);
                component.set("v.labelOptions", options);
            } else {
                console.log('Failed with state: ' + state);
            }
        });
        $A.enqueueAction(action); 
    }
     
})