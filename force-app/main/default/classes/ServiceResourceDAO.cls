public class ServiceResourceDAO {
    public static Map<Id,ServiceResource> getServiceResources(Set<Id> srIds) {
        Map<Id,ServiceResource> serviceResources = new Map<Id,ServiceResource>([Select Id,RelatedRecordId From ServiceResource Where Id IN :srIds]);
        return serviceResources;
    }
}