public class Pandadocs{

    @AuraEnabled
	public cls_results[] results;

	class cls_results {
        @AuraEnabled
		public String id;	//WL4Q88eE8ZW5BdRQcJQCqG

        @AuraEnabled
		public String name;	//Test Document 3

        @AuraEnabled
		public String status;	//document.draft

        @AuraEnabled
		public String date_created;	//2022-03-18T05:03:31.576006Z

        @AuraEnabled
		public String date_modified;	//2022-03-18T05:03:38.999231Z

        @AuraEnabled
		public String date_completed;	//2022-03-18T05:03:38.999231Z

        @AuraEnabled
		public String expiration_date;	//2022-03-18T05:03:38.999231Z

        @AuraEnabled
		public String version;	//2
	}
	public static Pandadocs parse(String json){
		return (Pandadocs) System.JSON.deserialize(json, Pandadocs.class);
	}
}