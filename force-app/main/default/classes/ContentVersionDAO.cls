public class ContentVersionDAO {

    public static  List<ContentVersion> getContentVersionUsingIds(List<id> versionIds){
        List<ContentVersion> cvs = [SELECT id, 
                                           ContentDocumentId 
                                    FROM   ContentVersion 
                                    WHERE  id 
                                    IN     :versionIds ];

        return cvs;
        
    }
}