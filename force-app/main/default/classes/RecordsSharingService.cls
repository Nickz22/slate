/*
 * @description : Common class containing sharing logic, called from different triggers
**/
public class RecordsSharingService {
    public static void handleQuoteSharing(List<SBQQ__Quote__c > quoteList){
        Map<Id,Id> oppToDivisionLeaderIdMap = new Map<Id,Id>();
        Map<Id, Set<Id>> oppIdToQuotesMap = new Map<Id, Set<Id>>();
        for(SBQQ__Quote__c quoteRec : quoteList){
            if(!oppIdToQuotesMap.containsKey(quoteRec.SBQQ__Opportunity2__c)){
                oppIdToQuotesMap.put(quoteRec.SBQQ__Opportunity2__c,new Set<Id>());
            }
            oppIdToQuotesMap.get(quoteRec.SBQQ__Opportunity2__c).add(quoteRec.Id);
        }
        for(Opportunity opp:[Select Id,Division__r.Division_Leader__c from Opportunity where Id IN :oppIdToQuotesMap.KeySet() AND Division__c != Null]){
            oppToDivisionLeaderIdMap.put(opp.Id,opp.Division__r.Division_Leader__c);
        }
        List<SBQQ__Quote__Share> sharesToInsert = new List<SBQQ__Quote__Share>();
        for(Id oppId:oppToDivisionLeaderIdMap.KeySet()){
            Id divisionLeaderId = oppToDivisionLeaderIdMap.get(oppId);
            for(Id quoteId:oppIdToQuotesMap.get(oppId)){
                SBQQ__Quote__Share newShare = new SBQQ__Quote__Share();
                newShare.ParentId = quoteId;
                newShare.UserOrGroupId = divisionLeaderId;
                newShare.AccessLevel = 'Read';
                sharesToInsert.add(newShare);                    
            }
        }
        if(sharesToInsert.size()>0){
            Database.insert(sharesToInsert, false);
        }
    }
    
}