global with sharing class ContractFeesJobQLD implements Schedulable{
    global void execute(SchedulableContext sc) {
        ServiceTerritory saTerritory = ServiceTerritoryDAO.getServiceTerritoryWithName('QLD');
        CreateContractFeesBatch  batchToExecute = new CreateContractFeesBatch (saTerritory.id); 
        database.executebatch(batchToExecute);

    }
}