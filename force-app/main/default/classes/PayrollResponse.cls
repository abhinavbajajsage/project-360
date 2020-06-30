//TRANSACTION VALIDATION
public class PayrollResponse {
    
    public Integer code;
    public String status;
    public String message;
    public Data data;
    
    public class Data {
        public Boolean valid;
    }
    
}