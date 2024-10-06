public class AccountTriggerHandler {
    public static void onAfterInsert(Map<Id,Account> newMap){
        List<Id> createAccTeam = new List<Id>();
        
        for(Account acc:newMap.values()){
            if(acc.RecordTypeId != Schema.SObjectType.Account.getRecordTypeInfosByName().get('Retainer').getRecordTypeId())
                createAccTeam.add(acc.Id);
        }
        
        //Turning off auto team cloning on create. Uncomment to restart.
        //AccountTeamClone.cloneAccountTeam(createAccTeam);
    }
}