@isTest
public class AccountPrimaryContactBatchTest {
  @isTest
  static void testBatchProcessing() {
    // Create test data
    List<Account> testAccounts = new List<Account>();
    for (Integer i = 0; i < 10; i++) {
      testAccounts.add(new Account(Name = 'Test Account ' + i));
    }
    insert testAccounts;

    // Create contacts
    List<Contact> testContacts = new List<Contact>();
    for (Integer i = 0; i < 10; i++) {
      testContacts.add(
        new Contact(
          FirstName = 'Test',
          LastName = 'Contact ' + i,
          AccountId = testAccounts[i].Id,
          Email = 'test' + i + '@test.com'
        )
      );
    }
    insert testContacts;

    // Create a Division for Opportunities
    Division__c testDivision = new Division__c(Name = 'Test Division');
    insert testDivision;

    // Create Opportunities with Primary Contacts for half the accounts
    List<Opportunity> testOpportunities = new List<Opportunity>();
    for (Integer i = 0; i < 5; i++) {
      testOpportunities.add(
        new Opportunity(
          Name = 'Test Opportunity ' + i,
          AccountId = testAccounts[i].Id,
          StageName = 'Prospecting',
          Lead_Type__c = 'Slate - CGI',
          CloseDate = Date.today().addDays(30),
          PrimaryContact__c = testContacts[i].Id,
          Division__c = testDivision.Id
        )
      );
    }

    // Create multiple Opportunities for the first account to test most recent logic
    Contact secondContactForFirstAccount = new Contact(
      FirstName = 'Second',
      LastName = 'Contact',
      AccountId = testAccounts[0].Id,
      Email = 'second@test.com'
    );
    insert secondContactForFirstAccount;

    testOpportunities.add(
      new Opportunity(
        Name = 'Most Recent Test Opp',
        AccountId = testAccounts[0].Id,
        StageName = 'Prospecting',
        Lead_Type__c = 'Motion',
        CloseDate = Date.today().addDays(30),
        PrimaryContact__c = secondContactForFirstAccount.Id,
        Division__c = testDivision.Id
      )
    );

    insert testOpportunities;

    // null the primary contact on all accounts
    for (Account acc : testAccounts) {
      acc.Contact__c = null;
    }
    update testAccounts;

    // Verify initial state - all accounts should have null Contact__c
    for (Account acc : [
      SELECT Id, Contact__c
      FROM Account
      WHERE Id IN :testAccounts
    ]) {
      System.assertEquals(
        null,
        acc.Contact__c,
        'Account should not have a primary contact initially'
      );
    }

    // Execute the batch
    Test.startTest();
    AccountPrimaryContactBatch batchJob = new AccountPrimaryContactBatch();
    Id batchJobId = Database.executeBatch(batchJob);
    Test.stopTest();

    // Verify results
    List<Account> updatedAccounts = [
      SELECT Id, Contact__c
      FROM Account
      WHERE Id IN :testAccounts
    ];

    // Accounts 0-4 should have primary contacts set
    Map<Id, Account> accountById = new Map<Id, Account>(updatedAccounts);
    for (Integer i = 0; i < 5; i++) {
      Account acc = accountById.get(testAccounts[i].Id);
      if (i == 0) {
        // First account should have the most recent opportunity's contact
        System.assertEquals(
          secondContactForFirstAccount.Id,
          acc.Contact__c,
          'First account should have most recent opportunity contact'
        );
      } else {
        System.assertEquals(
          testContacts[i].Id,
          acc.Contact__c,
          'Account ' + i + ' should have primary contact set from opportunity'
        );
      }
    }

    // Accounts 5-9 should still have null primary contacts (no opportunities)
    for (Integer i = 5; i < 10; i++) {
      Account acc = accountById.get(testAccounts[i].Id);
      System.assertEquals(
        null,
        acc.Contact__c,
        'Account ' + i + ' should not have primary contact (no opportunities)'
      );
    }
  }

  @isTest
  static void testEmptyBatch() {
    // Test empty batch execution
    Test.startTest();
    AccountPrimaryContactBatch batchJob = new AccountPrimaryContactBatch();
    Id batchJobId = Database.executeBatch(batchJob);
    Test.stopTest();

    // No errors should occur
    AsyncApexJob job = [
      SELECT Id, Status, NumberOfErrors
      FROM AsyncApexJob
      WHERE Id = :batchJobId
    ];
    System.assertEquals(
      0,
      job.NumberOfErrors,
      'Empty batch should complete without errors'
    );
  }
}
