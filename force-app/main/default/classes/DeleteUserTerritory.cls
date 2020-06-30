global class DeleteUserTerritory implements Queueable , Database.AllowsCallouts{
    FSL__User_Territory__c utToDelete;

    public DeleteUserTerritory(FSL__User_Territory__c utToDelete) {
        this.utToDelete = utToDelete;
    }

    public void execute(QueueableContext contextIn) {
        delete utToDelete;
    }
}