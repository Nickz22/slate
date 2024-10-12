public with sharing class OpportunitySelector {
    public OpportunitySelector() {

    }

    public List<Opportunity> selectOpportunitiesByIds(Set<Id> ids) {
        return [
            SELECT
              Id,
              Name,
              CC_Payment__c,
              Lead_Type__c,
              Division__r.Name,
              Account.Name,
              Upper_Descriptor__c,
              InvoiceNumber__c,
              Payment__c,
              Tax_to_collect__c,
              Shoot_Date__c,
              CC_Fee_invoice__c,
              PrimaryContact__r.Email,
              PrimaryContact__r.FirstName,
              PrimaryContact__r.LastName,
              Invoice_Amount__c
            FROM Opportunity
            WHERE Id IN :ids
        ];
    }
}