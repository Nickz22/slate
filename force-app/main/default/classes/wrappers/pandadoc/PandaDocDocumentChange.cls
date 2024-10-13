public class PandaDocDocumentChange {
    public String event;
    public DocumentData data;
    
    public class DocumentData {
        public String id;
        public String name;
        public String status;
        public Metadata metadata;
        public List<Recipient> recipients;
        public User sent_by;
        public GrandTotal grand_total;
        public Template template;
    }
    
    public class Metadata {
        public String salesforce_opportunity_id;
        public String folder;
    }
    
    public class Recipient {
        public String id;
        public String first_name;
        public String last_name;
        public String email;
        public String recipient_type;
        public Boolean has_completed;
        public List<String> roles;
    }
    
    public class User {
        public String id;
        public String email;
        public String first_name;
        public String last_name;
    }
    
    public class GrandTotal {
        public String amount;
    }
    
    public class Template {
        public String id;
        public String name;
    }
    
    public static PandaDocDocumentChange parse(String json) {
        return (PandaDocDocumentChange) System.JSON.deserialize(json, PandaDocDocumentChange.class);
    }
}