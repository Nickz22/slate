@isTest
private class PandaDocQuoteControllerTest {
  @TestSetup
  static void setupTestData() {
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
      accounts.add(new Account(Name = 'Test Account ' + i));
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
          Lead_Type__c = 'Slate - CGI'
        )
      );
    }
    insert opportunities;
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
    opp.CC_Payment__c = true; // Set CC_Payment__c to true for this test
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

    String slateCCFeeEstimateTemplateUuid = new PandadocQuoteMappingSelector()
      .selectPandadocQuoteTemplateMappingByDivisionName('Slate')
      .Pandadoc_CC_Fee_Estimate_Template_Id__c; // Use the CC Fee template field
    Map<String, Object> sentPayload = mock.lastRequestBody;
    System.assertEquals(
      slateCCFeeEstimateTemplateUuid,
      sentPayload.get('template_uuid'),
      'Template UUID in the payload should exactly equal the mapped template id for Slate CC fee estimate'
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

    String slateCCFeeInvoiceTemplateUuid = new PandadocQuoteMappingSelector()
      .selectPandadocQuoteTemplateMappingByDivisionName('Slate')
      .Pandadoc_CC_Fee_Invoice_Template_Id__c; // Changed to CC fee invoice template field
    Map<String, Object> sentPayload = mock.lastRequestBody;
    System.assertEquals(
      slateCCFeeInvoiceTemplateUuid,
      sentPayload.get('template_uuid'),
      'Template UUID in the payload should exactly equal the mapped template id for Slate CC fee invoice'
    );
  }

  @isTest
  static void testAttachDocumentToOpportunity() {
    // GIVEN
    Opportunity opp = [
      SELECT Id,Division__r.Name,Name
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
      WHERE LinkedEntityId = :opp.Id AND SystemModstamp >= :testStart
    ];

    System.assertEquals(
      1,
      cdls.size(),
      'One ContentDocumentLink should be created'
    );
    String nameShouldbe =
        opp.Division__r.Name.substring(0, 2).toUpperCase() +
        ' - ' +
        'EST' +
        ' - ' +
        opp.Name;
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
}
