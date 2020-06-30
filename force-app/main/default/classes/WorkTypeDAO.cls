public class WorkTypeDAO {
    public static  List<WorkType> getWorkTypeByName(String name){
        List<WorkType> wos = [ Select  Id 
                                From    WorkType 
                                Where   Name = :name];

        return wos;
        
    }
}