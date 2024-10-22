public class QuoteTriggerHandler {
    
    public static void handleAfterInsert(List<SBQQ__Quote__c> quotes){
        RecordsSharingService.handleQuoteSharing(quotes);
    }

}