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

  @isTest
  static void testInvoiceDueDateCalculation() {
    // Create test accounts with different payment terms
    List<Account> testAccounts = new List<Account>{
      new Account(Name = 'Test Account Net 15', Payment_Terms__c = 'Net 15'),
      new Account(Name = 'Test Account Net 30', Payment_Terms__c = 'Net 30'),
      new Account(Name = 'Test Account Net 45', Payment_Terms__c = 'Net 45'),
      new Account(Name = 'Test Account Net 60', Payment_Terms__c = 'Net 60'),
      new Account(Name = 'Test Account No Terms', Payment_Terms__c = null)
    };

    Database.DMLOptions dmlOpts = new Database.DMLOptions();
    dmlOpts.DuplicateRuleHeader.AllowSave = true;
    dmlOpts.DuplicateRuleHeader.RunAsCurrentUser = true;
    Database.insert(testAccounts, dmlOpts);

    Division__c division = new Division__c(
      Name = 'Slate',
      Division_Leader__c = UserInfo.getUserId()
    );
    insert division;

    // Create opportunities linked to these accounts
    Date closeDate = Date.today();
    List<Opportunity> testOpps = new List<Opportunity>();

    for (Account acc : testAccounts) {
      testOpps.add(
        new Opportunity(
          Name = 'Test Opp for ' + acc.Name,
          AccountId = acc.Id,
          StageName = 'Proposal',
          CloseDate = closeDate,
          Division__c = division.Id,
          Lead_Type__c = 'Slate - CGI'
        )
      );
    }

    insert testOpps;

    // Get the opportunities before the update
    Map<Id, Opportunity> oldOpps = new Map<Id, Opportunity>(
      [
        SELECT Id, StageName, CloseDate, Invoice_Due_Date__c
        FROM Opportunity
        WHERE Id IN :testOpps
      ]
    );

    // Update the opportunities to Closed Won
    for (Opportunity opp : testOpps) {
      opp.StageName = 'Closed Won';
    }

    // Call the method being tested
    Test.startTest();
    OpportunityTriggerHandler.onBeforeUpdate(oldOpps, testOpps);
    Test.stopTest();

    // Verify the invoice due dates are set correctly
    for (Opportunity opp : testOpps) {
      Account relatedAccount = null;
      for (Account acc : testAccounts) {
        if (acc.Id == opp.AccountId) {
          relatedAccount = acc;
          break;
        }
      }

      if (relatedAccount.Payment_Terms__c == 'Net 15') {
        Assert.areEqual(
          closeDate.addDays(15),
          opp.Invoice_Due_Date__c,
          'Invoice due date should be 15 days after close date for Net 15'
        );
      } else if (relatedAccount.Payment_Terms__c == 'Net 30') {
        Assert.areEqual(
          closeDate.addDays(30),
          opp.Invoice_Due_Date__c,
          'Invoice due date should be 30 days after close date for Net 30'
        );
      } else if (relatedAccount.Payment_Terms__c == 'Net 45') {
        Assert.areEqual(
          closeDate.addDays(45),
          opp.Invoice_Due_Date__c,
          'Invoice due date should be 45 days after close date for Net 45'
        );
      } else if (relatedAccount.Payment_Terms__c == 'Net 60') {
        Assert.areEqual(
          closeDate.addDays(60),
          opp.Invoice_Due_Date__c,
          'Invoice due date should be 60 days after close date for Net 60'
        );
      } else {
        Assert.areEqual(
          closeDate,
          opp.Invoice_Due_Date__c,
          'Invoice due date should be the same as close date when no payment terms'
        );
      }
    }
  }

  @isTest
  static void shouldCreateSlateCcFeeAsQuoteLineItemWhenCcFeeIsChecked() {
    // Disable auto quote generation to control the process
    OpportunityTriggerHandler.autoGenerateQuote = false;

    // Get the test data
    Division__c division = [
      SELECT Id, Name
      FROM Division__c
      WHERE Name = 'Slate'
      LIMIT 1
    ];
    Account account = [
      SELECT Id
      FROM Account
      WHERE Name = 'Test Account'
      LIMIT 1
    ];
    Contact contact = [
      SELECT Id
      FROM Contact
      WHERE LastName = 'Contact'
      LIMIT 1
    ];

    // Create opportunity without CC payment initially
    Opportunity opp = new Opportunity(
      Name = 'Test Opportunity',
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      AccountId = account.Id,
      Division__c = division.Id,
      PrimaryContact__c = contact.Id,
      Amount = 1000,
      CC_Payment__c = false,
      Required_Deposit__c = 50 // 50% deposit
    );
    insert opp;

    // Create a quote for this opportunity
    Id pricebookId = Test.getStandardPricebookId();
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      SBQQ__Opportunity2__c = opp.Id,
      SBQQ__Account__c = account.Id,
      SBQQ__Primary__c = true,
      SBQQ__Status__c = 'Draft',
      SBQQ__PricebookId__c = pricebookId
    );
    insert quote;

    Test.startTest();
    // Now update the opportunity to have CC_Payment__c = true
    opp.CC_Payment__c = true;
    update opp;
    Test.stopTest();

    // Verify a QLI for CC Fee was created
    List<SBQQ__QuoteLine__c> quoteLines = [
      SELECT
        Id,
        SBQQ__Product__r.Name,
        SBQQ__CustomerPrice__c,
        SBQQ__ListPrice__c,
        SBQQ__UnitCost__c,
        SBQQ__Quantity__c,
        SBQQ__Description__c
      FROM SBQQ__QuoteLine__c
      WHERE
        SBQQ__Quote__c = :quote.Id
        AND SBQQ__Product__r.Name = 'CC Processing Fee'
    ];

    System.assertEquals(
      1,
      quoteLines.size(),
      'Expected a CC Fee quote line to be created'
    );
    System.assertEquals(
      45.0,
      quoteLines[0].SBQQ__CustomerPrice__c,
      'Expected CC Fee to be 4.5% of 1000 = 45'
    );
    System.assertEquals(
      45.0,
      quoteLines[0].SBQQ__ListPrice__c,
      'Expected ListPrice to equal CustomerPrice'
    );
    System.assertEquals(
      30.0,
      quoteLines[0].SBQQ__UnitCost__c,
      'Expected UnitCost to be 3% of 1000 = 30'
    );
    System.assertEquals(
      1,
      quoteLines[0].SBQQ__Quantity__c,
      'Expected Quantity to be 1'
    );
    System.assertEquals(
      'Credit Card Processing Fee',
      quoteLines[0].SBQQ__Description__c,
      'Expected Description to be Credit Card Processing Fee'
    );
  }

  @isTest
  static void shouldUpdateSlateCcFeeAmountWhenOpportunityAmountChanges() {
    // Disable auto quote generation to control the process
    OpportunityTriggerHandler.autoGenerateQuote = false;

    // Get the test data
    Division__c division = [
      SELECT Id, Name
      FROM Division__c
      WHERE Name = 'Slate'
      LIMIT 1
    ];
    Account account = [
      SELECT Id
      FROM Account
      WHERE Name = 'Test Account'
      LIMIT 1
    ];
    Contact contact = [
      SELECT Id
      FROM Contact
      WHERE LastName = 'Contact'
      LIMIT 1
    ];

    // Create opportunity with CC payment
    Opportunity opp = new Opportunity(
      Name = 'Test Opportunity',
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      AccountId = account.Id,
      Division__c = division.Id,
      PrimaryContact__c = contact.Id,
      Amount = 1000,
      CC_Payment__c = true,
      Required_Deposit__c = 50 // 50% deposit
    );
    insert opp;

    // Create a quote for this opportunity
    Id pricebookId = Test.getStandardPricebookId();
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      SBQQ__Opportunity2__c = opp.Id,
      SBQQ__Account__c = account.Id,
      SBQQ__Primary__c = true,
      SBQQ__Status__c = 'Draft',
      SBQQ__PricebookId__c = pricebookId
    );
    insert quote;

    // Trigger creation of initial CC fee line
    opp.Amount = 1000;
    update opp;

    Test.startTest();
    // Now update the opportunity amount
    opp.Amount = 2000;
    update opp;
    Test.stopTest();

    // Verify the QLI for CC Fee was updated
    List<SBQQ__QuoteLine__c> quoteLines = [
      SELECT
        Id,
        SBQQ__Product__r.Name,
        SBQQ__CustomerPrice__c,
        SBQQ__ListPrice__c,
        SBQQ__UnitCost__c,
        SBQQ__Quantity__c,
        SBQQ__Description__c
      FROM SBQQ__QuoteLine__c
      WHERE
        SBQQ__Quote__c = :quote.Id
        AND SBQQ__Product__r.Name = 'CC Processing Fee'
    ];

    System.assertEquals(
      1,
      quoteLines.size(),
      'Expected a CC Fee quote line to exist'
    );
    System.assertEquals(
      90.0,
      quoteLines[0].SBQQ__CustomerPrice__c,
      'Expected CC Fee to be updated to 4.5% of 2000 = 90'
    );
    System.assertEquals(
      90.0,
      quoteLines[0].SBQQ__ListPrice__c,
      'Expected ListPrice to be updated to 4.5% of 2000 = 90'
    );
    System.assertEquals(
      60.0,
      quoteLines[0].SBQQ__UnitCost__c,
      'Expected UnitCost to be updated to 3% of 2000 = 60'
    );
    System.assertEquals(
      1,
      quoteLines[0].SBQQ__Quantity__c,
      'Expected Quantity to be 1'
    );
    System.assertEquals(
      'Credit Card Processing Fee',
      quoteLines[0].SBQQ__Description__c,
      'Expected Description to be Credit Card Processing Fee'
    );
  }

  @isTest
  static void shouldRemoveSlateCcFeeAsQuoteLineItemWhenCcFeeIsUnchecked() {
    // Disable auto quote generation to control the process
    OpportunityTriggerHandler.autoGenerateQuote = false;

    // Get the test data
    Division__c division = [
      SELECT Id, Name
      FROM Division__c
      WHERE Name = 'Slate'
      LIMIT 1
    ];
    Account account = [
      SELECT Id
      FROM Account
      WHERE Name = 'Test Account'
      LIMIT 1
    ];
    Contact contact = [
      SELECT Id
      FROM Contact
      WHERE LastName = 'Contact'
      LIMIT 1
    ];

    // Create opportunity with CC payment
    Opportunity opp = new Opportunity(
      Name = 'Test Opportunity',
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      AccountId = account.Id,
      Division__c = division.Id,
      PrimaryContact__c = contact.Id,
      Amount = 1000,
      CC_Payment__c = true,
      Required_Deposit__c = 50 // 50% deposit
    );
    insert opp;

    // Create a quote for this opportunity
    Id pricebookId = Test.getStandardPricebookId();
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      SBQQ__Opportunity2__c = opp.Id,
      SBQQ__Account__c = account.Id,
      SBQQ__Primary__c = true,
      SBQQ__Status__c = 'Draft',
      SBQQ__PricebookId__c = pricebookId
    );
    insert quote;

    // Get the CC product Id
    Product2 ccProduct = [
      SELECT Id
      FROM Product2
      WHERE Name = 'CC Processing Fee'
      LIMIT 1
    ];

    // Create CC fee line item
    SBQQ__QuoteLine__c ccFeeLine = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c = quote.Id,
      SBQQ__Product__c = ccProduct.Id,
      SBQQ__Quantity__c = 1,
      SBQQ__CustomerPrice__c = 30.0
    );
    insert ccFeeLine;

    Test.startTest();
    // Now uncheck the CC Payment checkbox
    opp.CC_Payment__c = false;
    update opp;
    Test.stopTest();

    // Verify the QLI for CC Fee was deleted
    List<SBQQ__QuoteLine__c> quoteLines = [
      SELECT Id
      FROM SBQQ__QuoteLine__c
      WHERE
        SBQQ__Quote__c = :quote.Id
        AND SBQQ__Product__r.Name = 'CC Processing Fee'
    ];

    System.assertEquals(
      0,
      quoteLines.size(),
      'Expected CC Fee quote line to be deleted'
    );
  }

  @isTest
  static void shouldCreateAlignCcFeeAsQuoteLineItemWhenCcFeeIsChecked() {
    OpportunityTriggerHandler.autoGenerateQuote = false;
    Division__c division = [
      SELECT Id, Name
      FROM Division__c
      WHERE Name = 'Align'
      LIMIT 1
    ];
    Account account = [
      SELECT Id
      FROM Account
      WHERE Name = 'Test Account'
      LIMIT 1
    ];
    Contact contact = [
      SELECT Id
      FROM Contact
      WHERE LastName = 'Contact'
      LIMIT 1
    ];

    Opportunity opp = new Opportunity(
      Name = 'Test Opportunity',
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      AccountId = account.Id,
      Division__c = division.Id,
      PrimaryContact__c = contact.Id,
      Amount = 1000,
      CC_Payment__c = false,
      Required_Deposit__c = 50
    );
    insert opp;

    Id pricebookId = Test.getStandardPricebookId();
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      SBQQ__Opportunity2__c = opp.Id,
      SBQQ__Account__c = account.Id,
      SBQQ__Primary__c = true,
      SBQQ__Status__c = 'Draft',
      SBQQ__PricebookId__c = pricebookId
    );
    insert quote;

    Test.startTest();
    opp.CC_Payment__c = true;
    update opp;
    Test.stopTest();

    List<SBQQ__QuoteLine__c> quoteLines = [
      SELECT
        Id,
        SBQQ__Product__r.Name,
        SBQQ__CustomerPrice__c,
        SBQQ__ListPrice__c,
        SBQQ__UnitCost__c,
        SBQQ__Quantity__c,
        SBQQ__Description__c
      FROM SBQQ__QuoteLine__c
      WHERE
        SBQQ__Quote__c = :quote.Id
        AND SBQQ__Product__r.Name = 'CC Processing Fee'
    ];

    System.assertEquals(
      1,
      quoteLines.size(),
      'Expected a CC Fee quote line to be created for Align division'
    );
    System.assertEquals(
      45.0,
      quoteLines[0].SBQQ__CustomerPrice__c,
      'Expected CC Fee to be 4.5% of 1000 = 45'
    );
    System.assertEquals(
      45.0,
      quoteLines[0].SBQQ__ListPrice__c,
      'Expected ListPrice to equal CustomerPrice'
    );
    System.assertEquals(
      30.0,
      quoteLines[0].SBQQ__UnitCost__c,
      'Expected UnitCost to be 3% of 1000 = 30'
    );
    System.assertEquals(
      1,
      quoteLines[0].SBQQ__Quantity__c,
      'Expected Quantity to be 1'
    );
    System.assertEquals(
      'Credit Card Processing Fee',
      quoteLines[0].SBQQ__Description__c,
      'Expected Description to be Credit Card Processing Fee'
    );
  }

  @isTest
  static void shouldUpdateAlignCcFeeAmountWhenOpportunityAmountChanges() {
    OpportunityTriggerHandler.autoGenerateQuote = false;
    Division__c division = [
      SELECT Id, Name
      FROM Division__c
      WHERE Name = 'Align'
      LIMIT 1
    ];
    Account account = [
      SELECT Id
      FROM Account
      WHERE Name = 'Test Account'
      LIMIT 1
    ];
    Contact contact = [
      SELECT Id
      FROM Contact
      WHERE LastName = 'Contact'
      LIMIT 1
    ];

    Opportunity opp = new Opportunity(
      Name = 'Test Opportunity',
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      AccountId = account.Id,
      Division__c = division.Id,
      PrimaryContact__c = contact.Id,
      Amount = 1000,
      CC_Payment__c = true,
      Required_Deposit__c = 50
    );
    insert opp;

    Id pricebookId = Test.getStandardPricebookId();
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      SBQQ__Opportunity2__c = opp.Id,
      SBQQ__Account__c = account.Id,
      SBQQ__Primary__c = true,
      SBQQ__Status__c = 'Draft',
      SBQQ__PricebookId__c = pricebookId
    );
    insert quote;

    opp.Amount = 1000;
    update opp;

    Test.startTest();
    opp.Amount = 2000;
    update opp;
    Test.stopTest();

    List<SBQQ__QuoteLine__c> quoteLines = [
      SELECT
        Id,
        SBQQ__Product__r.Name,
        SBQQ__CustomerPrice__c,
        SBQQ__ListPrice__c,
        SBQQ__UnitCost__c,
        SBQQ__Quantity__c,
        SBQQ__Description__c
      FROM SBQQ__QuoteLine__c
      WHERE
        SBQQ__Quote__c = :quote.Id
        AND SBQQ__Product__r.Name = 'CC Processing Fee'
    ];

    System.assertEquals(
      1,
      quoteLines.size(),
      'Expected a CC Fee quote line to be updated for Align division'
    );
    System.assertEquals(
      90.0,
      quoteLines[0].SBQQ__CustomerPrice__c,
      'Expected CC Fee to be updated to 4.5% of 2000 = 90'
    );
    System.assertEquals(
      90.0,
      quoteLines[0].SBQQ__ListPrice__c,
      'Expected ListPrice to be updated to 4.5% of 2000 = 90'
    );
    System.assertEquals(
      60.0,
      quoteLines[0].SBQQ__UnitCost__c,
      'Expected UnitCost to be updated to 3% of 2000 = 60'
    );
    System.assertEquals(
      1,
      quoteLines[0].SBQQ__Quantity__c,
      'Expected Quantity to be 1'
    );
    System.assertEquals(
      'Credit Card Processing Fee',
      quoteLines[0].SBQQ__Description__c,
      'Expected Description to be Credit Card Processing Fee'
    );
  }

  @isTest
  static void shouldRemoveAlignCcFeeAsQuoteLineItemWhenCcFeeIsUnchecked() {
    OpportunityTriggerHandler.autoGenerateQuote = false;
    Division__c division = [
      SELECT Id, Name
      FROM Division__c
      WHERE Name = 'Align'
      LIMIT 1
    ];
    Account account = [
      SELECT Id
      FROM Account
      WHERE Name = 'Test Account'
      LIMIT 1
    ];
    Contact contact = [
      SELECT Id
      FROM Contact
      WHERE LastName = 'Contact'
      LIMIT 1
    ];
    Opportunity opp = new Opportunity(
      Name = 'Test Opportunity',
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      AccountId = account.Id,
      Division__c = division.Id,
      PrimaryContact__c = contact.Id,
      Amount = 1000,
      CC_Payment__c = true,
      Required_Deposit__c = 50
    );
    insert opp;
    Id pricebookId = Test.getStandardPricebookId();
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      SBQQ__Opportunity2__c = opp.Id,
      SBQQ__Account__c = account.Id,
      SBQQ__Primary__c = true,
      SBQQ__Status__c = 'Draft',
      SBQQ__PricebookId__c = pricebookId
    );
    insert quote;
    Product2 ccProduct = [
      SELECT Id
      FROM Product2
      WHERE Name = 'CC Processing Fee'
      LIMIT 1
    ];
    SBQQ__QuoteLine__c ccFeeLine = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c = quote.Id,
      SBQQ__Product__c = ccProduct.Id,
      SBQQ__Quantity__c = 1,
      SBQQ__CustomerPrice__c = 30.0
    );
    insert ccFeeLine;
    Test.startTest();
    opp.CC_Payment__c = false;
    update opp;
    Test.stopTest();
    List<SBQQ__QuoteLine__c> quoteLines = [
      SELECT Id
      FROM SBQQ__QuoteLine__c
      WHERE
        SBQQ__Quote__c = :quote.Id
        AND SBQQ__Product__r.Name = 'CC Processing Fee'
    ];
    System.assertEquals(
      0,
      quoteLines.size(),
      'Expected CC Fee quote line to be deleted for Align division'
    );
  }

  @isTest
  static void shouldCreatePalermoCcFeeAsQuoteLineItemWhenCcFeeIsChecked() {
    OpportunityTriggerHandler.autoGenerateQuote = false;
    Division__c division = [
      SELECT Id, Name
      FROM Division__c
      WHERE Name = 'Palermo'
      LIMIT 1
    ];
    Account account = [
      SELECT Id
      FROM Account
      WHERE Name = 'Test Account'
      LIMIT 1
    ];
    Contact contact = [
      SELECT Id
      FROM Contact
      WHERE LastName = 'Contact'
      LIMIT 1
    ];
    Opportunity opp = new Opportunity(
      Name = 'Test Opportunity',
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      AccountId = account.Id,
      Division__c = division.Id,
      PrimaryContact__c = contact.Id,
      Amount = 1000,
      CC_Payment__c = false,
      Required_Deposit__c = 50
    );
    insert opp;
    Id pricebookId = Test.getStandardPricebookId();
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      SBQQ__Opportunity2__c = opp.Id,
      SBQQ__Account__c = account.Id,
      SBQQ__Primary__c = true,
      SBQQ__Status__c = 'Draft',
      SBQQ__PricebookId__c = pricebookId
    );
    insert quote;
    Test.startTest();
    opp.CC_Payment__c = true;
    update opp;
    Test.stopTest();
    List<SBQQ__QuoteLine__c> quoteLines = [
      SELECT
        Id,
        SBQQ__Product__r.Name,
        SBQQ__CustomerPrice__c,
        SBQQ__ListPrice__c,
        SBQQ__UnitCost__c,
        SBQQ__Quantity__c,
        SBQQ__Description__c
      FROM SBQQ__QuoteLine__c
      WHERE
        SBQQ__Quote__c = :quote.Id
        AND SBQQ__Product__r.Name = 'CC Processing Fee'
    ];
    System.assertEquals(
      1,
      quoteLines.size(),
      'Expected a CC Fee quote line to be created for Palermo division'
    );
    System.assertEquals(
      45.0,
      quoteLines[0].SBQQ__CustomerPrice__c,
      'Expected CC Fee to be 4.5% of 1000 = 45'
    );
    System.assertEquals(
      45.0,
      quoteLines[0].SBQQ__ListPrice__c,
      'Expected ListPrice to equal CustomerPrice'
    );
    System.assertEquals(
      30.0,
      quoteLines[0].SBQQ__UnitCost__c,
      'Expected UnitCost to be 3% of 1000 = 30'
    );
    System.assertEquals(
      1,
      quoteLines[0].SBQQ__Quantity__c,
      'Expected Quantity to be 1'
    );
    System.assertEquals(
      'Credit Card Processing Fee',
      quoteLines[0].SBQQ__Description__c,
      'Expected Description to be Credit Card Processing Fee'
    );
  }

  @isTest
  static void shouldUpdatePalermoCcFeeAmountWhenOpportunityAmountChanges() {
    OpportunityTriggerHandler.autoGenerateQuote = false;
    Division__c division = [
      SELECT Id, Name
      FROM Division__c
      WHERE Name = 'Palermo'
      LIMIT 1
    ];
    Account account = [
      SELECT Id
      FROM Account
      WHERE Name = 'Test Account'
      LIMIT 1
    ];
    Contact contact = [
      SELECT Id
      FROM Contact
      WHERE LastName = 'Contact'
      LIMIT 1
    ];
    Opportunity opp = new Opportunity(
      Name = 'Test Opportunity',
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      AccountId = account.Id,
      Division__c = division.Id,
      PrimaryContact__c = contact.Id,
      Amount = 1000,
      CC_Payment__c = true,
      Required_Deposit__c = 50
    );
    insert opp;
    Id pricebookId = Test.getStandardPricebookId();
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      SBQQ__Opportunity2__c = opp.Id,
      SBQQ__Account__c = account.Id,
      SBQQ__Primary__c = true,
      SBQQ__Status__c = 'Draft',
      SBQQ__PricebookId__c = pricebookId
    );
    insert quote;
    opp.Amount = 1000;
    update opp;
    Test.startTest();
    opp.Amount = 2000;
    update opp;
    Test.stopTest();
    List<SBQQ__QuoteLine__c> quoteLines = [
      SELECT
        Id,
        SBQQ__Product__r.Name,
        SBQQ__CustomerPrice__c,
        SBQQ__ListPrice__c,
        SBQQ__UnitCost__c,
        SBQQ__Quantity__c,
        SBQQ__Description__c
      FROM SBQQ__QuoteLine__c
      WHERE
        SBQQ__Quote__c = :quote.Id
        AND SBQQ__Product__r.Name = 'CC Processing Fee'
    ];
    System.assertEquals(
      1,
      quoteLines.size(),
      'Expected a CC Fee quote line to be updated for Palermo division'
    );
    System.assertEquals(
      90.0,
      quoteLines[0].SBQQ__CustomerPrice__c,
      'Expected CC Fee to be updated to 4.5% of 2000 = 90'
    );
    System.assertEquals(
      90.0,
      quoteLines[0].SBQQ__ListPrice__c,
      'Expected ListPrice to be updated to 4.5% of 2000 = 90'
    );
    System.assertEquals(
      60.0,
      quoteLines[0].SBQQ__UnitCost__c,
      'Expected UnitCost to be updated to 3% of 2000 = 60'
    );
    System.assertEquals(
      1,
      quoteLines[0].SBQQ__Quantity__c,
      'Expected Quantity to be 1'
    );
    System.assertEquals(
      'Credit Card Processing Fee',
      quoteLines[0].SBQQ__Description__c,
      'Expected Description to be Credit Card Processing Fee'
    );
  }

  @isTest
  static void shouldRemovePalermoCcFeeAsQuoteLineItemWhenCcFeeIsUnchecked() {
    OpportunityTriggerHandler.autoGenerateQuote = false;
    Division__c division = [
      SELECT Id, Name
      FROM Division__c
      WHERE Name = 'Palermo'
      LIMIT 1
    ];
    Account account = [
      SELECT Id
      FROM Account
      WHERE Name = 'Test Account'
      LIMIT 1
    ];
    Contact contact = [
      SELECT Id
      FROM Contact
      WHERE LastName = 'Contact'
      LIMIT 1
    ];
    Opportunity opp = new Opportunity(
      Name = 'Test Opportunity',
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      AccountId = account.Id,
      Division__c = division.Id,
      PrimaryContact__c = contact.Id,
      Amount = 1000,
      CC_Payment__c = true,
      Required_Deposit__c = 50
    );
    insert opp;
    Id pricebookId = Test.getStandardPricebookId();
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      SBQQ__Opportunity2__c = opp.Id,
      SBQQ__Account__c = account.Id,
      SBQQ__Primary__c = true,
      SBQQ__Status__c = 'Draft',
      SBQQ__PricebookId__c = pricebookId
    );
    insert quote;
    Product2 ccProduct = [
      SELECT Id
      FROM Product2
      WHERE Name = 'CC Processing Fee'
      LIMIT 1
    ];
    SBQQ__QuoteLine__c ccFeeLine = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c = quote.Id,
      SBQQ__Product__c = ccProduct.Id,
      SBQQ__Quantity__c = 1,
      SBQQ__CustomerPrice__c = 30.0
    );
    insert ccFeeLine;
    Test.startTest();
    opp.CC_Payment__c = false;
    update opp;
    Test.stopTest();
    List<SBQQ__QuoteLine__c> quoteLines = [
      SELECT Id
      FROM SBQQ__QuoteLine__c
      WHERE
        SBQQ__Quote__c = :quote.Id
        AND SBQQ__Product__r.Name = 'CC Processing Fee'
    ];
    System.assertEquals(
      0,
      quoteLines.size(),
      'Expected CC Fee quote line to be deleted for Palermo division'
    );
  }

  @TestSetup
  static void setupTestData() {
    Division__c division = new Division__c(Name = 'Slate');
    insert division;

    Division__c alignDivision = new Division__c(Name = 'Align');
    insert alignDivision;

    Account account = new Account(
      Name = 'Test Account',
      Payment_Terms__c = 'Net 30'
    );
    insert account;

    Product2 ccProduct = new Product2(
      Name = 'CC Processing Fee',
      ProductCode = 'SLATE_0076',
      IsActive = true
    );
    insert ccProduct;

    Product2 alignProduct = new Product2(
      Name = 'CC Processing Fee',
      ProductCode = 'ALIGN_0076',
      IsActive = true
    );
    insert alignProduct;

    // Create a price book entry for the CC Fee product
    Id standardPriceBookId = Test.getStandardPricebookId();
    PricebookEntry pbe = new PricebookEntry(
      Pricebook2Id = standardPriceBookId,
      Product2Id = ccProduct.Id,
      UnitPrice = 0,
      IsActive = true
    );
    insert pbe;

    PricebookEntry alignPbe = new PricebookEntry(
      Pricebook2Id = standardPriceBookId,
      Product2Id = alignProduct.Id,
      UnitPrice = 0,
      IsActive = true
    );
    insert alignPbe;

    Division__c palermoDivision = new Division__c(Name = 'Palermo');
    insert palermoDivision;
    Product2 palermoProduct = new Product2(
      Name = 'CC Processing Fee',
      ProductCode = 'PALERMO_0076',
      IsActive = true
    );
    insert palermoProduct;
    PricebookEntry palermoPbe = new PricebookEntry(
      Pricebook2Id = standardPriceBookId,
      Product2Id = palermoProduct.Id,
      UnitPrice = 0,
      IsActive = true
    );
    insert palermoPbe;

    Contact contact = new Contact(
      FirstName = 'Test',
      LastName = 'Contact',
      Email = 'test@example.com',
      AccountId = account.Id
    );
    insert contact;
  }
}
