global class recallApprovalFromFlow {
   @InvocableMethod
    public static void get(List <String> workItemString) {
        Approval.ProcessWorkItemRequest req = new Approval.ProcessWorkItemRequest();
        Id workItemId = Id.valueOf(workItemString.get(0));
        req.setWorkItemId(workItemId);
        req.setAction('Removed'); // This means to remove/recall Approval Request
        req.setComments('Recall Approval Process from Edit.');
        Approval.ProcessResult result = Approval.process(req);

    }
}