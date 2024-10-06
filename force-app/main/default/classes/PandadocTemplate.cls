public class PandadocTemplate{
    @AuraEnabled
	public cls_results[] results;
	class cls_results {
        @AuraEnabled
		public String id;	//mJLA444LyyJjXHz2rBBYtR

        @AuraEnabled
		public String name;	//Start exploring here! (Product guide)

        @AuraEnabled
		public String date_created;	//2022-03-18T04:57:49.170663Z

        @AuraEnabled
		public String date_modified;	//2022-03-18T04:57:49.213011Z

        @AuraEnabled
		public String version;	//2
	}
	public static PandadocTemplate parse(String json){
		return (PandadocTemplate) System.JSON.deserialize(json, PandadocTemplate.class);
	}
}