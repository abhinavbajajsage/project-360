global with sharing class ContractFeesJobVIC implements Schedulable{
    global void execute(SchedulableContext sc) {
        ServiceTerritory saTerritory = ServiceTerritoryDAO.getServiceTerritoryWithName('VIC');
        CreateContractFeesBatch  batchToExecute = new CreateContractFeesBatch (saTerritory.id); 
        database.executebatch(batchToExecute);

    }
}