public class AccountTeamClone {
    
    @TestVisible private static Id sourceAcc;
    private static List<Id> copyToAccs;
    private static List<Account_Team__c> sourceTeam;
    
    @InvocableMethod(label='Clone Account Team' description='Clone an account team to another account')
    public static void cloneAccountTeam(List<Id> toAccs){
        
        if(!Test.isRunningTest())
        	sourceAcc = System.Label.Default_Account_Team;
        
        copyToAccs = toAccs;
        
        cloneTeam();
    }
    
    private static void cloneTeam(){
        
        sourceTeam = [SELECT Name, Active__c, Vetted__c, Day_Rate__c, Half_Day_Rate__c,Service_Type__c, Team_Member__c
                      FROM Account_Team__c WHERE Account__c =: sourceAcc AND Active__c = true];
        
        List<Account_Team__c> cloned = new List<Account_Team__c>();
        
        for(Id copyToAcc:copyToAccs){
            for(Account_Team__c at:sourceTeam){
                Account_Team__c newAt = new Account_Team__c();
                newAt.Name = at.Name;
                newAt.Account__c = copyToAcc;
                newAt.Team_Member__c = at.Team_Member__c;
                newAt.Active__c = true;
                newAt.Vetted__c = at.Vetted__c;
                newAt.Day_Rate__c = at.Day_Rate__c;
                newAt.Half_Day_Rate__c = at.Half_Day_Rate__c;
                newAt.Service_Type__c = at.Service_Type__c;
                
                cloned.add(newAt);
            }
        }
        
        if(!cloned.isEmpty())
            insert cloned;
    }
    
}