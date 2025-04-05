@isTest
public with sharing class OpportunityTriggerHandlerTest {
  @isTest
  static void testSetOppName() {
    // Get the current date in YYMMDD format
    String currentDate = System.now().format('YYMMdd');

    // Test case 1: Brand Content
    String result1 = OpportunityTriggerHandler.setOppName(
      'Brand Content',
      'Acme Corp'
    );
    Assert.isTrue(
      result1.startsWith(currentDate + '_ACMECORP_BC'),
      'Brand Content test failed'
    );

    // Test case 2: Studio Rental
    String result2 = OpportunityTriggerHandler.setOppName(
      'Studio Rental',
      'Wayne Enterprises'
    );
    Assert.isTrue(
      result2.startsWith(currentDate + '_WAYNEENTERPRISES_SR'),
      'Studio Rental test failed'
    );

    // Test case 3: Motion
    String result3 = OpportunityTriggerHandler.setOppName(
      'Motion',
      'Stark Industries'
    );
    Assert.isTrue(
      result3.startsWith(currentDate + '_STARKINDUSTRIES_MT'),
      'Motion test failed'
    );

    // Test case 4: Retouching
    String result4 = OpportunityTriggerHandler.setOppName(
      'Retouching',
      'Daily Planet'
    );
    Assert.isTrue(
      result4.startsWith(currentDate + '_DAILYPLANET_RT'),
      'Retouching test failed'
    );

    // Test case 5: Casablanca - Motion Production
    String result5 = OpportunityTriggerHandler.setOppName(
      'Casablanca - Motion Production',
      'Oscorp'
    );
    Assert.isTrue(
      result5.startsWith(currentDate + '_OSCORP_CMP'),
      'Casablanca - Motion Production test failed'
    );

    // Test case 6: Palermo - Digital/UX
    String result6 = OpportunityTriggerHandler.setOppName(
      'Palermo - Digital/UX',
      'Umbrella Corp'
    );
    Assert.isTrue(
      result6.startsWith(currentDate + '_UMBRELLACORP_UX'),
      'Palermo - Digital/UX test failed'
    );

    // Test case 7: Align - CGI
    String result7 = OpportunityTriggerHandler.setOppName(
      'Align - CGI',
      'Cyberdyne Systems'
    );
    Assert.isTrue(
      result7.startsWith(currentDate + '_CYBERDYNESYSTEMS_CG'),
      'Align - CGI test failed'
    );

    // Test case 8: Default case (should return EC)
    String result8 = OpportunityTriggerHandler.setOppName(
      'Some Random Type',
      'Acme Corp'
    );
    Assert.isTrue(
      result8.startsWith(currentDate + '_ACMECORP_EC'),
      'Default case test failed'
    );
  }

  @isTest
  static void testAccountPrimaryContactUpdate() {
    // Create test data
    Account testAccount = new Account(Name = 'Test Account');
    insert testAccount;

    Contact testContact = new Contact(
      FirstName = 'Test',
      LastName = 'Contact',
      AccountId = testAccount.Id,
      Email = 'test@test.com'
    );
    insert testContact;

    // Verify Account has no primary contact initially
    testAccount = [
      SELECT Id, Contact__c
      FROM Account
      WHERE Id = :testAccount.Id
    ];
    Assert.isNull(
      testAccount.Contact__c,
      'Account should not have a primary contact initially'
    );

    Division__c testDivision = new Division__c(Name = 'Slate');
    insert testDivision;

    // Create Opportunity with Primary Contact
    Opportunity testOpp = new Opportunity(
      Name = 'Test Opportunity',
      AccountId = testAccount.Id,
      StageName = 'Prospecting',
      Lead_Type__c = 'Slate - CGI',
      CloseDate = Date.today().addDays(30),
      PrimaryContact__c = testContact.Id,
      Division__c = testDivision.Id
    );

    // Test insert trigger functionality
    Test.startTest();
    insert testOpp;
    Test.stopTest();

    // Verify Account primary contact was updated
    testAccount = [
      SELECT Id, Contact__c
      FROM Account
      WHERE Id = :testAccount.Id
    ];
    Assert.areEqual(
      testContact.Id,
      testAccount.Contact__c,
      'Account primary contact should be updated after Opportunity insert'
    );

    // Create a new contact
    Contact newContact = new Contact(
      FirstName = 'New',
      LastName = 'Contact',
      Email = 'new@test.com',
      AccountId = testAccount.Id
    );
    insert newContact;

    // Update opportunity primary contact
    testOpp.PrimaryContact__c = newContact.Id;
    update testOpp;

    // Verify Account primary contact remains unchanged since it's already populated
    testAccount = [
      SELECT Id, Contact__c
      FROM Account
      WHERE Id = :testAccount.Id
    ];
    Assert.areEqual(
      testContact.Id,
      testAccount.Contact__c,
      'Account primary contact should not change when already populated'
    );
  }

  @isTest
  static void testOpportunityInsert() {
    // Create test data
    Account testAccount = new Account(Name = 'New Test Account');
    insert testAccount;

    Contact testContact = new Contact(
      FirstName = 'New Test',
      LastName = 'Contact',
      AccountId = testAccount.Id,
      Email = 'newtest@test.com'
    );
    insert testContact;

    Division__c testDivision = new Division__c(Name = 'Slate Division');
    insert testDivision;

    // Test insert with primary contact set
    Test.startTest();

    Opportunity newOpp = new Opportunity(
      Name = 'New Opportunity',
      AccountId = testAccount.Id,
      StageName = 'Prospecting',
      Lead_Type__c = 'Slate - CGI',
      CloseDate = Date.today().addDays(30),
      PrimaryContact__c = testContact.Id,
      Division__c = testDivision.Id
    );

    insert newOpp;

    // Verify the opportunity was inserted and Account primary contact was updated
    Opportunity insertedOpp = [
      SELECT Id, PrimaryContact__c, AccountId
      FROM Opportunity
      WHERE Id = :newOpp.Id
    ];
    Assert.areEqual(
      testContact.Id,
      insertedOpp.PrimaryContact__c,
      'Opportunity primary contact should be set correctly'
    );

    Account updatedAccount = [
      SELECT Id, Contact__c
      FROM Account
      WHERE Id = :testAccount.Id
    ];
    Assert.areEqual(
      testContact.Id,
      updatedAccount.Contact__c,
      'Account primary contact should be updated from new opportunity'
    );

    // Test a second opportunity for the same account with a different contact
    Contact secondContact = new Contact(
      FirstName = 'Second',
      LastName = 'Contact',
      AccountId = testAccount.Id,
      Email = 'second@test.com'
    );
    insert secondContact;

    Opportunity secondOpp = new Opportunity(
      Name = 'Second Opportunity',
      AccountId = testAccount.Id,
      StageName = 'Prospecting',
      Lead_Type__c = 'Motion',
      CloseDate = Date.today().addDays(45),
      PrimaryContact__c = secondContact.Id,
      Division__c = testDivision.Id
    );

    insert secondOpp;

    Test.stopTest();

    // Verify second opportunity was inserted but Account primary contact remains the same
    Account accountAfterSecondOpp = [
      SELECT Id, Contact__c
      FROM Account
      WHERE Id = :testAccount.Id
    ];
    Assert.areEqual(
      testContact.Id,
      accountAfterSecondOpp.Contact__c,
      'Account primary contact should not change when already populated'
    );
  }
}
