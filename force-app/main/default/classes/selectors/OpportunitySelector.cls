public with sharing class OpportunitySelector {
    public OpportunitySelector() {

    }

    public List<Opportunity> selectOpportunitiesByIds(Set<Id> ids) {
        return [
            SELECT
              Name,
              Account.Name,
              CC_Payment__c,
              CC_Fee_invoice__c,
              Division__r.Name,
              InvoiceNumber__c,
              Upper_Descriptor__c,
              Payment__c,
              PrimaryContact__r.FirstName,
              PrimaryContact__r.LastName,
              PrimaryContact__r.Email,
              Tax_to_collect__c,
              Invoice_Amount__c
            FROM Opportunity
            WHERE Id IN :ids
        ];
    }
}