/*
 * Name: PandaDocWebServiceUtils
 * Description: Class in charge of callout to PandaDoc
 */
public class PandaDocWebServiceUtils {
    public static final String SEPARATOR_SLASH = ' / ';
    public static final String EMPTY = '';
    public static final EndpointSetup__c setup = EndpointSetup__c.getValues('API Keys');
    public static final String apiKey = !Test.isRunningTest() ?setup.PandaDocAPIKey__c : ''; 

	/*
     * Description: set PandaDoc request
	 */
    public static HttpRequest setRequest(String endpoint, String method) {
        return setRequest(endpoint, method, null, null, null);
    }
    
    /*
     * Description: set PandaDoc request
	 */
    public static HttpRequest setRequest(String endpoint, String method, Map<String, String> header, String body, String endpointExtension) {
        String url = generateUrl(endpoint) + (String.isNotBlank(endpointExtension) ? endpointExtension : '');
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod(method);
        req.setHeader('Authorization', 'API-Key ' + apiKey);
        if(header != null) {
            for(String key : header.keySet()) {
                req.setHeader(key, header.get(key));
            }
        }
        if(String.isNotBlank(body)) {
            req.setBody(body);
        }
        return req;
    }

    /*
     * Descriotion: get response
     */
    public static HttpResponse getResponse(HttpRequest req) {
        Http h = new Http();
        HttpResponse response;
        response = h.send(req);
        return response;
    }
    
    /*
     * Description: generate full url endpoint
     */
    public static String generateUrl(String endpointName) {
        Map<String, Endpoint__mdt> endpointSOQLMap = new Map<String, Endpoint__mdt>();
        
        for(Endpoint__mdt endpoint : [SELECT Id, Parent__c, Path__c, URL__c, DeveloperName FROM Endpoint__mdt]) {
            endpointSOQLMap.put(endpoint.DeveloperName, endpoint);
        }
        Map<String, Object> endpointMap = urlGenerator(endpointName, EMPTY, endpointSOQLMap);
        Endpoint__mdt endpoint = (Endpoint__mdt) endpointMap.get('endpoint');
        return (String) endpointMap.get('url');
    }
    
	/*
     * Description: Generator URL
     */ 
    public static Map<String, Object> urlGenerator(String endpointName, String url, Map<String, Endpoint__mdt> endpointSOQLMap) {
        Map<String, Object> endpointMap = new Map<String, Object>();
        Endpoint__mdt endpoint = endpointSOQLMap.get(endpointName);
        if(endpoint != null) {
            if(String.isNotBlank(endpoint.Parent__c)) {
                url = (!endpoint.Path__c.startsWith(SEPARATOR_SLASH.trim())) ? SEPARATOR_SLASH.trim() + endpoint.Path__c + url : endpoint.Path__c + url;
                endpointMap = urlGenerator(endpoint.Parent__c, url, endpointSOQLMap);
            } else {
                url = (endpoint.URL__c.endsWith(SEPARATOR_SLASH.trim())) ? endpoint.URL__c.substring(0, endpoint.URL__c.length() - 1) + url : endpoint.URL__c + url;
                if(endpointMap.isEmpty()) {
                    endpointMap.put('url', url);
                    endpointMap.put('endpoint', endpoint);
                }
            }
        }
        return endpointMap;
    }
}