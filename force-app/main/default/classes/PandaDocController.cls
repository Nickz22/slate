/*
 * Name: PandaDocController
 * Description: class which receives pandadoc request fron the platform
 */
public class PandaDocController extends PandaDocManager{
    /*
	 * Description: response wrapper
	 */
    public class ResponseWrapper{
        @AuraEnabled public String state {get;set;}
        @AuraEnabled public Object data {get;set;}
        @AuraEnabled public String message {get;set;}
        @AuraEnabled public String errorTrace  {get;set;}
        
        public ResponseWrapper(){}
    }

    @AuraEnabled
    public static ResponseWrapper getTemplates() {
        ResponseWrapper rw = new ResponseWrapper();
        try{
            rw.data = getTemplateList();
            rw.state = Constants.Status.SUCCESS.name();
        }catch(Exception e){
            rw.state = Constants.Status.ERROR.name();
            rw.errorTrace = e.getStackTraceString();
            rw.message = e.getMessage();
        }
        System.debug(JSON.serializePretty(rw));
        return rw;
    }
    
    @InvocableMethod(label='Generate estimation document' description='Generate estimate document draft')
    public static List<String> generateEstimation(List<String> oppId){
        List<String> result = new List<String>();
        try{
            result.add(generateEstimate(oppId.get(0)));
        }catch(Exception e){
            result.add(e.getMessage());
        }
        System.debug(JSON.serializePretty(result));

        return result;
    }
}