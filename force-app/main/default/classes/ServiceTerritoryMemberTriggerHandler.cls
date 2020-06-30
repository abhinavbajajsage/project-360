public class ServiceTerritoryMemberTriggerHandler {
    public static void syncUserTerritoryRecords(List<ServiceTerritoryMember> newRecs, Map<Id,ServiceTerritoryMember> oldRecs) {
        List<FSL__User_Territory__c> newuserTerritories = new List<FSL__User_Territory__c>();
        Set<ID> srIds = new Set<ID>();
        Map<Id,Map<Id,Id>> resToTeriToSTM = new Map<Id,Map<Id,Id>>();
        Map<Id,ServiceResource> serviceResources = new Map<Id,ServiceResource>();
        Map<Id,ServiceResource> userToSR = new Map<Id,ServiceResource>();

        if(newRecs != null && !newRecs.isEmpty()){
            for(ServiceTerritoryMember stm : newRecs){
                srIds.add(stm.ServiceResourceId);
                Map<Id,Id> tempMap = new Map<Id,Id>();
                tempMap.put(stm.ServiceTerritoryId, stm.Id);
                resToTeriToSTM.put(stm.ServiceResourceId, tempMap);
            }

            if(!srIds.isEmpty()){
                serviceResources = ServiceResourceDAO.getServiceResources(srIds);
                for(ServiceResource sr : serviceResources.values()){
                    userToSR.put(sr.RelatedRecordId, sr);
                }
            }

            List<FSL__User_Territory__c> updateUTs = new List<FSL__User_Territory__c>();
            for(ServiceTerritoryMember stm : newRecs){
                if(oldRecs == null && serviceResources.containsKey(stm.ServiceResourceId)){
                    newuserTerritories.add(new FSL__User_Territory__c(FSL__ServiceTerritory__c = stm.ServiceTerritoryId, FSL__User__c = serviceResources.get(stm.ServiceResourceId).RelatedRecordId));
                }
                if(oldRecs != null && !oldRecs.isEmpty() && oldRecs.get(stm.Id).ServiceResourceId != stm.ServiceResourceId){
                    updateUTs.add(new FSL__User_Territory__c(Id = stm.User_Territory__c, FSL__User__c = serviceResources.get(stm.ServiceResourceId).RelatedRecordId));
                }
            }

            if(!updateUTs.isEmpty()){
                update updateUTs;
            }

            if(!newuserTerritories.isEmpty()){
                insert newuserTerritories;
                List<ServiceTerritoryMember> updateList = new List<ServiceTerritoryMember>();
                if(!resToTeriToSTM.isEmpty()){
                    for(FSL__User_Territory__c userTer : newuserTerritories){
                        if(resToTeriToSTM.containsKey(userToSR.get(userTer.FSL__User__c).Id) && resToTeriToSTM.get(userToSR.get(userTer.FSL__User__c).Id).containsKey(userTer.FSL__ServiceTerritory__c)){
                            updateList.add(new ServiceTerritoryMember(Id = resToTeriToSTM.get(userToSR.get(userTer.FSL__User__c).Id).get(userTer.FSL__ServiceTerritory__c), User_Territory__c = userTer.Id));
                        }
                    }
                }
                if(!updateList.isEmpty()){
                    update updateList;
                }
                
            }
        }else{
            List<FSL__User_Territory__c> deleteUTs = new List<FSL__User_Territory__c>();
            for(ServiceTerritoryMember stm : oldRecs.values()){
                deleteUTs.add(new FSL__User_Territory__c(Id = stm.User_Territory__c));
            }
            delete deleteUTs;
        }
    }
}