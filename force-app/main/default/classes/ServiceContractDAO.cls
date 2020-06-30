public class ServiceContractDAO {
    public static  List<ServiceContract> getContractByAddress(String street, String suburb, String postcode, String serviceTerritory){
        List<ServiceContract> scs = [   Select  Id, 
                                                ShippingStreet, 
                                                ShippingCity, 
                                                ShippingPostalCode, 
                                                AccountId, 
                                                ContactId, 
                                                Service_Territory__c,
                                                RecordType.Name 
                                        From    ServiceContract 
                                        Where   Shipping_Street_Lower__c = :street 
                                        AND     Shipping_City_Lower__c = :suburb 
                                        AND     ShippingPostalCode = :postcode 
                                        AND     Service_Territory__r.Name  = :serviceTerritory];

        return scs;
        
    }

    public static  List<ServiceContract> getContractByType(String type, String recType, String serviceTerritory){
        List<ServiceContract> scs = [   Select  Id,
                                                RecordType.Name,
                                                ContactId
                                        From    ServiceContract 
                                        Where   Type__c = :type 
                                        AND     RecordType.Name = :recType 
                                        AND     Service_Territory__r.Name = :serviceTerritory];

        return scs;
        
    }

    public static List<ServiceContract> getContractByAccountAndType(Id AccountId, String type){
        List<ServiceContract> scs = [   Select  Id, 
                                                RecordType.Name,
                                                ContactId 
                                        From    ServiceContract 
                                        Where   AccountId = :AccountId 
                                        AND     Type__c = :type];
        return scs;
    }

    public static List<ServiceContract> getContractByContactIds(Set<Id> contactIds){
        List<ServiceContract> scs = [   Select  Id, 
                                                RecordType.Name,
                                                Name,
                                                ContactId,
                                                Normal_Time__c 
                                        From    ServiceContract 
                                        Where   ContactId IN :contactIds
                                        And     Status = 'Active'];
        return scs;
    }

    public static List<ServiceContract> getContractByProntoCode(String contCode){
        List<ServiceContract> scs = [   Select  Id,
                                                Service_Territory__c 
                                        From    ServiceContract
                                        Where   Pronto_Contract_No__c = :contCode];
        return scs;
    }

    public static List<ServiceContract> getContractByContractIds(Set<Id> contractIds){
        List<ServiceContract> scs = [   Select  Id, 
                                                RecordType.Name,
                                                Name,
                                                ContactId,
                                                Normal_Time__c,
                                                Service_Territory__r.Business_Hours__c 
                                        From    ServiceContract 
                                        Where   Id IN :contractIds];
        return scs;
    }
}