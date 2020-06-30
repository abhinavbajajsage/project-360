({
	init : function(component, event, helper) {
        component.set('v.columns', [
            {label: 'Work Order Number', fieldName: 'WorkOrderNumber', type: 'text',sortable:true},
            {label: 'Subject', fieldName: 'Subject', type: 'text',sortable:true},
            {label: 'Materials Total', fieldName: 'Materials_Total__c', type: 'currency',sortable:true}, 
            {label: 'Total Billable Hours', fieldName: 'Total_Billable_Hours__c', type: 'number',sortable:true}
        ]);
        helper.getData(component);
        helper.getServiceContract(component);
	},
    updateSelectedText : function(component, event, helper){
        var selectedRows = event.getParam('selectedRows');
        //  console.log('selectedRows'+selectedRows);
        component.set("v.selectedRowsCount" ,selectedRows.length );
        let obj =[] ; 
        for (var i = 0; i < selectedRows.length; i++){
            
            obj.push(selectedRows[i].Id);
        }
        
        
        component.set("v.selectedRowsDetails" ,obj );
        component.set("v.selectedRowsList" ,event.getParam('selectedRows') );
        
    },
    // Client-side controller called by the onsort event handler
    updateColumnSorting: function (cmp, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        // assign the latest attribute with the sorted column fieldName and sorted direction
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    },
    handleSelect: function (component, event, helper) {
        var arr = component.get('v.data');
        var obj =  component.get("v.selectedRowsList");
        var selectedRowsCount = component.get("v.selectedRowsCount");
        
        if(selectedRowsCount != 0){
            //throw new Error("I can’t go on. This is the end.");
            //Calling server side controller's updateStudent() method.
            var action = component.get("c.createSalesOrder");
            //Set method parameter of updateStudent() method.
            action.setParams({"contract": component.get("v.contractRecord") , "workOrderIds": JSON.stringify(component.get("v.selectedRowsDetails"))});
            action.setCallback(this, function(response){
                //<response.getState()> return response status as SUCCESS/ERROR/INCOMPLETE etc.
                var state = response.getState();
                console.log("state="+state);
                //If response from server side is <SUCCESS>, then we will display a success message.
                if (state === "SUCCESS"){
                    //Success message display logic.
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": response.getReturnValue(),
                        "slideDevName": "detail"
                    });
                    navEvt.fire();
                    //Navigate to detail page.
                    //window.location ="/"+response.getReturnValue();
                    //location.reload();
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
            
            
        }else{
            component.find('notifLib').showNotice({
                "variant": "error",
                "header": "Error Message",
                "message": "Please select atleast one work order"
                
            });
        }
    },
})