/**
 * @description : Test class covering sharing logics written in OpportunityTrigger, OpportunityContactRoleTrigger & QuoteTrigger
**/
@isTest
public class RecordsSharingServiceTest {
    @isTest
    static void testHandleQuoteSharing() {
        Division__c division = new Division__c(Name='Slate', Division_Leader__c=UserInfo.getUserId());
        insert division;

        Account account = new Account(Name='Test Account');
        insert account;

        Opportunity opportunity = new Opportunity(Name='Test Opportunity', StageName='Open', CloseDate=Date.today(), AccountId=account.Id, Division__c=division.Id,Lead_Type__c = 'Slate - CGI');
        insert opportunity;

        Test.startTest();
        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Opportunity2__c=opportunity.Id, OwnerId=UserInfo.getUserId());
        insert quote;
        Test.stopTest();

        List<SBQQ__Quote__Share> shares = [SELECT Id, ParentId, UserOrGroupId FROM SBQQ__Quote__Share WHERE ParentId = :quote.Id];
        Assert.areEqual(1, shares.size(), 'Expected one Quote Share record to be created');
        Assert.areEqual(division.Division_Leader__c, shares[0].UserOrGroupId, 'The UserOrGroupId should match the Division Leader');
    }
}