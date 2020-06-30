({
	getData : function(component) {
        
        var action = component.get("c.getWorkOrderForContractWithStatus");
        action.setParams({
            "contractId": component.get("v.recordId"),
            "workOrderStatus": "Ready To Invoice"
        });
        action.setCallback(this, function(a) {
            component.set("v.data", a.getReturnValue());
        });
        $A.enqueueAction(action);
    },
    getServiceContract : function(component ) {
		//Calling server side controller's fetchStudentDetails() method.
        var action = component.get("c.getServiceContract");
        //Set method parameter of updateStudent() method, where "v.recordId" returns object record id of current screen.
        action.setParams({"contractId": component.get("v.recordId")});
        
        action.setCallback(this, function(response){
            //<response.getState()> return response status as SUCCESS/ERROR/INCOMPLETE etc.
            var state = response.getState();
            console.log("state="+state)
            console.log("response="+response);
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
    sortData: function (cmp, fieldName, sortDirection) {
        var data = cmp.get("v.data");
        var reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, reverse))
        cmp.set("v.data", data);
    },
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
        function(x) {return x[field]};
        //checks if the two rows should switch places
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },
})