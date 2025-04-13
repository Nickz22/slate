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
  static void testSetRequiredDepositDefaults() {
    // Create test division for Slate
    Division__c division = new Division__c(Name = 'Slate');
    insert division;

    // Create test opportunity
    Opportunity opp = new Opportunity(
      Name = 'Test Opportunity',
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      Division__c = division.Id,
      Lead_Type__c = 'Slate - CGI'
    );

    // Execute test
    Test.startTest();
    insert opp;
    Test.stopTest();

    // Verify results
    Opportunity result = [
      SELECT Required_Deposit__c
      FROM Opportunity
      WHERE Id = :opp.Id
    ];
    Assert.areEqual(
      70.0,
      result.Required_Deposit__c,
      'Required deposit was not set correctly'
    );
  }

  @isTest
  static void testSetRequiredDepositDefaultsForMultipleDivisions() {
    // Create test divisions
    Division__c slateDiv = new Division__c(Name = 'Slate');
    Division__c alignDiv = new Division__c(Name = 'Align');
    Division__c palermoDiv = new Division__c(Name = 'Palermo');
    insert new List<Division__c>{ slateDiv, alignDiv, palermoDiv };

    // Create test opportunities
    List<Opportunity> opps = new List<Opportunity>{
      new Opportunity(
        Name = 'Slate Opportunity',
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(30),
        Lead_Type__c = 'Slate - CGI',
        Division__c = slateDiv.Id
      ),
      new Opportunity(
        Name = 'Align Opportunity',
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(30),
        Lead_Type__c = 'Retouching - Align',
        Division__c = alignDiv.Id
      ),
      new Opportunity(
        Name = 'Palermo Opportunity',
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(30),
        Lead_Type__c = 'Palermo - Branding',
        Division__c = palermoDiv.Id
      )
    };

    // Execute test
    Test.startTest();
    insert opps;
    Test.stopTest();

    // Verify results
    List<Opportunity> results = [
      SELECT Name, Required_Deposit__c
      FROM Opportunity
      WHERE Id IN :opps
      ORDER BY Name
    ];

    Assert.areEqual(3, results.size(), 'Should have 3 opportunities');
    Assert.areEqual(
      0.0,
      results[0].Required_Deposit__c,
      'Align deposit should be 0.0'
    );
    Assert.areEqual(
      70.0,
      results[1].Required_Deposit__c,
      'Palermo deposit should be 70.0'
    );
    Assert.areEqual(
      70.0,
      results[2].Required_Deposit__c,
      'Slate deposit should be 70.0'
    );
  }
}
