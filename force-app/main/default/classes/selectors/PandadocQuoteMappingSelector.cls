public with sharing class PandadocQuoteMappingSelector {
  public PandadocQuoteMappingSelector() {
  }

  public Pandadoc_Quote_Template_Mapping__mdt selectPandadocQuoteTemplateMappingByDivisionName(
    String divisionName
  ) {
    return [
      SELECT
        Division_Name__c,
        Pandadoc_CC_Fee_Estimate_Template_Id__c,
        Pandadoc_CC_Fee_Proposal_Template_Id__c,
        Pandadoc_Proposal_Template_Id__c,
        Pandadoc_Estimate_Template_Id__c,
        Pandadoc_Invoice_Template_Id__c,
        Pandadoc_CC_Fee_Invoice_Template_Id__c
      FROM Pandadoc_Quote_Template_Mapping__mdt
      WHERE Division_Name__c = :divisionName
      LIMIT 1
    ];
  }
}
