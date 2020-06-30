global with sharing class ContractFeesJobWA implements Schedulable{
    global void execute(SchedulableContext sc) {
        ServiceTerritory saTerritory = ServiceTerritoryDAO.getServiceTerritoryWithName('WA');
        CreateContractFeesBatch  batchToExecute = new CreateContractFeesBatch (saTerritory.id); 
        database.executebatch(batchToExecute);

    }
}