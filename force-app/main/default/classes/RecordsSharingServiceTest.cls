/**
 * @description : Test class covering sharing logics written in OpportunityTrigger, OpportunityContactRoleTrigger & QuoteTrigger
**/
@isTest
public class RecordsSharingServiceTest {
    
    @isTest
    static void testHandleContactSharingWithOCRInsertion() {
        Division__c division = new Division__c(Name='Slate', Division_Leader__c=UserInfo.getUserId());
        insert division;

        Account account = new Account(Name='Test Account');
        insert account;

        Opportunity opportunity = new Opportunity(Name='Test Opportunity', StageName='Open', CloseDate=Date.today(), AccountId=account.Id, Division__c=division.Id, Lead_Type__c = 'Slate - CGI');
        insert opportunity;

        Contact contact1 = new Contact(FirstName='Test1', LastName='User1', AccountId=account.Id, Email='test1@test.com');
        insert contact1;

        Test.startTest();
        OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId=opportunity.Id, ContactId=contact1.Id, Role='Decision Maker');
        insert ocr;
        Test.stopTest();
        
        List<ContactShare> initialShares = [SELECT Id, ContactId, UserOrGroupId FROM ContactShare WHERE ContactId = :contact1.Id];
        Assert.areEqual(1, initialShares.size(), 'Expected one ContactShare record to be created');
    }
    @isTest
    static void testHandleContactSharingWithOCRUpdation() {
        Division__c division = new Division__c(Name='Slate', Division_Leader__c=UserInfo.getUserId());
        insert division;

        Account account = new Account(Name='Test Account');
        insert account;

        Opportunity opportunity = new Opportunity(Name='Test Opportunity', StageName='Open', CloseDate=Date.today(), AccountId=account.Id, Division__c=division.Id, Lead_Type__c = 'Slate - CGI');
        insert opportunity;

        Contact contact1 = new Contact(FirstName='Test1', LastName='User1', AccountId=account.Id, Email='test1@test.com');
        insert contact1;

        Contact contact2 = new Contact(FirstName='Test2', LastName='User2', AccountId=account.Id, Email='test2@test.com');
        insert contact2;        

        OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId=opportunity.Id, ContactId=contact1.Id, Role='Decision Maker');
        insert ocr;
        
        Test.startTest();
        ocr.ContactId = contact2.Id;
        update ocr;
        Test.stopTest();
        
        List<ContactShare> newShares = [SELECT Id, ContactId, UserOrGroupId FROM ContactShare WHERE ContactId = :contact2.Id];
        Assert.areEqual(1, newShares.size(), 'Expected one ContactShare record for the new Contact');
        Assert.areEqual(division.Division_Leader__c, newShares[0].UserOrGroupId, 'The UserOrGroupId should match the Division Leader');

    }
    
    @isTest
    static void testHandleAccount_PrimaryContactSharing() {
        Division__c division = new Division__c(Name='Slate', Division_Leader__c=UserInfo.getUserId());
        insert division;

        Account account = new Account(Name='Test Account');
        insert account;

        Opportunity opportunity = new Opportunity(Name='Test Opportunity', StageName='Open', CloseDate=Date.today(), AccountId=account.Id, Division__c=division.Id, Lead_Type__c = 'Slate - CGI');
        insert opportunity;

        Contact contact = new Contact(FirstName='Test', LastName='User', AccountId=account.Id, Email='test@test.com');
        insert contact;

        Test.startTest();
        opportunity.PrimaryContact__c = contact.Id;
        update opportunity;
        Test.stopTest();

        List<AccountShare> accShares = [SELECT Id, AccountId, UserOrGroupId FROM AccountShare WHERE AccountId = :account.Id];
        Assert.areEqual(1, accShares.size(), 'Expected one AccountShare record to be created');
        Assert.areEqual(division.Division_Leader__c, accShares[0].UserOrGroupId, 'The UserOrGroupId should match the Division Leader');

        List<ContactShare> shares = [SELECT Id, ContactId, UserOrGroupId FROM ContactShare WHERE ContactId = :contact.Id];
        Assert.areEqual(1, shares.size(), 'Expected one ContactShare record to be created');
        Assert.areEqual(division.Division_Leader__c, shares[0].UserOrGroupId, 'The UserOrGroupId should match the Division Leader');
    }

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