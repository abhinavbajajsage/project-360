global with sharing class ContractFeesJobNSW implements Schedulable{
    global void execute(SchedulableContext sc) {
        ServiceTerritory saTerritory = ServiceTerritoryDAO.getServiceTerritoryWithName('NSW');
        CreateContractFeesBatch  batchToExecute = new CreateContractFeesBatch (saTerritory.id); 
        database.executebatch(batchToExecute);

    }
}