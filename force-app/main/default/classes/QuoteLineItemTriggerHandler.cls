public class QuoteLineItemTriggerHandler {
    
    public static void handleAfterInsert(List<SBQQ__QuoteLine__c> lineItems){
        List<SBQQ__QuoteLine__c> lineItemsWithContact = new List<SBQQ__QuoteLine__c>();
        for(SBQQ__QuoteLine__c lineItem : lineItems){
            if(lineItem.Vendor__c != null){
                lineItemsWithContact.add(lineItem);
            }
        }
        if(!lineItemsWithContact.IsEmpty()){
			handleOcrCreation(lineItemsWithContact);            
        }
    }
    
    public static void handleAfterUpdate(List<SBQQ__QuoteLine__c> newList, Map<Id,SBQQ__QuoteLine__c> oldMap){
        List<SBQQ__QuoteLine__c> lineItemsWithContact = new List<SBQQ__QuoteLine__c>();
        for(SBQQ__QuoteLine__c lineItem : newList){
            SBQQ__QuoteLine__c oldItem = oldMap.get(lineItem.Id);
            if(lineItem.Vendor__c != null && oldItem.Vendor__c != lineItem.Vendor__c){
                lineItemsWithContact.add(lineItem);
            }
        }
        if(!lineItemsWithContact.IsEmpty()){
			handleOcrCreation(lineItemsWithContact);            
        }
    }
    
    public static void handleOcrCreation(List<SBQQ__QuoteLine__c> lineItems){
        Set<Id> opportunityIds = new Set<Id>();
        Set<Id> vendorIds = new Set<Id>();
        Map<Id, Id> quoteToOpportunityMap = new Map<Id, Id>();
        List<OpportunityContactRole> rolesToInsert = new List<OpportunityContactRole>();
        
        for (SBQQ__QuoteLine__c quoteLine : lineItems) {
            if (quoteLine.Vendor__c != null && quoteLine.SBQQ__Quote__c != null) {
                opportunityIds.add(quoteLine.SBQQ__Quote__c);
                vendorIds.add(quoteLine.Vendor__c);
            }
        }
        
        if (!opportunityIds.isEmpty()) {
            for (SBQQ__Quote__c quote : [
                SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c 
                WHERE Id IN :opportunityIds
            ]) {
                quoteToOpportunityMap.put(quote.Id, quote.SBQQ__Opportunity2__c);
            }
        }
        
        for (SBQQ__QuoteLine__c quoteLine : lineItems) {
            Id opportunityId = quoteToOpportunityMap.get(quoteLine.SBQQ__Quote__c);
            
            OpportunityContactRole newRole = new OpportunityContactRole(
                OpportunityId = opportunityId,
                ContactId = quoteLine.Vendor__c,
                Role = quoteLine.Lead_Type__c
            );
            rolesToInsert.add(newRole);
        }
        if (!rolesToInsert.isEmpty()) {
            insert rolesToInsert;
        }
    }
    
}