@isTest
private class recallApprovalFromFlowTest {

    static testMethod void testApproval() {
        OperatingHours op = new OperatingHours (Name = 'SA');
        insert op;

        ServiceTerritory st = new ServiceTerritory( Name = 'SA', Branch_Code__c = '5', OperatingHoursId = op.id );
        insert st;   
   
        Purchase_Order__c po = new Purchase_Order__c( Service_Territory__c = st.id );
        insert po; 
        
        Purchase_Order_Line_Item__c poli = new Purchase_Order_Line_Item__c(Cost__c = 200000, Quantity__c = 2, Purchase_Order__c = po.id);
        insert poli;
        
        po.Status__c = 'Approval Pending';
        update po;

        ProcessInstanceWorkitem workItems = [ SELECT Id
                                                FROM ProcessInstanceWorkitem
                                                WHERE ProcessInstance.TargetObjectId =: po.id
                                                AND ProcessInstance.Status = 'Pending' ];
        
        List <String> workItemList = new List <String>();
        workItemList.add(workItems.id);
                                                
        recallApprovalFromFlow.get( workItemList );
        
    }

}