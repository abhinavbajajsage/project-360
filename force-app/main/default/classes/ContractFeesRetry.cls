global class ContractFeesRetry {
    @InvocableMethod(label='execute the batch CreateContractFeesBatch' description='This method will execute CreateContractFeesBatch')
    public static void executeBatchMethod(List<String> contractids) {
        String contractId = contractids.get(0);
        Database.executeBatch(new CreateContractFeesBatch(contractId), 1);
    }  
}