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
        Stage_Document_Automated__c,
        Additional_Client_CC__c,
        Amount_QB__c,
        Invoice_Amount__c,
        Invoice_Due_Date__c,
        Payment_Terms__c,
        CreatedDate,
        (SELECT Id FROM SBQQ__Quotes2__r WHERE SBQQ__Primary__c = TRUE),
        Lead_Producer__c,
        Lead_Producer_Email__c,
        Division__r.Division_Leader__r.Phone,
        CloseDate
      FROM Opportunity
      WHERE Id IN :ids
    ];
  }
  public List<Opportunity> selectOpportunitiesByQuoteIds(Set<Id> ids) {
    return [
      SELECT
        Id,
        Name,
        CC_Payment__c,
        Lead_Type__c,
        Division__r.Name,
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
        Stage_Document_Automated__c,
        Additional_Client_CC__c,
        Amount_QB__c,
        Invoice_Amount__c,
        Invoice_Due_Date__c,
        Payment_Terms__c,
        CreatedDate,
        Lead_Producer__c,
        Lead_Producer_Email__c,
        Division__r.Division_Leader__r.Phone,
        CloseDate
      FROM Opportunity
      WHERE
        Id IN (
          SELECT SBQQ__Opportunity2__c
          FROM SBQQ__Quote__c
          WHERE Id IN :ids
        )
    ];
  }
}
