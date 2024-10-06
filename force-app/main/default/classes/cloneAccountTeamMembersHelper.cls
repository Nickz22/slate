/**
* @author Aditya Shetty - aditya@tamtechs.com
* @date 03/10/2022
* @description CloneAccountTeamMembers Aura Component Helper class to facilitate all required functions
*/
public with sharing class cloneAccountTeamMembersHelper {
    @AuraEnabled(cacheable=true)
    public static AccountTeamWrapper getTeamMembers(Id AccId) {
        List<Account_Team__c> accountTeam = [SELECT ID,Name,Service_Type__c,Day_Rate__c FROM Account_Team__c WHERE Account__c =: AccId];
        Set<Id> preseletedIds = new Set<Id>(); 
        for(Account_Team__c acc : accountTeam){
            preseletedIds.Add(acc.Id);
        }

        AccountTeamWrapper accTeamWrapper = new AccountTeamWrapper();
        accTeamWrapper.accList = accountTeam;
        accTeamWrapper.selectedIdSet = preseletedIds;
        return accTeamWrapper;
    }   

    @AuraEnabled
    public static String getAccountName (Id AccId){
        Account acc = [SELECT ID,Name FROM Account WHERE Id =:AccId LIMIT 1];
        String accName = '';
        if (acc != null){
            accName = acc.Name;
        }
        return accName;
    }

    @AuraEnabled
    public static String[] getTeamMembersName (List<String> Ids){
        List<Account_Team__c> accountTeam = [SELECT ID,Name FROM Account_Team__c WHERE ID IN: Ids];
        String[] accountTeamNames = new List<String>();
        for(Account_Team__c accTeam : accountTeam){
            accountTeamNames.Add(accTeam.Name);
        }

        return accountTeamNames;
    }
    
    @AuraEnabled
    public static void cloneRecords(String AccId, List<String> Ids){
        List<Account_Team__c> existingAccountTeams = [select id, Service_Type__c,Team_Member__c,Name,Account__c,Active__c,Vetted__c,Day_Rate__c,Half_Day_Rate__c from Account_Team__c where Id IN: Ids];
        List<Account_Team__c> copyAccountTeam = new List<Account_Team__c>();
        for(Account_Team__c existingAccountTeam : existingAccountTeams){
            Account_Team__c ecopy = new Account_Team__c();
            ecopy =	existingAccountTeam.clone(false, false, false, false);
            ecopy.Account__c = AccId;
            copyAccountTeam.Add(ecopy);
        }
        
        if(!copyAccountTeam.isEmpty()){
            try
            {
                insert copyAccountTeam;
            }
            catch(Exception e){
                System.debug(Logginglevel.ERROR, e.getMessage());
                throw new AuraHandledException(e.getMessage());
            }
        }
    }

    public class AccountTeamWrapper{  
        @AuraEnabled public List<Account_Team__c> accList {get; set;}  
        @AuraEnabled public Set<Id> selectedIdSet {get; set;}  
      }  


    public cloneAccountTeamMembersHelper(){

    }
}