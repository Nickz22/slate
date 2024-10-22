public class OCRTriggerHandler {
    
    public static void handleAfterInsert(List<OpportunityContactRole> ocrList){
        RecordsSharingService.handleContactSharing(ocrList, null);
    }
    public static void handleAfterUpdate(List<OpportunityContactRole> ocrList, Map<Id,OpportunityContactRole> oldMap){
        RecordsSharingService.handleContactSharing(ocrList, oldMap);
    }

}