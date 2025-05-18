@isTest
private class PandaDocQuoteControllerTest {
  @TestSetup
  static void setupTestData() {
    User u = new User(
      Id = UserInfo.getUserId(),
      Email = 'test@slate.com',
      Username = 'test@slate.com'
    );
    update u;

    System.runAs(u) {
      // Create test Divisions
      List<Division__c> divisions = new List<Division__c>{
        new Division__c(Name = 'Slate'),
        new Division__c(Name = 'Palermo'),
        new Division__c(Name = 'Align')
      };
      insert divisions;

      // Create test Accounts
      List<Account> accounts = new List<Account>();
      for (Integer i = 0; i < 3; i++) {
        accounts.add(
          new Account(Name = 'Test Account ' + i, Payment_Terms__c = 'Net 30')
        );
      }
      insert accounts;

      // Create test Contacts
      List<Contact> contacts = new List<Contact>();
      for (Integer i = 0; i < 3; i++) {
        contacts.add(
          new Contact(
            FirstName = 'Test',
            LastName = 'Contact ' + i,
            AccountId = accounts[i].Id,
            Email = 'test' + i + '@example.com'
          )
        );
      }
      insert contacts;

      // Create test Opportunities
      List<Opportunity> opportunities = new List<Opportunity>();
      for (Integer i = 0; i < 3; i++) {
        opportunities.add(
          new Opportunity(
            Name = 'Test Opportunity ' + divisions[i].Name,
            AccountId = accounts[i].Id,
            PrimaryContact__c = contacts[i].Id,
            Division__c = divisions[i].Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 1000,
            Lead_Type__c = 'Slate - CGI'
          )
        );
      }
      insert opportunities;
      //insert quote
      SBQQ__Quote__c quote = new SBQQ__Quote__c(
        SBQQ__Opportunity2__c = opportunities[0].Id,
        SBQQ__Primary__c = true
      );
      insert quote;
      Id pricebookId = Test.getStandardPricebookId();
      Pricebook2 standardPricebook = new Pricebook2(
        Id = pricebookId,
        IsActive = true
      );
      update standardPricebook;
      // Create Product
      Product2 product = new Product2(Name = 'Test Product', IsActive = true);
      insert product;

      PricebookEntry standardPriceEntry = new PricebookEntry(
        Pricebook2Id = standardPricebook.Id,
        Product2Id = product.Id,
        UnitPrice = 100,
        IsActive = true
      );
      insert standardPriceEntry;

      // Create Quote Line Item
      SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c(
        SBQQ__Quote__c = quote.Id,
        SBQQ__Product__c = product.Id,
        SBQQ__ListPrice__c = 100,
        SBQQ__Quantity__c = 1,
        SBQQ__SubscriptionTerm__c = 12,
        Vendor__c = contacts[0].Id,
        Client_Info__c = 'Test Client Info'
      );
      insert qli;
    }
  }

  @isTest
  static void testCreatePandaDocQuote_SlateNoCCPayment_Estimate() {
    Opportunity opp = [
      SELECT Division__c, CC_Payment__c
      FROM Opportunity
      WHERE Division__r.Name = 'Slate'
      LIMIT 1
    ];
    opp.CC_Payment__c = false;
    update opp;

    PandaDocApiMock mock = PandaDocApiMock.createSuccessMock();
    Test.setMock(HttpCalloutMock.class, mock);

    // WHEN
    Test.startTest();
    Map<String, String> result = PandaDocQuoteController.createPandaDocQuote(
      opp.Id,
      'estimate'
    );
    Test.stopTest();

    // THEN
    System.assertNotEquals(null, result, 'Result should not be null');

    String slateEstimateNoCcFeeTemplateUuid = new PandadocQuoteMappingSelector()
      .selectPandadocQuoteTemplateMappingByDivisionName('Slate')
      .Pandadoc_Estimate_Template_Id__c;
    Map<String, Object> sentPayload = mock.lastRequestBody;
    System.assertEquals(
      slateEstimateNoCcFeeTemplateUuid,
      sentPayload.get('template_uuid'),
      'Template UUID in the payload should exactly equal the mapped template id for Slate no cc fee estimate'
    );
  }

  @isTest
  static void testCreatePandaDocQuote_SlateCCPayment_Estimate() {
    Opportunity opp = [
      SELECT Division__c, CC_Payment__c
      FROM Opportunity
      WHERE Division__r.Name = 'Slate'
      LIMIT 1
    ];

    // Create CC Processing Fee Product and PricebookEntry
    Product2 ccProduct = new Product2(
      Name = 'CC Processing Fee',
      IsActive = true,
      ProductCode = 'Slate_CC',
      Family = 'Service'
    );
    insert ccProduct;

    Id pricebookId = Test.getStandardPricebookId();
    PricebookEntry standardPriceEntry = new PricebookEntry(
      Pricebook2Id = pricebookId,
      Product2Id = ccProduct.Id,
      UnitPrice = 1, // Set a nominal price, actual price might be calculated by automation
      IsActive = true
    );
    insert standardPriceEntry;

    opp.CC_Payment__c = true;
    update opp;

    PandaDocApiMock mock = PandaDocApiMock.createSuccessMock();
    Test.setMock(HttpCalloutMock.class, mock);

    // WHEN
    Test.startTest();
    Map<String, String> result = PandaDocQuoteController.createPandaDocQuote(
      opp.Id,
      'estimate'
    );
    Test.stopTest();

    // THEN
    System.assertNotEquals(null, result, 'Result should not be null');

    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM SBQQ__QuoteLine__c
        WHERE
          SBQQ__Product__r.Name = 'CC Processing Fee'
          AND SBQQ__Quote__r.SBQQ__Opportunity2__c = :opp.Id
      ],
      'Expected one CC Processing Fee QLI for Slate CC Payment Estimate'
    );
  }

  @isTest
  static void testCreatePandaDocQuote_SlateNoCCPayment_Invoice() {
    Opportunity opp = [
      SELECT Division__c, CC_Payment__c
      FROM Opportunity
      WHERE Division__r.Name = 'Slate'
      LIMIT 1
    ];
    opp.CC_Payment__c = false;
    update opp;

    PandaDocApiMock mock = PandaDocApiMock.createSuccessMock();
    Test.setMock(HttpCalloutMock.class, mock);

    // WHEN
    Test.startTest();
    Map<String, String> result = PandaDocQuoteController.createPandaDocQuote(
      opp.Id,
      'invoice' // Changed from 'estimate' to 'invoice'
    );
    Test.stopTest();

    // THEN
    System.assertNotEquals(null, result, 'Result should not be null');

    String slateInvoiceNoCcFeeTemplateUuid = new PandadocQuoteMappingSelector()
      .selectPandadocQuoteTemplateMappingByDivisionName('Slate')
      .Pandadoc_Invoice_Template_Id__c; // Changed to invoice template field
    Map<String, Object> sentPayload = mock.lastRequestBody;
    System.assertEquals(
      slateInvoiceNoCcFeeTemplateUuid,
      sentPayload.get('template_uuid'),
      'Template UUID in the payload should exactly equal the mapped template id for Slate no cc fee invoice'
    );
  }

  @isTest
  static void testCreatePandaDocQuote_SlateCCPayment_Invoice() {
    Opportunity opp = [
      SELECT Division__c, CC_Payment__c
      FROM Opportunity
      WHERE Division__r.Name = 'Slate'
      LIMIT 1
    ];

    // Create CC Processing Fee Product and PricebookEntry
    Product2 ccProduct = new Product2(
      Name = 'CC Processing Fee',
      IsActive = true,
      ProductCode = 'Slate_CC',
      Family = 'Service'
    );
    insert ccProduct;

    Id pricebookId = Test.getStandardPricebookId();
    PricebookEntry standardPriceEntry = new PricebookEntry(
      Pricebook2Id = pricebookId,
      Product2Id = ccProduct.Id,
      UnitPrice = 1, // Set a nominal price, actual price might be calculated by automation
      IsActive = true
    );
    insert standardPriceEntry;

    opp.CC_Payment__c = true;
    update opp;

    PandaDocApiMock mock = PandaDocApiMock.createSuccessMock();
    Test.setMock(HttpCalloutMock.class, mock);

    // WHEN
    Test.startTest();
    Map<String, String> result = PandaDocQuoteController.createPandaDocQuote(
      opp.Id,
      'invoice' // Changed from 'estimate' to 'invoice'
    );
    Test.stopTest();

    // THEN
    System.assertNotEquals(null, result, 'Result should not be null');

    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM SBQQ__QuoteLine__c
        WHERE
          SBQQ__Product__r.Name = 'CC Processing Fee'
          AND SBQQ__Quote__r.SBQQ__Opportunity2__c = :opp.Id
      ],
      'Expected one CC Processing Fee QLI for Slate CC Payment Invoice'
    );
  }

  @isTest
  static void testAttachDocumentToOpportunity() {
    // GIVEN
    Opportunity opp = [
      SELECT Id, Division__r.Name, Name, CreatedDate
      FROM Opportunity
      WHERE Division__r.Name = 'Slate'
      LIMIT 1
    ];
    String mockDocumentId = 'mock-document-id';
    String mockDocumentName = 'Mock Document Name';
    Datetime testStart = Datetime.now();

    PandaDocApiMock mock = PandaDocApiMock.createDocumentContentMock();
    Test.setMock(HttpCalloutMock.class, mock);

    // WHEN
    Test.startTest();
    PandaDocQuoteController.attachDocumentToOpportunity(
      opp.Id,
      mockDocumentId,
      mockDocumentName,
      'estimate'
    );
    Test.stopTest();

    // THEN
    List<ContentDocumentLink> cdls = [
      SELECT ContentDocument.Title, ContentDocument.LatestPublishedVersionId
      FROM ContentDocumentLink
      WHERE
        LinkedEntityId = :opp.Id
        AND SystemModstamp >= :testStart
        AND ContentDocument.Title LIKE '%EST%'
    ];

    System.assertEquals(
      true,
      cdls.size() > 0,
      'One ContentDocumentLink should be created'
    );
    Datetime createdDate = opp.CreatedDate;

    String formattedDate = opp.CreatedDate.format('YYMMdd');

    String nameShouldbe =
      opp.Name +
      '_' +
      (opp.Division__r.Name != 'Palermo'
        ? opp.Division__r.Name.substring(0, 2).toUpperCase()
        : 'PL') +
      '_EST_' +
      formattedDate;

    System.assertEquals(
      nameShouldbe,
      cdls[0].ContentDocument.Title,
      'Document title should match'
    );

    ContentVersion cv = [
      SELECT Title, PathOnClient, VersionData
      FROM ContentVersion
      WHERE Id = :cdls[0].ContentDocument.LatestPublishedVersionId
    ];

    System.assertEquals(
      mockDocumentName + '.pdf',
      cv.PathOnClient,
      'File name should match and have .pdf extension'
    );
    System.assertEquals(
      'Mock PDF Content',
      cv.VersionData.toString(),
      'Document content should match mock content'
    );
  }

  @isTest
  static void testCheckDocumentStatus() {
    // GIVEN
    String mockStatusUrl = 'https://api.pandadoc.com/public/v1/documents/mock-document-id';
    PandaDocApiMock mock = PandaDocApiMock.createDocumentStatusMock();
    Test.setMock(HttpCalloutMock.class, mock);

    // WHEN
    Test.startTest();
    Map<String, String> result = PandaDocQuoteController.checkDocumentStatus(
      mockStatusUrl,
      [SELECT Id FROM Opportunity WHERE Division__r.Name = 'Slate' LIMIT 1].Id
    );
    Test.stopTest();

    // THEN
    Assert.isNotNull(result, 'Result should not be null');
    Assert.areEqual(
      'document.completed',
      result.get('status'),
      'Status should be "document.completed"'
    );
    Assert.areEqual(
      'mock-document-id',
      result.get('id'),
      'Document ID should match'
    );
    Assert.areEqual(
      'Mock Completed Document',
      result.get('name'),
      'Document name should match'
    );
  }

  @isTest
  static void testConstructErrorMessage() {
    // GIVEN
    HttpResponse mockResponse = new HttpResponse();
    mockResponse.setStatusCode(400);
    mockResponse.setStatus('Bad Request');
    mockResponse.setBody(
      '{"errors": ["You done goofed!", "Seriously, what were you thinking?"]}'
    );

    // WHEN
    String errorMessage = PandadocApi.constructErrorMessage(mockResponse);

    // THEN
    Assert.isTrue(
      errorMessage.contains('Failed to create PandaDoc quote'),
      'Error message should start with the failure indication'
    );
    Assert.isTrue(
      errorMessage.contains('Status: Bad Request'),
      'Error message should contain the status'
    );
    Assert.isTrue(
      errorMessage.contains('Status Code: 400'),
      'Error message should contain the status code'
    );
    Assert.isTrue(
      errorMessage.contains('Response Body:'),
      'Error message should contain the response body'
    );
    Assert.isTrue(
      errorMessage.contains(
        'Errors: ["You done goofed!","Seriously, what were you thinking?"]'
      ),
      'Error message should contain the parsed errors'
    );
  }

  @isTest
  static void testCreatePandaDocQuote_WithAdditionalCCRecipients() {
    // GIVEN
    Opportunity opp = [
      SELECT Id, Division__c, CC_Payment__c, Additional_Client_CC__c
      FROM Opportunity
      WHERE Division__r.Name = 'Slate'
      LIMIT 1
    ];
    opp.CC_Payment__c = false;
    opp.Additional_Client_CC__c = 'cc1@example.com, cc2@example.com';
    update opp;

    PandaDocApiMock mock = PandaDocApiMock.createSuccessMock();
    Test.setMock(HttpCalloutMock.class, mock);

    // WHEN
    Test.startTest();
    Map<String, String> result = PandaDocQuoteController.createPandaDocQuote(
      opp.Id,
      'estimate'
    );
    Test.stopTest();

    // THEN
    System.assertNotEquals(null, result, 'Result should not be null');

    // Verify that the recipients in the request include CC recipients
    Map<String, Object> sentPayload = mock.lastRequestBody;
    List<Object> recipients = (List<Object>) sentPayload.get('recipients');

    Integer ccRecipientCount = 0;
    for (Object recipientObj : recipients) {
      Map<String, Object> recipient = (Map<String, Object>) recipientObj;
      if (
        recipient.containsKey('recipient_type') &&
        recipient.get('recipient_type') == 'cc'
      ) {
        ccRecipientCount++;
      }
    }

    System.assertEquals(2, ccRecipientCount, 'There should be 2 CC recipients');
  }
  @isTest
  static void testCreatePandaDocQuote_WithQuoteRecord() {
    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
    PandaDocApiMock mock = PandaDocApiMock.createSuccessMock();
    Test.setMock(HttpCalloutMock.class, mock);

    // WHEN
    Test.startTest();
    Map<String, String> result = PandaDocQuoteController.createPandaDocQuote(
      quote.Id,
      'estimate'
    );
    Test.stopTest();

    // THEN
    System.assertNotEquals(null, result, 'Result should not be null');
  }

  @isTest
  static void testTokensReplacesNullValuesWithDoNotReplace() {
    // GIVEN
    Opportunity opp = [
      SELECT Id
      FROM Opportunity
      WHERE Division__r.Name = 'Slate'
      LIMIT 1
    ];

    // Set Required_Deposit__c to avoid exception
    opp.Required_Deposit__c = 50;
    // Set critical fields to null
    opp.Opportunity_Descriptor__c = null;
    opp.Lead_Type__c = null;
    opp.Shoot_Date__c = null;
    update opp;

    // Create a test quote
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      SBQQ__Opportunity2__c = opp.Id,
      SBQQ__Primary__c = true
    );
    insert quote;

    PandaDocApiMock mock = PandaDocApiMock.createSuccessMock();
    Test.setMock(HttpCalloutMock.class, mock);

    // WHEN
    Test.startTest();
    Map<String, String> apiResult = PandaDocQuoteController.createPandaDocQuote(
      opp.Id,
      'estimate'
    );
    Test.stopTest();

    // THEN
    System.assertNotEquals(null, apiResult, 'API result should not be null');

    // Verify request body contains "Do Not Replace" values
    Map<String, Object> sentPayload = mock.lastRequestBody;
    List<Object> sentTokens = (List<Object>) sentPayload.get('tokens');

    Boolean foundOpportunityDescriptionReplacement = false;
    Boolean foundShootDateReplacement = false;
    Boolean foundProjectDescriptionReplacement = false;

    for (Object tokenObj : sentTokens) {
      Map<String, Object> token = (Map<String, Object>) tokenObj;

      if (
        token.get('name') == 'Opportunity_Descriptor__c' &&
        token.get('value') == 'Do Not Replace'
      ) {
        foundOpportunityDescriptionReplacement = true;
      }

      if (
        token.get('name') == 'Shoot_Date__c' &&
        token.get('value') == 'Do Not Replace'
      ) {
        foundShootDateReplacement = true;
      }

      if (
        token.get('name') == 'PROJECT_DESCRIPTION' &&
        token.get('value') == 'Do Not Replace'
      ) {
        foundProjectDescriptionReplacement = true;
      }
    }

    System.assert(
      foundOpportunityDescriptionReplacement,
      'Opportunity_Descriptor__c should be replaced with "Do Not Replace" when null'
    );

    System.assert(
      foundShootDateReplacement,
      'Shoot_Date__c should be replaced with "Do Not Replace" when null'
    );

    System.assert(
      foundProjectDescriptionReplacement,
      'PROJECT_DESCRIPTION should be replaced with "Do Not Replace" when null'
    );
  }
}
