@isTest
public with sharing class SetsDivisionNameOnNewOppTest {
  @isTest
  static void given() {
    oneOpportunityWithDivisionNameSetToSlate();
  }

  static void oneOpportunityWithDivisionNameSetToSlate() {
    Assert.areEqual(
      1,
      [SELECT COUNT() FROM Opportunity WHERE Division_Name__c = 'Slate']
    );
  }

  @TestSetup
  static void setupTestData() {
    // Create test Divisions
    List<Division__c> divisions = new List<Division__c>{
      new Division__c(Name = 'Slate')
    };
    insert divisions;

    // Create test Account
    Account testAccount = new Account(Name = 'Test Account');
    insert testAccount;

    // Create test Opportunity
    Opportunity testOpportunity = new Opportunity(
      Name = 'Test Opportunity ' + divisions[0].Name,
      AccountId = testAccount.Id,
      Division__c = divisions[0].Id,
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      Lead_Type__c = 'Slate - CGI'
    );
    insert testOpportunity;
  }
}
