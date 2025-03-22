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
              Invoice_Amount__c,
              Account.Name,
              Opportunity_Descriptor__c,
              InvoiceNumber__c,
              Payment__c,
              Tax_to_collect__c,
              Shoot_Date__c,
              CC_Fee_invoice__c,
              Required_Deposit__c,
              PrimaryContact__r.Email,
              PrimaryContact__r.FirstName,
              PrimaryContact__r.LastName,
              Additional_Client_CC__c,
              Amount_QB__c,
              Invoice_Due_Date__c,
              Payment_Terms__c,
              CreatedDate, (SELECT Id FROM SBQQ__Quotes2__r WHERE SBQQ__Primary__c = true)
            FROM Opportunity
            WHERE Id IN :ids
        ];
    }
}