/*******************************************************************************
* @author          Kengo CHINEN (Proquest Consulting)
* @date            12.Nov.2019        
* @description         Transaction calculation. This class handles assignment of pricing to a work order line item based on the Work Order's Service Contract +
Split of work order line items into multiple lines depending on contract's business hours
• @revision 
• v1.0      - Rate Calculation


*******************************************************************************/

public class WorkOrderLineItemHandler {
    public static boolean recursive = false;
    
    public static void updateCreatedTransaction(List <WorkOrderLineItem> wolis, Map <Id, WorkOrderLineItem> oldMap) {
        
        //Get Contracts with business hours
        Set <Id> woIds = new Set<Id>();
        Set <Id> serviceContractId = new Set<Id>();
        Set <Id> employeeIds = new Set<Id>();
        Set <Id> serviceResourceIds = new Set<Id>();
        
        for(WorkOrderLineItem woli :wolis){ 
            
            
            if(woli.Manual_Override__c  == false 
               && woli.Billable_Hours__c <> 0
               && (woli.Resource__c <> NULL || woli.Employee__c <> NULL)
               && (oldMap == NULL || (woli.Sync_With_Pronto__c == oldMap.get(woli.id).Sync_With_Pronto__c && woli.SC_Project_Code__c  == oldMap.get(woli.id).SC_Project_Code__c  && woli.Integration_Status__c == oldMap.get(woli.id).Integration_Status__c && System.UserInfo.getName() <> 'Data.com Clean')  )){
                   if(oldMap != NULL)   {             
                       System.debug('****old.woli.Sync_With_Pronto__c:'+oldMap.get(woli.id).Sync_With_Pronto__c);
                       System.debug('****old.woli.Integration_Status__c:'+oldMap.get(woli.id).Integration_Status__c);
                   }
                   woIds.add(woli.WorkOrderId);
                   serviceResourceIds.add(woli.Resource__c);
               }
            if((woli.Manual_Override__c  == false && woli.Employee__c <> NULL  )){
                employeeIds.add(woli.Employee__c);
            }
            
            /*
            if( (oldMap != null && woli.StartDate != oldMap.get(woli.Id).StartDate && woli.EndDate != oldMap.get(woli.Id).EndDate) ||
                  (oldMap == null && woli.StartDate != null && woli.EndDate != null) ){
                      woli.Actual_Hours__c = Utilities.getActualHours(woli.StartDate, woli.EndDate);
                      if( woli.Billable_Hours_Update_Reason__c == null){
                          woli.Billable_Hours__c = woli.Actual_Hours__c;
                    }
                  }
			
            */
            
        }
        
        List <WorkOrder> wos = new List <WorkOrder>();
        Map <Id,Id> businessHoursMap = new Map <Id,Id>();
        Map <Id,Id> overtimeMap = new Map <Id,Id>();
        Map <Id,Id> nightTimeMap = new Map <Id,Id>();
        Map <Id,Id> woToPriceBook = new Map <Id, Id>();
        Map <Id,Id> woToContractRTMap = new Map <Id,Id>();
        Map <id, String> usePrePurchaseMap = new Map <Id,String>();
        Set <Id> pricebookIds = new Set <Id>();
        
        Map <Id,String> contractTypeMap = new Map <Id,String>();
        Id recTypeId = Schema.SObjectType.ServiceContract.getRecordTypeInfosByName().get(Constants.SCO_CustomerContract_RT).getRecordTypeId();
        
        if(woIds.size()>0){
            wos = WorkOrderDAO.getWorkOrdersUsingIds(woIds);
            
            for(WorkOrder wo :wos){
                
                usePrePurchaseMap.put(wo.id, wo.Use_Pre_purchased_Hours__c);
                
                if(wo.ServiceContractId <> Null ){
                    woToContractRTMap.put(wo.id,wo.ServiceContract.RecordTypeId);
                }
                
                if(wo.ServiceContract.Normal_Time__c <> NULL){
                    businessHoursMap.put(wo.id,wo.ServiceContract.Normal_Time__c);
                }
                if(wo.ServiceContract.Overtime__c <> NULL){
                    overtimeMap.put(wo.id,wo.ServiceContract.Overtime__c);
                }
                if(wo.ServiceContract.Night_Time__c <> NULL){
                    nightTimeMap.put(wo.id,wo.ServiceContract.Night_Time__c);
                }
                if(wo.ServiceContract.Pricebook2Id <> NULL){
                    woToPriceBook.put(wo.id, wo.ServiceContract.Pricebook2Id);
                    pricebookIds.add(wo.ServiceContract.Pricebook2Id);
                }
                if(wo.ServiceContract.Type__c <> NULL){
                    contractTypeMap.put(wo.id, wo.ServiceContract.Type__c);
                }
            }
        }
        
        Map <Id, String> employeeTypeMap = new Map <Id, String>();
        List <Employees__c> employees = new List <Employees__c>();
        if(employeeIds.size()>0){
            
            employees = EmployeesDAO.getEmployeesUsingIds(employeeIds);
            
            for(Employees__c e :employees){
                employeeTypeMap.put(e.id, e.Role__c);
            }
        }
        
        Map <Id, String> srTypeMap = new Map <Id, String>();
        List <ServiceResource> serviceResources = new List <ServiceResource>();
        if(serviceResourceIds.size()>0){
            
            serviceResources = [Select Id, Role__c FROM ServiceResource WHERE Id IN :serviceResourceIds];
            
            for(ServiceResource sr :serviceResources){
                srTypeMap.put(sr.id, sr.Role__c);
            }
        }
        
        List <PricebookEntry> entries = new List <PricebookEntry>();
        Map <String, Id> entryMap = new Map <String, Id>();
        Map <Id, Decimal> unitPriceMap = new Map <Id, Decimal>();  
        Map <Id, Decimal> usageMap = new Map <Id, Decimal>();  
        
        System.debug('**PricebookIds**'+pricebookIds);    
        
        if(pricebookIds.size()>0){
            System.debug('**EnterPricebookIF**'+pricebookIds);    
            entries = PricebookEntryDAO.getEntriesUsingPricebookIds(pricebookIds);
            
            for(PricebookEntry entry :entries){
                entryMap.put(entry.Contract_Type__c + entry.Resource_Type__c + entry.Service_Time__c, entry.id);
                unitPriceMap.put(entry.id, entry.unitPrice);
                usageMap.put(entry.id, entry.Usage_per_hour__c);
            }
            
            // Assess what is the Contract business hours related to the transaction  + update WOLI with Product, UnitRate, Quantity + update EndDate
            for(WorkOrderLineItem woli :wolis){
                
                Boolean woliProcessed = false;
                
                // round DateTime second to 0
                woli.StartDate = Utilities.DatetimeZeroSecond(woli.StartDate) ;
                woli.EndDate = Utilities.DatetimeZeroSecond(woli.EndDate);
                
                String entryKey;
                if(woli.Employee__c <> NULL){
                    entryKey = contractTypeMap.get(woli.WorkOrderId) + employeeTypeMap.get(woli.Employee__c);
                }
                if(woli.Employee__c == NULL){
                    entryKey = contractTypeMap.get(woli.WorkOrderId) + srTypeMap.get(woli.Resource__c);
                }
                
                Id businessHoursBH = businessHoursMap.get(woli.workorderId);
                Id overtimeHoursBH = overtimeMap.get(woli.workorderId);
                Id nightHoursBH    = nightTimeMap.get(woli.workorderId);
                
                //Transaction STARTS within Business Hours
                if(BusinessHours.isWithin(businessHoursBH, woli.StartDate )){
                    
                    Id entryId = entryMap.get(entryKey+'Business Hours');                              
                    //woli.Description = 'Business Hours Labour'; 
                    woli.Description =   entryKey.replace('Silver','').replace('Gold','').replace('Silver','').replace('Bronze','').replace('Platinum','').replace('Support', ' ') + ' - Normal Time';
                    woli.PricebookEntryId = entryId;         
                    woli.UnitPrice = unitPriceMap.get(entryId); 
                    woliProcessed = true;
                    
                    
                    //Transaction ENDS within Business Hours on the same day
                    if(BusinessHours.isWithin(businessHoursBH, woli.EndDate) 
                       && woli.StartDate.day() == woli.EndDate.day()){
                           
                           woli.quantity = woli.Billable_Hours__c;
                       }
                    
                    //Transaction DOES NOT ENDS within Business Hours
                    if(BusinessHours.isWithin(businessHoursBH, woli.EndDate) == FALSE
                       || woli.StartDate.day() <> woli.EndDate.day()){
                           
                           Decimal diffEndBusinessHours = (BusinessHours.diff(businessHoursBH, woli.StartDate, woli.EndDate));
                           
                           woli.Temp_End_Date__c = woli.EndDate;           
                           woli.EndDate = woli.StartDate+ diffEndBusinessHours/86400000;
                           woli.quantity = diffEndBusinessHours/86400000*24;
                           woli.Temp_Actual_Hours__c = woli.Actual_Hours__c - woli.quantity;
                           woli.Temp_billable_Hours__c = woli.Billable_Hours__c - woli.quantity;
                           woli.Billable_Hours__c =  woli.quantity;
                           woli.Actual_Hours__c = woli.Billable_Hours__c;
                       }
                }
                //Transaction start within Overtime Hours
                if(BusinessHours.isWithin(overtimeHoursBH, woli.StartDate) && woliProcessed == false ){
                    
                    Id entryId = entryMap.get(entryKey+'Overtime');
                    //woli.Description = 'After Hours Labour';
                    woli.Description =   entryKey.replace('Silver','').replace('Gold','').replace('Silver','').replace('Bronze','').replace('Platinum','').replace('Support', ' ') + ' - Overtime';
                    woli.PricebookEntryId = entryId; 
                    woli.UnitPrice = unitPriceMap.get(entryId); 
                    
                    //Transaction ENDS within Overtime Hours
                    if(BusinessHours.isWithin(overtimeHoursBH, woli.EndDate) 
                       && woli.StartDate.day() == woli.EndDate.day()){
                           woli.quantity = woli.Billable_Hours__c;
                       }
                    
                    //Transaction DOES NOT ENDS within Overtime Hours
                    if(BusinessHours.isWithin(overtimeHoursBH, woli.EndDate)== FALSE
                       || woli.StartDate.day() <> woli.EndDate.day()){
                           
                           Decimal diffEndBusinessHours = (BusinessHours.diff(overtimeHoursBH, woli.StartDate, woli.EndDate));
                           
                           woli.Temp_End_Date__c = woli.EndDate;           
                           woli.EndDate = woli.StartDate+ diffEndBusinessHours/86400000;
                           woli.quantity = diffEndBusinessHours/86400000*24;
                           woli.Temp_Actual_Hours__c = woli.Actual_Hours__c - woli.quantity;
                           woli.Temp_billable_Hours__c = woli.Billable_Hours__c - woli.quantity;
                           woli.Billable_Hours__c =  woli.quantity;
                           woli.Actual_Hours__c = woli.Billable_Hours__c;
                       }              
                }
                
                // Assumption Contract has Business, Overtime and Night Time 
                if(businessHoursBH <> NULL
                   && overtimeHoursBH <> NULL
                   && nightHoursBH    <> NULL){
                       
                       //Transaction start within Night Hours
                       if(BusinessHours.isWithin(nightHoursBH, woli.StartDate )){
                           
                           Id entryId = entryMap.get(entryKey +'Night Time');
                           //woli.Description = 'Night Time Labour';
                           woli.Description =   entryKey.replace('Silver','').replace('Gold','').replace('Silver','').replace('Bronze','').replace('Platinum','').replace('Support', ' ') + ' - Night Time';
                           woli.PricebookEntryId = entryId; 
                           woli.UnitPrice = unitPriceMap.get(entryId);  
                           
                           //Transaction ENDS within Night Hours
                           if(BusinessHours.isWithin(nightHoursBH, woli.EndDate) 
                              && woli.StartDate.day() == woli.EndDate.day()){
                                  
                                  woli.quantity = woli.Billable_Hours__c;
                              }
                           
                           //Transaction DOES NOT ENDS within Nightime Hours
                           if(BusinessHours.isWithin(nightHoursBH, woli.EndDate)== FALSE
                              || Woli.StartDate.day() <> woli.EndDate.day()){
                                  
                                  Decimal diffEndBusinessHours = (BusinessHours.diff(nightHoursBH, woli.StartDate, woli.EndDate));
                                  
                                  woli.Temp_End_Date__c = woli.EndDate;           
                                  woli.EndDate = woli.StartDate+ diffEndBusinessHours/86400000;
                                  woli.quantity = diffEndBusinessHours/86400000*24;
                                  woli.Temp_Actual_Hours__c = woli.Actual_Hours__c - woli.quantity;
                                  woli.Temp_billable_Hours__c = woli.Billable_Hours__c - woli.quantity;
                                  woli.Billable_Hours__c =  woli.quantity;
                                  woli.Actual_Hours__c = woli.Billable_Hours__c;
                              }
                       }
                       
                       //Transaction start within Public Holidays Hours                    
                       if(BusinessHours.isWithin(businessHoursBH, woli.StartDate) == FALSE
                          && BusinessHours.isWithin(overtimeHoursBH, woli.StartDate)== FALSE
                          && BusinessHours.isWithin(nightHoursBH, woli.StartDate)== FALSE){
                              
                              Id entryId = entryMap.get(entryKey+'Night Time');
                              //woli.Description = 'Night Time Labour';
                              woli.Description =   entryKey.replace('Silver','').replace('Gold','').replace('Silver','').replace('Bronze','').replace('Platinum','').replace('Support', ' ') + ' - Night Time';
                              woli.PricebookEntryId = entryId; 
                              woli.UnitPrice = unitPriceMap.get(entryId); 
                              
                              // Transaction ENDS within same Public Holidays hours OR during next night time (Same Rate)
                              if((BusinessHours.isWithin(businessHoursBH, woli.EndDate) == FALSE
                                  && BusinessHours.isWithin(overtimeHoursBH, woli.EndDate)== FALSE
                                  && BusinessHours.isWithin(nightHoursBH, woli.EndDate)== FALSE)
                                 || BusinessHours.isWithin(nightHoursBH, woli.EndDate)){
                                     woli.quantity = woli.Billable_Hours__c;                    
                                 }
                              
                              // Transaction DOES NOT ENDS within same Public Holidays hours
                              else{
                                  
                                  Datetime nextStartOT = BusinessHours.nextStartDate(overtimeHoursBH, woli.StartDate);
                                  Datetime nextStartBH = BusinessHours.nextStartDate(businessHoursBH, woli.StartDate);
                                  
                                  if(nextStartBH <nextStartOT){
                                      woli.Temp_End_Date__c = woli.EndDate;           
                                      woli.EndDate = nextStartBH;
                                      Decimal timeDiff = ( nextStartBH.getTime()- woli.StartDate.getTime())/1000/60/60;
                                      woli.quantity = timeDiff;
                                      woli.Temp_Actual_Hours__c = woli.Actual_Hours__c - woli.quantity;
                                      woli.Temp_billable_Hours__c = woli.Billable_Hours__c - woli.quantity;
                                      woli.Billable_Hours__c =  woli.quantity;
                                      woli.Actual_Hours__c = woli.Billable_Hours__c;
                                  }
                                  
                                  if(nextStartOT <nextStartBH){
                                      woli.Temp_End_Date__c = woli.EndDate;           
                                      woli.EndDate = nextStartOT;
                                      Decimal timeDiff = ( nextStartOT.getTime()- woli.StartDate.getTime())/1000/60/60;
                                      woli.quantity = timeDiff;
                                      woli.Temp_Actual_Hours__c = woli.Actual_Hours__c - woli.quantity;
                                      woli.Temp_billable_Hours__c = woli.Billable_Hours__c - woli.quantity;
                                      woli.Billable_Hours__c =  woli.quantity;
                                      woli.Actual_Hours__c = woli.Billable_Hours__c;
                                  }
                              }              
                          }  
                   }
                // Assumption Contract has ONLY Business Hours AND Overtime 
                if(businessHoursBH <> NULL
                   && overtimeHoursBH <> NULL
                   && nightHoursBH    == NULL){     
                       
                       //Transaction start within Overtime Hours
                       if(BusinessHours.isWithin(businessHoursBH, woli.StartDate )== FALSE){
                           
                           Id entryId = entryMap.get(entryKey+'Overtime');
                           // woli.Description = 'After Hours Labour';
                           woli.Description =   entryKey.replace('Silver','').replace('Gold','').replace('Silver','').replace('Bronze','').replace('Platinum','').replace('Support', ' ') + ' - Overtime';
                           woli.PricebookEntryId = entryId; 
                           woli.UnitPrice = unitPriceMap.get(entryId); 
                           
                           
                           //Transaction ENDS within Overtime Hours
                           if(woli.EndDate < BusinessHours.nextStartDate(businessHoursBH, woli.StartDate) ){
                               woli.quantity = woli.Billable_Hours__c;
                           }
                           
                           //Transaction DOES NOT ENDS within Overtime Hours
                           if(woli.EndDate > BusinessHours.nextStartDate(businessHoursBH, woli.StartDate)){
                               
                               woli.Temp_End_Date__c = woli.EndDate;           
                               woli.EndDate = BusinessHours.nextStartDate(businessHoursBH, woli.StartDate);
                               
                               Decimal diffEndBusinessHours = (BusinessHours.diff(overtimeHoursBH, woli.StartDate, woli.EndDate));
                               Decimal quantity = diffEndBusinessHours/86400000*24;                              
                               woli.quantity = quantity;
                               woli.Temp_Actual_Hours__c = woli.Actual_Hours__c - woli.quantity;
                               woli.Temp_billable_Hours__c = woli.Billable_Hours__c - woli.quantity;
                               woli.Billable_Hours__c =  woli.quantity;
                               woli.Actual_Hours__c = woli.Billable_Hours__c;
                           }              
                       }
                   }    
                // Update woli subject for FSL mobile app to see the summary on the Work Order Overview page. 
                woli.Subject = woli.Resource_Formula__c + ' '+ woli.StartDate.format()+ ' '+ woli.EndDate.format();
                
                // Check if WO is using pre purchased hours, Update price and pre purchased hours charged
                if(usePrePurchaseMap.get(woli.WorkOrderId) == 'Yes'){
                    woli.UnitPrice = 0;
                    woli.Consumed_Pre_Purchased_Hours__c = usageMap.get(woli.PricebookEntryId)*woli.quantity;
                }
                
            }    
        }
        for(WorkOrderLineItem woli :wolis){
            if(woli.Billable_Hours__c == 0){
                woli.Do_not_show_in_Service_Report__c = true;
                woli.Subject = woli.Resource_Formula__c + ' '+ woli.StartDate.format()+ ' '+ woli.EndDate.format();
            }
            
        } 
        
    }
    
    
    //************************************************************************************************
    
    public static void createSplittedTransaction(List <WorkOrderLineItem> wolis, Map <Id, WorkOrderLineItem> oldMap) {
        
        system.debug('**aftertrigger**');
        List <WorkOrderLineItem> transactionToInsert = new List<WorkOrderLineItem>(); 
        Set<Id> woliIdWithSONotIntegrated   = new Set<Id>();
        Set <Id> workOrdersId = new Set <Id>();
        
        for(WorkOrderLineItem woli :wolis){    
            if(woli.Quantity >0 && woli.Sales_Order_Integration_Status__c <> NULL && (woli.Sales_Order_Integration_Status__c == Utilities.INTEGRATION_PENDING || woli.Sales_Order_Integration_Status__c == Utilities.INTEGRATION_FAILED)){
                woliIdWithSONotIntegrated.Add(woli.id);
                workOrdersId.add(woli.WorkOrderId);
                System.debug('**SalesOrder Not integrated Yet**');
            }
            System.debug('****woli.Manual_Override__c:'+woli.Manual_Override__c);
            System.debug('****woli.Temp_billable_Hours__c:'+woli.Temp_billable_Hours__c);
            System.debug('****woli.Sync_With_Pronto__c:'+woli.Sync_With_Pronto__c);    
            System.debug('****woli.Integration_Status__c:'+woli.Integration_Status__c); 
            if(oldMap <> NULL){
                System.debug('****woli.oldMap.get(woli.id)SynchPronto:'+oldMap.get(woli.id).Sync_With_Pronto__c);    
                System.debug('****OldMap.Integration_Status__c:'+oldMap.get(woli.id).Integration_Status__c ); 
            }
            System.debug('****System.UserInfo.getName():'+System.UserInfo.getName()); 
            
            if( woli.Manual_Override__c  == false
               && woli.Temp_billable_Hours__c > 0 
               && (oldMap == NULL || (//woli.Sync_With_Pronto__c == oldMap.get(woli.id).Sync_With_Pronto__c 
                   //&& woli.Integration_Status__c == oldMap.get(woli.id).Integration_Status__c 
                   woli.Temp_billable_Hours__c <> oldMap.get(woli.id).Temp_billable_Hours__c 
                   && woli.SC_Project_Code__c == oldMap.get(woli.id).SC_Project_Code__c
                   && System.UserInfo.getName() <> 'Data.com Clean'
                   && (woli.UnitPrice == oldMap.get(woli.id).UnitPrice && woli.UnitPrice <> 0)))
              ){
                  
                  
                  WorkOrderLineItem woli2 = createwoli(woli);
                  woli2.StartDate = woli.EndDate ; 
                  woli2.EndDate = woli.Temp_End_Date__c ;
                  woli2.Billable_Hours__c = woli.Temp_billable_Hours__c;
                  woli2.Actual_Hours__c = woli.Temp_Actual_Hours__c;
                  woli2.Subject = woli.Resource_Formula__c + ' '+ woli.EndDate.format();
                  woli2.Service_Contract__c = woli.Service_Contract__c;
                  transactionToInsert.add(woli2);
              }
        }
        
        system.debug('**aftertrigger Size**'+ transactionToInsert.size());   
        if(transactionToInsert.size()>0){
            insert transactionToInsert;
        }   
        // logic to create a sales order line item
        if(woliIdWithSONotIntegrated.size()>0){
            List <Sales_Order_Line_Item__c> soliToCreate = new List <Sales_Order_Line_Item__c>();
            Map <Id, Id> SoliExistCheckMap = new Map<Id, Id>(); 
            List <Sales_Order_Line_Item__c> solis = SalesOrderLineItemDAO.getSOLinesForWOLI(woliIdWithSONotIntegrated);
            if(solis.size()>0){
                System.debug('**soli list is not null**');
                for(Sales_Order_Line_Item__c soli :solis){
                    SoliExistCheckMap.put(soli.Work_Order_Line_Item__c, soli.id);
                }
            }
            List <WorkOrder> wos = WorkOrderDAO.getWorkOrdersUsingIds(workOrdersId);
            Map <Id,Id> woToSo = new Map <Id,Id>();
            if(wos.size()>0){
                for(WorkOrder wo :wos){
                    woToSo.put(wo.Id, wo.Sales_Order__c);
                }
            }
            
            for(WorkOrderLineItem woli : wolis){
                if(woli.Quantity >0 && woli.Sales_Order_Integration_Status__c <> NULL &&(woli.Sales_Order_Integration_Status__c == Utilities.INTEGRATION_PENDING || woli.Sales_Order_Integration_Status__c == Utilities.INTEGRATION_FAILED)){
                    if(SoliExistCheckMap.get(woli.id) == NULL){
                        system.debug('**soli creation loop**');
                        Sales_Order_Line_Item__c newSOLI = new Sales_Order_Line_Item__c( Work_Order_Line_Item__c = woli.id,
                                                                                        Sales_Order__c = woToSo.get(woli.WorkOrderId),
                                                                                        Description__c = woli.Description,
                                                                                        Item_Price__c = woli.UnitPrice,
                                                                                        Order_Quantity__c = woli.Quantity,
                                                                                        Tax_Rate__c = 10,
                                                                                        Units__c = 'HRS',
                                                                                        Item_Code__c = 'Special (S)',
                                                                                        Purchase_Order__c = woli.Purchase_Order__c);
                        soliToCreate.add(newSOLI);
                        
                    }
                    
                }
            }
            if(soliToCreate.size()>0){
                insert soliToCreate;
            }
        }
    }
    
    public static WorkOrderLineItem createWoli(WorkOrderLineItem woli) {
        
        WorkOrderLineItem newWOLI = new WorkOrderLineItem( 
            WorkOrderId = woli.WorkOrderId,
            Resource__c = woli.Resource__c,
            Employee__c = woli.Employee__c,
            Purchase_Order__c = woli.Purchase_Order__c,
            Service_Appointment__c = woli.Service_Appointment__c
        );
        
        return newWOLI;
    }
    
        /**
		* Undelete Timesheet and Sync with Pronto if applicable 
		*/
    public static void unDeleteWorkOrderLineItem(List<WorkOrderLineItem> newWOLIs){
        
        	List<WorkOrderLineItem> lw = [select id from WorkOrderLineItem where id in: newWOLIs];
                
                for(WorkOrderLineItem w : lw)
                {
                    w.Send_Timesheet__c = false;
                    w.Sync_With_Pronto__c = true;
                }
                update lw;
            }
    
    
    	 /**
		* Check and process WOLI delete if allowed 
		*/
    public static void processWOLIDelete(List<WorkOrderLineItem> oldWOLIs,  Map<Id , WorkOrderLineItem> oldWoliMap){
        
        	for(WorkOrderLineItem woli: oldWOLIs)
                {
                    if(woli.StartDate != null)
                    {
                        if(Utilities.isOutsidePayrollCutoffTime(woli.StartDate, Datetime.now()))
                        {
                            woli.StartDate.addError(System.Label.WorkOrderLineItem_PayrollCutOffTime_CL);
                            system.debug('Trying to delete WOLI with' + woli.Id );
                        }
                        else 
                        {
                            if((woli.Integration_Status__c == Utilities.INTEGRATION_SUCCESSFUL || woli.Integration_Status__c == Utilities.INTEGRATION_PAYROLL_VALIDATED))
                            {
                                
                                Id profileId=userinfo.getProfileId();
                                String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
                                List<WorkOrder> salesorderIDs = [Select Sales_Order__c FROM WorkOrder where ID in (Select WorkOrderId from workorderlineitem where id=:woli.Id) ];
                                if(salesorderIDs.get(0).Sales_Order__c!=null && profileName=='Technician')
                                {
                                    woli.addError('WorkOrderLineItem_Delete_NotAllowed_SOGenerated_CL');
                                }
                                else 
                                {
                                    List<WorkOrderLineItem> lw = [select id from WorkOrderLineItem where id in: oldWoliMap.keyset()];
                                    for(WorkOrderLineItem w : lw)
                                    {
                                        w.Integration_Status__c = '';
                                    }
                                    update lw;
                                    SynchWithPronto.makeHTTPCallout(woli.Id); 
                                }
                            }
                            else
                            {
                                woli.addError(System.Label.WorkOrderLineItem_Delete_NotAllowed_CL);
                            }
                            
                        }  
                    }
                }
            }
    /**
* Check if transaction startDate was set or updated
	*/
    public static void validateStartDate(List<WorkOrderLineItem> newWOLIs , Map<Id , WorkOrderLineItem> oldWoliMap){
        List<WorkOrderLineItem> wolisToUpdate = new List<WorkOrderLineItem>();
        Map<Id,Id> woliSoli = new Map<Id,Id>();
        
        if(oldWoliMap != null){
            List<Sales_Order_Line_Item__c> solItems = SalesOrderLineItemDAO.getSalesOrdersLinesForWOLI(oldWoliMap.keySet());
            
            for(Sales_Order_Line_Item__c soli : solItems){
                woliSoli.put(soli.Work_Order_Line_Item__c, soli.Id);
            }
        }
        
        for(WorkOrderLineItem woli : newWOLIs){
            System.debug('**StartLoop Integration Status**'+woli.Integration_Status__c);
            System.debug('**StartLoop Synch With Pronto**'+woli.Sync_With_Pronto__c);
            if(woli.StartDate != null ){
                if( !Test.isRunningTest() &&
                   ((Trigger.isInsert && Utilities.isOutsidePayrollCutoffTime(woli.StartDate, Datetime.now()) && !woli.Manual_Override__c) ||
                    (Trigger.isUpdate && (woli.StartDate != oldWoliMap.get(woli.Id).StartDate || woli.EndDate != oldWoliMap.get(woli.Id).EndDate) && Utilities.isOutsidePayrollCutoffTime(woli.StartDate, Datetime.now()) && !woli.Manual_Override__c))){
                        woli.StartDate.addError(System.Label.WorkOrderLineItem_PayrollCutOffTime_CL);
                    }
                if(Trigger.isUpdate && woli.StartDate != oldWoliMap.get(woli.Id).StartDate && woliSoli.containsKey(woli.Id) ){
                    woli.StartDate.addError(System.Label.WorkOrderLineItem_StartDate_Update_NotAllowed_CL);
                }
            }
            if(woli.StartDate != null && woli.Purchase_Order__c == null){ 
                //manually triggered
                if(Trigger.isUpdate){
                    
                    WorkOrderLineItem oldWoli = (WorkOrderLineItem) oldWoliMap.get(woli.Id);
                    if((woli.Sync_With_Pronto__c == true && woli.Sync_With_Pronto__c != oldWoli.Sync_With_Pronto__c ) || (oldWoli.StartDate != woli.StartDate ) || (oldWoli.EndDate != woli.EndDate) || (oldWoli.Normal_Time__c != woli.Normal_Time__c ) || (oldWoli.Overtime__c != woli.Overtime__c) || (oldWoli.Double_Time__c != woli.Double_Time__c ) || (oldWoli.Public_Holiday__c != woli.Public_Holiday__c) ){     
                        woli.Integration_Status__c = Utilities.INTEGRATION_PENDING;
                        woli.Sync_With_Pronto__c = true;
                        if(woli.SA_Completed__c){
                            woli.Send_Timesheet__c = false;
                        }
                        continue;
                    }else{
                        woli.Sync_With_Pronto__c = false;
                    }
                    
                }else{
                    woli.Sync_With_Pronto__c = true;
                    woli.Integration_Status__c = Utilities.INTEGRATION_PENDING;
                }
            }else{
                woli.Sync_With_Pronto__c = false;
                woli.Integration_Status__c = Utilities.INTEGRATION_DENIED;
            }
            System.debug('**EndLoop Integration Status**'+woli.Integration_Status__c);
            System.debug('**EndLoop Synch With Pronto**'+woli.Sync_With_Pronto__c);        
        }
    }
    
    
    /**
* Check if transaction should be validated
*/
    public static void syncWithPronto(Map<Id,WorkOrderLineItem> woliMap, Map<Id,WorkOrderLineItem> oldMap, Boolean validatePayrollPeriod){
        List<WorkOrderLineItem> wolis = new List<WorkOrderLineItem>();
        for(WorkOrderLineItem woli : woliMap.values()){
            System.debug('****woli.Id:'+woli.Id);
            System.debug('****woli.Sync_With_Pronto__c:'+woli.Sync_With_Pronto__c);
            System.debug('****woli.SA_Completed__c:'+woli.SA_Completed__c);
            System.debug('****woli.Send_Timesheet__c:'+woli.Send_Timesheet__c);
            
            if(oldMap != null){
                System.debug('****old.Sync_With_Pronto__c:'+oldMap.get(woli.Id).Sync_With_Pronto__c);
                System.debug('****old.Send_Timesheet__c:'+oldMap.get(woli.Id).Send_Timesheet__c);
            }
            if(woli.Sync_With_Pronto__c && woli.Purchase_Order__c == null){
                Utilities.woliUpdateAllowed = true;
                if(Limits.getQueueableJobs() == Limits.getLimitQueueableJobs()) continue;
                SynchWithPronto validateJob = new SynchWithPronto(woli , 'WorkOrderLineItem', woli.SA_Completed__c ? false :validatePayrollPeriod);
                ID valjobID = System.enqueueJob(validateJob);
                WorkOrderLineItem woliClone = new WorkOrderLineItem(Id = woli.Id);
                woliClone.Sync_With_Pronto__c = false;
                wolis.add(woliClone);
            }
            if(woli.Send_Timesheet__c && woli.Purchase_Order__c == null && oldMap != null && woli.Send_Timesheet__c != oldMap.get(woli.Id).Send_Timesheet__c){
                Utilities.woliUpdateAllowed = true;
                if(Limits.getQueueableJobs() == Limits.getLimitQueueableJobs()) continue;
                SynchWithPronto syncjob = new SynchWithPronto(woli , 'WorkOrderLineItem', null);
                ID jobID = System.enqueueJob(syncjob);
                
                WorkOrderLineItem woliClone = new WorkOrderLineItem(Id = woli.Id);
                woliClone.Sync_With_Pronto__c = false;
                wolis.add(woliClone);
            }
        }
        
        if(wolis.size() > 0) 
            update wolis;
    }
    
    public static void lockWorkOrderLineItem(List<WorkOrderLineItem> wolis, Map<Id,WorkOrderLineItem> oldMap){
        Map<Id,Id> woliSoli = new Map<Id,Id>();
        
        if(oldMap != null){
            List<Sales_Order_Line_Item__c> solItems = SalesOrderLineItemDAO.getSalesOrdersLinesForWOLI(oldMap.keySet());
            
            for(Sales_Order_Line_Item__c soli : solItems){
                woliSoli.put(soli.Work_Order_Line_Item__c, soli.Id);
            }
        }
        
        //allowing edit transaction when ProntoTotalCostAmount__c / ProntoTotalCostHours__c are updated even when WOLI is integrated 
        for(WorkOrderLineItem woli : wolis){
            if(!Utilities.woliUpdateAllowed && !woli.Manual_Override__c && woli.SA_Completed__c && !woli.Sync_With_Pronto__c  && woli.Purchase_Order__c == null && woliSoli.containsKey(woli.Id)){
                if(oldMap != null && oldMap.get(woli.Id).Integration_Status__c == woli.Integration_Status__c
                    && oldMap.get(woli.Id).ProntoTotalCostAmount__c == woli.ProntoTotalCostAmount__c && oldMap.get(woli.Id).ProntoTotalCostHours__c == woli.ProntoTotalCostHours__c)
                    woli.addError(System.Label.WorkOrderLineItem_Locked_CL);
            }
            
            //allowing edit transaction when breakdown of hours is provided 
            
            if(woli.Sync_With_Pronto__c == true && oldMap.get(woli.Id).Sync_With_Pronto__c == false && woli.Integration_Status__c == Utilities.INTEGRATION_SUCCESSFUL 
               && oldMap.get(woli.Id).Overtime__c == woli.Overtime__c && oldMap.get(woli.Id).Double_Time__c == woli.Double_Time__c 
               && oldMap.get(woli.Id).Public_Holiday__c == woli.Public_Holiday__c && oldMap.get(woli.Id).Normal_Time__c == woli.Normal_Time__c ){
                   woli.addError(System.Label.Record_Locked_CL);
               } 
            
             //if(woli.Sync_With_Pronto__c == true && oldMap.get(woli.Id).Sync_With_Pronto__c == false && woli.Integration_Status__c == Utilities.INTEGRATION_SUCCESSFUL){
                //woli.addError(System.Label.Record_Locked_CL);
            }
        
    }
     
    
    
    public static void updateSOLI(List<WorkOrderLineItem> wolis, Map<Id,WorkOrderLineItem> oldMap){
        
        Set<Id> woliIds = new Set<Id>();
        Map<Id,Decimal> quantityMap = new Map<Id,Decimal>();
        Map<Id,Decimal> priceMap = new Map<Id,Decimal>();
        
        for(WorkOrderLineItem woli :wolis){
            if(oldMap != null && 
               (woli.StartDate <> oldMap.get(woli.Id).StartDate 
                || woli.StartDate <> oldMap.get(woli.Id).StartDate
                || woli.Quantity <> oldMap.get(woli.Id).Quantity
                || woli.UnitPrice <> oldMap.get(woli.Id).UnitPrice)){
                    quantityMap.put(woli.id, woli.Quantity);
                    priceMap.put(woli.id, woli.UnitPrice);
                    woliIds.add(woli.id);
                }
        }
        if(woliIds.size()>0){    
            List<Sales_Order_Line_Item__c> soliList = [Select id, Update_Count__c, Sales_Order__r.Integration_Status__c, Work_Order_Line_Item__c FROM Sales_Order_Line_Item__c WHERE Work_Order_Line_Item__c IN :woliIds];
            List<Sales_Order_Line_Item__c> soliToUpdate = new List<Sales_Order_Line_Item__c>();
            
            if(soliList.size()>0){
                for(Sales_Order_Line_Item__c soli :soliList){
                    if(soli.Sales_Order__r.Integration_Status__c == Constants.INTEGRATION_STATUS_PENDING || soli.Sales_Order__r.Integration_Status__c == Constants.INTEGRATION_STATUS_FAILED){
                        soli.Item_Price__c = priceMap.get(soli.Work_Order_Line_Item__c);
                        soli.Order_Quantity__c = quantityMap.get(soli.Work_Order_Line_Item__c);
                        
                        if(soli.Update_Count__c == NULL){
                            soli.Update_Count__c = 1;
                        }else{
                            soli.Update_Count__c = soli.Update_Count__c+1;
                        }
                        
                        soliToUpdate.add(soli);
                    }
                }
            }
            
            if(soliToUpdate.size()>0){
                update soliToUpdate;
            }
        }
    }
}