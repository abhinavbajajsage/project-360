public class ServiceAppointmentTriggerHandler {

    public static void  saValidationforCompleteWO (List<ServiceAppointment> newServiceAppointments , Map<Id , ServiceAppointment> oldServiceAppointmentsMap){
        Set<Id> workOrderIds = new Set<Id>();
        for(ServiceAppointment sa: newServiceAppointments){
            ServiceAppointment oldSa = (ServiceAppointment) oldServiceAppointmentsMap.get(sa.Id);
            if(sa.Work_Order_Completed__c == 'Yes' && sa.Status != oldSa.Status && (sa.Status == Constants.SERVICE_APPOINMENT_STATUS_COMPLETE || sa.Status == Constants.SERVICE_APPOINMENT_STATUS_CANNOT_COMPLETE)){
                workOrderIds.add(sa.Work_Order__c);
            }    
        }

        if(workOrderIds.size() > 0){
            
            Map <Id, String> woToSANumberMap = new Map <Id, String>();
            
            List<ServiceAppointment> openSAs = ServiceAppointmentDAO.getOpenServiceAppointments(workOrderIds);            
            for(ServiceAppointment sa :openSAs){
                for(ServiceAppointment satrigger :newServiceAppointments){
                    if(satrigger.AppointmentNumber <> sa.AppointmentNumber){
                        woToSANumberMap.put(sa.ParentRecordId, sa.AppointmentNumber);
                    }
                }
            }
            
            for(ServiceAppointment sa: newServiceAppointments){
                if(woToSANumberMap.get(sa.ParentRecordId)<>NULL){
                    sa.addError('You cannot Complete the work order as other Service Appointments are still opened: ' +woToSANumberMap.get(sa.ParentRecordId));
                }
            }
        }
    }
    
    public static void  saValidationForOpenPOs (List<ServiceAppointment> newServiceAppointments , Map<Id , ServiceAppointment> oldServiceAppointmentsMap){
        Set<Id> workOrderIds = new Set<Id>();
        for(ServiceAppointment sa: newServiceAppointments){
            ServiceAppointment oldSa = (ServiceAppointment) oldServiceAppointmentsMap.get(sa.Id);
            if(sa.Work_Order_Completed__c == 'Yes' && sa.Status != oldSa.Status && (sa.Status == Constants.SERVICE_APPOINMENT_STATUS_COMPLETE || sa.Status == Constants.SERVICE_APPOINMENT_STATUS_CANNOT_COMPLETE)){
                workOrderIds.add(sa.Work_Order__c);
            }    
        }

        if(workOrderIds.size() > 0){
            
            Map <Id, String> woToPONumberMap = new Map <Id, String>();
            
            List<Purchase_Order__c> openPOs = PurchaseOrderDAO.getOpenPOs(workOrderIds);    
            if(openPOs.size()>0){        
                for(Purchase_Order__c po :openPOs){
                    for(ServiceAppointment satrigger :newServiceAppointments){
                        if(satrigger.ParentRecordId == po.Work_Order__c){
                            woToPONumberMap.put(satrigger.ParentRecordId, po.Name);
                        }
                    }
                }
            
            }
            
            for(ServiceAppointment sa: newServiceAppointments){
                if(woToPONumberMap.get(sa.ParentRecordId)<>NULL){
                    sa.addError('You cannot Complete the work order as some Purchase Orders are still opened: ' +woToPONumberMap.get(sa.ParentRecordId));
                }
            }
        }
    }
    
    //reset Actual Start Time seconds to 0 
    public static void  updateActualStartTime(List<ServiceAppointment> newServiceAppointments){
        
        for(ServiceAppointment sa:newServiceAppointments)
            { 
                if(sa.ActualStartTime!=null)
                {
                  sa.ActualStartTime = Utilities.DatetimeZeroSecond(sa.ActualStartTime);
                }
            }
        }

    //check if SA should be synced and if any exist then send the timesheet to Pronto
    public static void  syncWithProntoForCompletion(List<ServiceAppointment> newServiceAppointments , Map<Id , ServiceAppointment> oldServiceAppointmentsMap){
        Set<Id> workOrderIds = new Set<Id>();
        for(ServiceAppointment sa: newServiceAppointments){
            ServiceAppointment oldSa = (ServiceAppointment) oldServiceAppointmentsMap.get(sa.Id);
            if(sa.Status != oldSa.Status && (sa.Status == Constants.SERVICE_APPOINMENT_STATUS_COMPLETE || sa.Status == Constants.SERVICE_APPOINMENT_STATUS_CANNOT_COMPLETE)){
                workOrderIds.add(sa.Work_Order__c);
            }    
        }

        if(workOrderIds.size() > 0){
            Map<Id,WorkOrderLineItem> workOrderLineItems = WorkOrderLineItemDAO.getWorkOrderLineItemsUsingWoIds(workOrderIds);
            
            // Boolean checkValidTransactionExist = false;
            // //Check atleast one transaction exist withing the current payroll period
            // for(WorkOrderLineItem woli :workOrderLineItems.values()){
            //     if(woli.Within_Current_Payroll_Period__c && woli.Integration_Status__c != Utilities.INTEGRATION_WAITING && woli.Integration_Status__c != Utilities.INTEGRATION_SUCCESSFUL){
            //         checkValidTransactionExist = true;
            //     }
            // }
            // if(checkValidTransactionExist){
            Map<Id,WorkOrderLineItem> itemsToSend = new Map<Id,WorkOrderLineItem>();
            
            for(WorkOrderLineItem woli :workOrderLineItems.values()){
                if( woli.Integration_Status__c != Utilities.INTEGRATION_WAITING && woli.Integration_Status__c != Utilities.INTEGRATION_SUCCESSFUL){
                    woli.Sync_With_Pronto__c = true;
                    system.debug('wwww'+woli.Id);
                    system.debug('wwww222'+woli);
                    itemsToSend.put(woli.Id,woli);
                    
                }
             }
            //Send the transaction to Pronto
             	WorkOrderLineItemHandler.syncWithPronto(itemsToSend, null, false);
                system.debug('send'+itemsToSend);
            }
        }
    

}