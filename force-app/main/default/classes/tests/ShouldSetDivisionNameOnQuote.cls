@isTest
class ShouldSetDivisionNameOnQuote {

  @isTest
  static void testSetDivisionName() {
    System.debug('PARSE_DEBUG_START: Starting testSetDivsisionName');
    Test.startTest();
    SBQQ__Quote__c quote = [
      SELECT Division_Name__c
      FROM SBQQ__Quote__c
      LIMIT 1
    ];
    System.debug('PARSE_DEBUG_START: Fetched quote: ' + quote);
    System.assertEquals('Test Division', quote.Division_Name__c);
    Test.stopTest();
    System.debug('PARSE_DEBUG_END: Finished testSetDivisionName');
  }

  @TestSetup
  static void setupTestData() {
    Division__c division = new Division__c(Name = 'Test Division');
    insert division;
    Account testAccount = new Account(Name = 'Test Account');
    insert testAccount;
    Opportunity opp = new Opportunity(
      Name = 'Test Opportunity',
      AccountId = testAccount.Id,
      Division__c = division.Id,
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      Lead_Type__c = 'Slate - CGI'
    );
    insert opp;
  }
}
