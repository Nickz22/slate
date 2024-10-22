/*
 * @description : Common class containing sharing logic, called from different triggers
**/
public class RecordsSharingService {
    //Method to share contacts on OpportunityContactRole creation/updation
    public static void handleContactSharing(List<OpportunityContactRole> ocrList, Map<Id,OpportunityContactRole> oldMap){
        Map<Id,set<Id>> oppIdsToContactIdsMap = new Map<Id,set<Id>>();
        Map<Id,Id> oppToDivisionLeaderIdMap = new Map<Id,Id>();
        for(OpportunityContactRole ocr:ocrList){
            if(oldMap == null || oldMap.get(ocr.Id).ContactId != ocr.ContactId){
                if(!oppIdsToContactIdsMap.containsKey(ocr.OpportunityId)){
                    oppIdsToContactIdsMap.put(ocr.OpportunityId,new Set<Id>());
                }
                oppIdsToContactIdsMap.get(ocr.OpportunityId).add(ocr.ContactId);
            }
        }
        for(Opportunity opp:[Select Id,Division__r.Division_Leader__c from Opportunity where Id IN :oppIdsToContactIdsMap.KeySet() AND Division__c != Null]){
            oppToDivisionLeaderIdMap.put(opp.Id,opp.Division__r.Division_Leader__c);
        }
        List<ContactShare> sharesToInsert = new List<ContactShare>();
        for(Id oppId:oppToDivisionLeaderIdMap.KeySet()){
            Id divisionLeaderId = oppToDivisionLeaderIdMap.get(oppId);
            for(Id conId:oppIdsToContactIdsMap.get(oppId)){
                ContactShare newShare = new ContactShare();
                newShare.ContactId = conId;
                newShare.UserOrGroupId = divisionLeaderId;
                newShare.ContactAccessLevel = 'Read';
                sharesToInsert.add(newShare);
            }
        }
        if(sharesToInsert.size()>0){
            Database.insert(sharesToInsert, false);
        }
    }
    
    public static void handleAccount_PrimaryContactSharing(List<Opportunity> newRecords, Map<Id, Opportunity> oldMap){
        Set<Id> divisionIds = new Set<Id>();
        Map<Id, Set<Id>> accToDivisionIdsMap = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> contactIdToDivisionIdsMap = new Map<Id, Set<Id>>();
        for(Opportunity opp : newRecords){
            if(opp.Division__c != null){
                divisionIds.add(opp.Division__c);
                if(oldMap == null || opp.AccountId != oldMap.get(opp.Id).AccountId){
                    if(!accToDivisionIdsMap.containsKey(opp.AccountId)){
                        accToDivisionIdsMap.put(opp.AccountId, new Set<Id>());
                    }
                    accToDivisionIdsMap.get(opp.AccountId).add(opp.Division__c);
                }
                if(oldMap == null || opp.PrimaryContact__c != oldMap.get(opp.Id).PrimaryContact__c){
                    if(opp.PrimaryContact__c != null){
                        if(!contactIdToDivisionIdsMap.containsKey(opp.PrimaryContact__c)){
                            contactIdToDivisionIdsMap.put(opp.PrimaryContact__c, new Set<Id>());
                        }
                        contactIdToDivisionIdsMap.get(opp.PrimaryContact__c).add(opp.Division__c);
                    }
                }
            }
        }
        Map<Id, Division__c> divisionsMap = new Map<Id, Division__c>([SELECT Division_Leader__c FROM Division__c WHERE Id IN :divisionIds]);
        List<SObject> sharesToInsert = new List<SObject>();
        
        for (Id accId : accToDivisionIdsMap.keySet()) {
            Set<Id> relatedDivisions = accToDivisionIdsMap.get(accId);
            for (Id divisionId : relatedDivisions) {
                Id divisionLeaderId = divisionsMap.get(divisionId).Division_Leader__c;
                AccountShare newShare = new AccountShare();
                newShare.AccountId = accId;
                newShare.UserOrGroupId = divisionLeaderId;
                newShare.AccountAccessLevel = 'Read';
                newShare.RowCause = Schema.AccountShare.RowCause.Manual;
                newShare.ContactAccessLevel = 'None';
                sharesToInsert.add(newShare);
            }
        }
        for(Id conId : contactIdToDivisionIdsMap.keySet()){
            Set<Id> relatedDivisions = contactIdToDivisionIdsMap.get(conId);
            for (Id divisionId : relatedDivisions) {
                Id divisionLeaderId = divisionsMap.get(divisionId).Division_Leader__c;
                ContactShare newShare = new ContactShare();
                newShare.ContactId = conId;
                newShare.UserOrGroupId = divisionLeaderId;
                newShare.ContactAccessLevel = 'Read';
                sharesToInsert.add(newShare);
            }
        }
        
        if (!sharesToInsert.isEmpty()) {
            Database.insert(sharesToInsert,false);
        }
    }
    
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