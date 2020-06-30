public class Log {
    
    public Integer code;
    public String message;
    public String status;
    public Data data;
    
    public class Data {
        public List<Validation_errors> validation_errors;
    }
    
    public class Validation_errors {
        public String field;
        public String error;
    }
}