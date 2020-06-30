global with sharing class ContractFeesJobNT implements Schedulable{
    global void execute(SchedulableContext sc) {
        ServiceTerritory saTerritory = ServiceTerritoryDAO.getServiceTerritoryWithName('NT');
        CreateContractFeesBatch  batchToExecute = new CreateContractFeesBatch (saTerritory.id); 
        database.executebatch(batchToExecute);

    }
}