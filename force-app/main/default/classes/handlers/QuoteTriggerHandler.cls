public class QuoteTriggerHandler {

  public static void setDivisionName(List<SBQQ__Quote__c> quotes) {
    Set<Id> opportunityIds = new Set<Id>();
    for (SBQQ__Quote__c quote : quotes) {
      if (quote.SBQQ__Opportunity2__c != null) {
        opportunityIds.add(quote.SBQQ__Opportunity2__c);
      }
    }
    Map<Id, Opportunity> opportunities = new Map<Id, Opportunity>(
      [SELECT Id, Division_Name__c FROM Opportunity WHERE Id IN :opportunityIds]
    );
    for (SBQQ__Quote__c quote : quotes) {
      if (
        quote.SBQQ__Opportunity2__c != null &&
        opportunities.containsKey(quote.SBQQ__Opportunity2__c)
      ) {
        quote.Division_Name__c = opportunities.get(quote.SBQQ__Opportunity2__c)
          .Division_Name__c;
      }
    }
  }
}
