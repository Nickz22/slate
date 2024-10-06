public class CloneQuoteFlowController {
    @AuraEnabled public String oldRecordId {get;set;}
    @AuraEnabled public String newRecordId {get;set;}
    
    public CloneQuoteFlowController(ApexPages.StandardController stdController) {
        this.oldRecordId = stdController.getId();
    }

    public Pagereference cloneQuote(){
        Map<String, Object> params = new Map<String, Object>();
        params.put('recordId', oldRecordId);
        Flow.Interview.Clone_Quotes_Exactly cloneFlow = new Flow.Interview.Clone_Quotes_Exactly(params);
        cloneFlow.start();
        newRecordId = (string) cloneFlow.getvariableValue('New_Quote_Id');
        SBQQ__Quote__c newQuote = [SELECT Id, SBQQ__Primary__c FROM SBQQ__Quote__c WHERE Id = :newRecordId];
        if(!newQuote.SBQQ__Primary__c){
            newQuote.SBQQ__Primary__c = true;
            update newQuote;
        }
        PageReference pg = new PageReference('/'+newRecordId);
        pg.setRedirect(true);
        return pg; 
    }
}