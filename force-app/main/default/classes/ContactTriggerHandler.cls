public class ContactTriggerHandler {
    //Check if contact is linked as a primary contact on a service contract when the email is cleared
    public static void checkContactEmailUpdated(List<Contact> newContacts, Map<Id,Contact> oldContacts) {
        Map<Id,Contact> contactByIds = new Map<Id,Contact>();
        for(Contact cont : newContacts){
            if(cont.Email != oldContacts.get(cont.Id).Email && cont.Email == null){
                contactByIds.put(cont.Id, cont);
            }
        }
        if(!contactByIds.isEmpty()){
            List<ServiceContract> contracts = ServiceContractDAO.getContractByContactIds(contactByIds.keySet());
            Map<Id,ServiceContract> contractByContact = new Map<Id,ServiceContract>();
            for(ServiceContract sc : contracts){
                contractByContact.put(sc.ContactId, sc);
            }
            if(!contractByContact.isEmpty()){
                for(Contact cont : contactByIds.values()){
                    if(contractByContact.containsKey(cont.Id)){
                        cont.Email.addError(String.format(System.Label.Contact_Email_Required_CL, new List<String> {contractByContact.get(cont.Id).Name}));
                    }
                }
            }
        }
    }
}