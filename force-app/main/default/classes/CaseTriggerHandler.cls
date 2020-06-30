public class CaseTriggerHandler {
    public static void populateOutsideBusinessHours(List<Case> cases) {
        Set<Id> serviceContractIds = new Set<Id>();
        for(Case currentCase : cases){
            serviceContractIds.add(currentCase.Service_Contract__c);
        }
        if(!serviceContractIds.isEmpty()){
            Map<Id,ServiceContract> serviceContracts = new Map<Id,ServiceContract>(ServiceContractDAO.getContractByContractIds(serviceContractIds));
            Datetime createdDate = Test.isRunningTest() ? Datetime.newInstance(2020, 04, 14, 4, 30, 0) : System.now();
            for(Case currentCase : cases){
                if(serviceContracts.containsKey(currentCase.Service_Contract__c) && serviceContracts.get(currentCase.Service_Contract__c).Service_Territory__r.Business_Hours__c != null && !BusinessHours.isWithin(serviceContracts.get(currentCase.Service_Contract__c).Service_Territory__r.Business_Hours__c, createdDate )){
                    currentCase.Outside_Business_Hours__c = true;
                }
            }
        }
    }
}