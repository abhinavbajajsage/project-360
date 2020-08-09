public class WorkOrderDetailsPDFExtn {
    public Id serviceContractId;
    public ServiceContract serviceContractRecord = new ServiceContract();
    public WorkOrder workOrderFilter {get;set;}
    public List<WorkOrder> workOrderList = new List<WorkOrder>();
    public List<WorkOrderWrapper> workOrderWrapperList {get;set;}
    public string reportMonthYear {get;set;}
    public string[] monthArr = new string[] {'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'};
    
    public WorkOrderDetailsPDFExtn(ApexPages.StandardController sc) {
        serviceContractId = sc.getId();
        workOrderFilter = new WorkOrder();
        workOrderList = new List<WorkOrder>();
        workOrderWrapperList = new List<WorkOrderWrapper>();
        reportMonthYear = '';
        
        if(ApexPages.currentPage().getParameters().containsKey('startdate') && ApexPages.currentPage().getParameters().get('startdate') != null) {
            workOrderFilter.Filter_Start_Date__c = Date.valueOf(ApexPages.currentPage().getParameters().get('startdate'));
        }
        if(ApexPages.currentPage().getParameters().containsKey('enddate') && ApexPages.currentPage().getParameters().get('enddate') != null) {
            workOrderFilter.Filter_End_Date__c = Date.valueOf(ApexPages.currentPage().getParameters().get('enddate'));
        }
        if(serviceContractId != null) {
            serviceContractRecord = [SELECT Id, Account.Name FROM ServiceContract WHERE Id = :serviceContractId];
        }
        fetchWorkOrder();
    }
    
    public PageReference fetchWorkOrder() {
        workOrderList = new List<WorkOrder>();
        workOrderWrapperList = new List<WorkOrderWrapper>();
        
        List<String> sObjectFieldsList = new List<String>();
        sObjectFieldsList = getsObjectFields(new WorkOrder());
        if(sObjectFieldsList.size() > 0 ) {
            String query = '';
            query = 'SELECT ' + String.join(sObjectFieldsList, ',') + ', CreatedBy.Name, (SELECT Id, Service_Resource_Name__c FROM Service_Appointments__r) FROM WorkOrder WHERE ServiceContractId = :serviceContractId';
            if(workOrderFilter.Filter_Start_Date__c != null && workOrderFilter.Filter_End_Date__c != null && workOrderFilter.Filter_Start_Date__c <= workOrderFilter.Filter_End_Date__c) {
                DateTime startDate = workOrderFilter.Filter_Start_Date__c;
                DateTime endDate = workOrderFilter.Filter_End_Date__c.addDays(1);
                reportMonthYear = monthArr[startDate.month() - 1] + ' ' + startDate.year() + ' - ' + monthArr[endDate.month() - 1] + ' ' + endDate.year();
                query += ' AND CreatedDate >= :startDate AND CreatedDate <= :endDate';
                workOrderList = Database.query(query);
            } else {
                ApexPages.addMessage(new ApexPages.Message(Apexpages.Severity.ERROR, 'Please fill the correct date.'));
                return null;
            }
            
            if(workOrderList.size() > 0) {
                for(WorkOrder wo : workOrderList) {
                    Set<string> technicialNameSet = new Set<string>();
                    List<string> technicialNameList = new List<string>();
                    if(wo.Service_Appointments__r != null && wo.Service_Appointments__r.size() > 0) {
                        for(ServiceAppointment sa : wo.Service_Appointments__r) {
                            if(String.isNotBlank(sa.Service_Resource_Name__c)) {
                                technicialNameSet.add(sa.Service_Resource_Name__c);
                            }
                        }
                        if(technicialNameSet.size() > 0) {
                            technicialNameList = new List<string> (technicialNameSet);
                        }
                    }
                    if(technicialNameList.size() > 0) {
                        workOrderWrapperList.add(new WorkOrderWrapper(wo, String.join(technicialNameList, ', ')));
                    } else {
                        workOrderWrapperList.add(new WorkOrderWrapper(wo, ''));
                    }
                }
            }
        }
        return null;
    }
    
    private List<string> getsObjectFields(sObject obj) {
        Set<String> sObjectFieldsSet = new Set<String>();
        Map<String, Schema.SobjectField> fields = obj.getSObjectType().getDescribe().fields.getMap();
        for (String s : fields.keySet()) {
            if (fields.get(s).getDescribe().isAccessible()) {
                sObjectFieldsSet.add(s);
            }
        }
        sObjectFieldsSet.add('Account.Name');
        
        return new List<string> (sObjectFieldsSet);
    }
    
    public Class WorkOrderWrapper {
        public WorkOrder workOrderRecord {get;set;}
        public string technicianName {get;set;}
        public WorkOrderWrapper(WorkOrder workOrderRecord, string technicianName) {
            this.workOrderRecord = workOrderRecord;
            this.technicianName = technicianName;
        }
    }
}