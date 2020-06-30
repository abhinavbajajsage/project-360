({
    /**
     * @name:    doInit      
     * @date:        17 DEC 2017
     * @description: This method is handler method of UpdateStudent component and hence it will be
     *      call on the time of component initial load.
     *      This method is responsible to fetch the existing record.
     **/
    doInit : function(component, event, helper) {
        helper.getServiceContract(component);
        helper.getAggregateFormats(component);        
        helper.getServiceContractBillingFormat(component);         
    },
    
    /**
     * @name:    doCancel      
     * @date:        17 DEC 2017
     * @description: This method is responsible to cancel or close the modal window.
     **/
    doCancel : function(component, event, helper) {
        var cmpTargetForEdit = component.find('modalIdForEditStudent');
        var cmpBackDropForEdit = component.find('backdropIdForEditStudent');
        $A.util.removeClass(cmpBackDropForEdit,'slds-backdrop--open');
        $A.util.removeClass(cmpTargetForEdit, 'slds-fade-in-open');
    },
    
    /**
     * @name:    doSave      
     * @date:        17 DEC 2017
     * @description: This method is responsible to save student record.
     **/
    saveRecord : function(component, event, helper) {
  /** Server side controller calling logic. **/
        
        //Calling server side controller's updateStudent() method.
        var action = component.get("c.saveServiceContract");
        //Set method parameter of updateStudent() method.
        action.setParams({"contract": component.get("v.contractRecord") , "billingFormat": JSON.stringify(component.get("v.labelOptions"))});
        
        action.setCallback(this, function(response){
            //<response.getState()> return response status as SUCCESS/ERROR/INCOMPLETE etc.
            var state = response.getState();
            console.log("state="+state)
            //If response from server side is <SUCCESS>, then we will display a success message.
            if (state === "SUCCESS"){
                //Success message display logic.
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Service Contract has been updated successfully."
                });
                toastEvent.fire();
                
                //Navigate to detail page.
                window.location ="/"+component.get("v.recordId");
                location.reload();
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
    nextTab : function(component, event, helper) {
        component.set("v.setMessage", '');           
        var showListBox = component.get("v.showListBox");
        var defaultOptions = component.get("v.defaultOptions");
        var labelOptions = component.get("v.labelOptions");
        var opties = defaultOptions.toString().split(",");
        var options = [];
        
        opties.forEach(function(result)  { 
            var labelR = '';
            labelOptions.forEach(function(lblResult)  { 
                if(lblResult.value == result){
                   labelR = lblResult.label;
                }
            });
            options.push({ value: result, label: labelR});
        });

        if(showListBox == true){
            component.set("v.labelOptions", options);
            component.set("v.showListBox",false);
            component.set("v.showTable", true);
        } 
    },
    prevTab : function(component, event, helper) {
        component.set("v.setMessage", '');           
        var showTable = component.get("v.showTable");
        if(showTable == true){
            component.set("v.showListBox",true);
            component.set("v.showTable", false);
        } 
    }
})