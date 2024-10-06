public class AccountTeamTriggerHandler {
	
    public static void onBeforeInsert()
    {
        //Get list of accounts new team member(s) are being added for
        Set<Id> accounts = new Set<Id>();
        for(Account_Team__c ac:(List<Account_Team__c>)Trigger.new)
        {
            if(!accounts.contains(ac.Account__c))
                accounts.add(ac.Account__c);
        }
        
        //Get list of existing team members for the accounts
        //and create a set with string accountId-contactId for matching
        Set<String> existingTeam = new Set<String>();
        for(Account_Team__c ex:[SELECT Account__c, Team_Member__c FROM Account_Team__c WHERE Account__c IN: accounts])
        {
            existingTeam.add(ex.Account__c+'-'+ex.Team_Member__c);
        }
        System.debug(existingTeam);
        //check for duplicates from the existingTeam list and throw error if duplicate is found
        for(Account_Team__c check:(List<Account_Team__c>)Trigger.new)
        {
            System.debug(check.Account__c+'-'+check.Team_Member__c);
            if(existingTeam.contains(check.Account__c+'-'+check.Team_Member__c))
                check.addError('Team member already exists');
        }
    }
}