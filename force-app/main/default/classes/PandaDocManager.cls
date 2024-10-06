/*
 * Name: PandaDocManager
 * Description: main logic of pandadoc callouts
 */
public virtual class PandaDocManager {
    /*
     * Description: get template list
     */ 
    public static PandadocTemplate getTemplateList() {
        PandadocTemplate result;
        HttpRequest req = PandaDocWebServiceUtils.setRequest('PandaDocTemplates', Constants.GET_METHOD);
        result = PandadocTemplate.parse(PandaDocWebServiceUtils.getResponse(req).getBody());
        return result;
    }
    
    /*
     * Description: get specific template
     */
    public static String getTemplate(String templateName) {
        String templateId;
        for(pt_results template : getTemplateList().results){
            if(templateName.equals(template.name)){
                templateId = template.id;
                break;
            }
        }
        return templateId;
    }

    /*
     * Description: get specific template
     */
    public static String getTemplateIdByName(String templateName) {
        PandaDocTemplate__mdt templateMdt = [SELECT DocumentId__c FROM PandaDocTemplate__mdt WHERE DeveloperName = :templateName];
        return templateMdt.DocumentId__c;
    }
    
    /*
     * Description: send document from PandaDoc to receivers
     */
    public static Boolean sendDocument(String docId, String message, String subject) {
        String endpointExtension = docId + '/send';
        String body = '{ "message": "' + message + '", "subject": "' + subject + '", "silent": true }';
        HttpRequest req = PandaDocWebServiceUtils.setRequest('PandaDocDocuments', Constants.POST_METHOD, null, body, endpointExtension);
        HttpResponse res = PandaDocWebServiceUtils.getResponse(req);
        if(res.getStatusCode() == 200){
            return true;
        }
        else {
            return false;
        }
    }
    
    /*
     * Description: generate estimation
     */
    public static String generateEstimate(String args){
        List<String> argsList = args.split(';');
        String oppId = argsList.get(0);
        String clientAgreement = argsList.get(1);
        Opportunity opp = [SELECT Id, ContactId, Account.Name, Name, Upper_Descriptor__c, Text_Title_Case_Shoot_Dates__c,InvoiceNumber__c,
                           Stringnum__c, Text_Processing_Fee_Invoice__c, Text_invoice_amt__c, UPPER_CLIENT__c, Text_Shoot_Dates__c,
                           CC_Fee_Estimate__c, Deposit_Amount__c, Estimate_Status__c, Service_Type__c, UPPER_TYPE__c, Account.Deposit_Rate__c,
                           Account.Late_Fee_Rate__c, Account.Balance_Rate__c
                           FROM Opportunity WHERE Id = :oppId];
        String bodyTemplate = generateEstimateBodyTemplate(opp, 'SlateEstimate', clientAgreement);
        System.debug(JSON.serializePretty(bodyTemplate));
        HttpRequest req = PandaDocWebServiceUtils.setRequest('PandaDocDocuments', Constants.POST_METHOD, new Map<String, String>{'Content-Type'=>'application/json', 'accept'=> 'application/json'}, bodyTemplate, null);
        HttpResponse res = PandaDocWebServiceUtils.getResponse(req);
        String docId = (String)((Map<String,Object>) JSON.deserializeUntyped(res.getBody())).get('id');
        if(res.getStatusCode() == 201){
            linkDocumentToRecord(docId, 'opportunity', opp.Id);
        }
        return docId;
    }
    
    /*
     * Description: generate Estimate body template
     */
    public static String generateEstimateBodyTemplate(Opportunity opp, String company, String clientAgreement) {
        String documentName = opp.Name;
        String templateId = getTemplateIdByName(company);
        Contact contact = [SELECT Id, Name, FirstName, LastName, Email FROM Contact WHERE Id = :opp.ContactId];
        String createDocumentJSON = '{"name":"' + documentName + '","template_uuid":"'+ templateId +'","recipients":[{"email":"' + contact.Email + '","last_name":"' + contact.LastName + '","first_name":"' + contact.FirstName + '"}]}';
        Map<String, Object> fields = new Map<String, Object>{
            'Name'=> opp.Name,
            'Upper_Descriptor__c'=> opp.Upper_Descriptor__c,
            'UPPER_CLIENT__c'=> opp.UPPER_CLIENT__c, 
            'Invoice_Amount_Text__c'=> opp.InvoiceNumber__c,
            'stringnum__c'=> opp.Stringnum__c,
            'TEXT_INVOICE_AMT__C'=> opp.Text_invoice_amt__c,
            'UPPER_TYPE__c'=> opp.Upper_type__c,
            'Deposit_Amount__c'=> opp.Deposit_Amount__c,
            'Estimate_Status__c'=> opp.Estimate_Status__c,
            'Client_Agreement__c'=> clientAgreement,
            'Late_Fee_Rate__c'=> opp.Account.Late_Fee_Rate__c,
            'Deposit_Rate__c'=> Integer.valueOf(opp.Account.Deposit_Rate__c),
            'Balance_Rate__c'=> Integer.valueOf(opp.Account.Balance_Rate__c)
        };
        if(clientAgreement.equals('true')) {
            fields.put('Show_Text_Shoot_Dates__c', opp.Text_Shoot_Dates__c);
            fields.put('Show_Text_Processing_Fee_Invoice__c', opp.Text_Processing_Fee_Invoice__c);
            fields.put('Show_CC_Fee_Estimate__c', opp.CC_Fee_Estimate__c);
        }

        Map<String,Object> createDocumentData = new Map<String,Object>();
        createDocumentData.put('pricing_tables', generatePricingTable(opp.Id));
        createDocumentData.put('tokens', generateTokens(fields));
        createDocumentData = addBodyProperties(createDocumentData, contact, documentName, templateId);
        return JSON.serialize(createDocumentData);
    }
    
    /*
     * Description: Add body properties
     */
    private static Map<String, Object> addBodyProperties(Map<String, Object> returnMap, Contact contact, String docName, String templateId){
        returnMap.put('recipients', new List<Object>{
                new Map<String, Object>{
                    'first_name'=> contact.FirstName,
                    'last_name'=> contact.LastName,
                    'email'=> contact.Email
                }
        });
        returnMap.put('template_uuid', templateId);
        returnMap.put('name', docName);
        return returnMap;
    }


    /*
     * Description: generate tokens for document body
     */
    public static List<Map<String, Object>> generateTokens(Map<String, Object> params) {
        List<Map<String, Object>> resultList = new List<Map<String, Object>>();
        for(String key: params.keySet()) {
            resultList.add(new Map<String,Object>{'value' => params.get(key), 'name' => key});
        }
        return resultList;
    }
    
    /*
     * Description: generate pricing tables
	 */
    public static Object generatePricingTable(Id oppId){
        List<SBQQ__QuoteLine__c> quotes = [SELECT SBQQ__Product__r.Name,
                                                SBQQ__ListPrice__c,
                                                Customer_Unit_Cost__c,
                                                SBQQ__Quantity__c,
                                                Days_on_Project5__c,
                                                SBQQ__CustomerTotal__c
                                            FROM SBQQ__QuoteLine__c 
                                            WHERE  SBQQ__Quote__r.SBQQ__Opportunity2__r.Id = :oppId 
                                                AND SBQQ__Quote__r.SBQQ__Primary__c = true
                                            ORDER BY SBQQ__Number__c];
        List<Object> pricingItems = new List<Object>();
        for(SBQQ__QuoteLine__c line : quotes) {
            pricingItems.add(
                new Map<String, Object>{
                    'data'=> new Map<String, Object>{
                        'Name'=> line.SBQQ__Product__r.Name,
                        'Text_Unit_Cost__c' => line.SBQQ__ListPrice__c,
                        'Text_Customer_Price__c' => line.Customer_Unit_Cost__c	,
                        'Days_Required__c' => Integer.valueOf(line.Days_on_Project5__c),
                        'QTY'=> Integer.valueOf(line.SBQQ__Quantity__c),
                        'Quantity'=> Integer.valueOf(line.SBQQ__Quantity__c),
                        'Price'=> line.SBQQ__CustomerTotal__c
                    },
                    'options'=> new Map<String, Object>{
                        'optional'=> false,
                        'qty_editable'=> false
                    }
                }
            );
        }                                            
        Object pricing_tables = new List<Object>{
            new Map<String, Object>{
                'sections' => new List<Object>{
                    new Map<String, Object>{
                        'title' => 'sample selection',
                        'default' => true,
                        'rows' => pricingItems 
                    }
                },
                'name'=> 'Pricing Table 1',
                'data_merge'=> true,
                'options' => new Map<String, Object>{
                    'Tax'=> new Map<String, Object>{
                        'type' => 'absolute',
                        'name' => 'Discount',
                        'value' => 0
                        }
                }
            } 
        };
        return pricing_tables;
    }

    /*
     * Description: link document to a SF record
     */
    private static void linkDocumentToRecord(String docId, String objectType, String recordId){
        Organization org = [SELECT IsSandbox FROM Organization LIMIT 1];
        Map<String, Object> requestBody = new Map<String, Object>{
            'provider'=> org.IsSandbox ? 'salesforce-oauth2-sandbox' : 'salesforce-oauth2',
            'entity_type'=> objectType,
            'entity_id'=> recordId
        };  
        String endpointExtension = '/' + docId + '/linked-objects';
        String body = JSON.serialize(requestBody);
        HttpRequest req = PandaDocWebServiceUtils.setRequest('PandaDocDocuments', Constants.POST_METHOD, new Map<String, String>{'Content-Type'=>'application/json', 'accept'=> 'application/json'}, body, endpointExtension);
        HttpResponse res = PandaDocWebServiceUtils.getResponse(req);
        if(res.getStatusCode() != 201) {
            linkDocumentToRecord(docId, objectType, recordId);
        }
    }

    @InvocableMethod(label='Send estimation document' description='Send estimate document to recipient')
    public static List<String> sendEstimate(List<String> docId) {
        List<String> result = new List<String>();
        try{
            sendDocument(docId.get(0), Label.PandaDocSendEstimateMessage, Label.PandaDocSendEstimateSubject);
        }catch(Exception e){
            result.add(Constants.Status.ERROR.name());
            result.add(e.getStackTraceString());
            result.add(e.getMessage());
        }
        System.debug(JSON.serializePretty(result));
        return result;
    }

    /////////////////////////////Response structures///////////////////////////////
    public static PandadocTemplate parse(String json){
        return (PandadocTemplate) System.JSON.deserialize(json, PandadocTemplate.class);
    }

    public class PandadocTemplate{
        public pt_results[] results;
        
    }

    class pt_results {
        public String id;	//mJLA444LyyJjXHz2rBBYtR
        public String name;	//Start exploring here! (Product guide)
        public String date_created;	//2022-03-18T04:57:49.170663Z
        public String date_modified;	//2022-03-18T04:57:49.213011Z
        public String version;	//2
    }
}