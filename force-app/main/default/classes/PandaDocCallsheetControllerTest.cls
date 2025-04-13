@isTest
private class PandaDocCallsheetControllerTest {
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
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
        SBQQ__Opportunity2__c = opportunities[0].Id,
        SBQQ__Primary__c = TRUE
    );
        insert quote;
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;
            // Create Product
    Product2 product = new Product2(
        Name = 'Test Product',
        IsActive = TRUE
    );
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
        Client_Info__c = 'Test Client Info',
        Include_in_Call_Sheet__c = TRUE
    );
    insert qli;
    }
  }

  @isTest
  static void testCreatePandaCallsheetSlate() {
    SBQQ__Quote__c quote = [SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c LIMIT 1];

    PandaDocApiMock mock = PandaDocApiMock.createSuccessMock();
    Test.setMock(HttpCalloutMock.class, mock);

    // WHEN
    Test.startTest();
    Map<String, String> result = PandadocCallSheetController.createPandaDocCallSheet(
      quote.SBQQ__Opportunity2__c
    );
    Test.stopTest();

    // THEN
    System.assertNotEquals(null, result, 'Result should not be null');

    String slateEstimateNoCcFeeTemplateUuid = new PandadocQuoteMappingSelector()
      .selectPandadocQuoteTemplateMappingByDivisionName('Slate')
      .Pandadoc_Call_Sheet_Template_Id__c;
    Map<String, Object> sentPayload = mock.lastRequestBody;
    System.assertEquals(
      slateEstimateNoCcFeeTemplateUuid,
      sentPayload.get('template_uuid'),
      'Template UUID in the payload should exactly equal the mapped template id for Slate no cc fee estimate'
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
      'callsheet'
    );
    Test.stopTest();

    // THEN
    List<ContentDocumentLink> cdls = [
      SELECT ContentDocument.Title, ContentDocument.LatestPublishedVersionId
      FROM ContentDocumentLink
      WHERE
        LinkedEntityId = :opp.Id
        AND SystemModstamp >= :testStart
        AND ContentDocument.Title LIKE '%CS%'
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
      '_CS_' +
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
  static void testTokensReplacesNullValuesWithDoNotReplace() {
    // GIVEN
    Opportunity opp = [
      SELECT Id
      FROM Opportunity
      WHERE Division__r.Name = 'Slate'
      LIMIT 1
    ];

    // Set critical fields to null
    opp.Lead_Type__c = null;
    opp.Lead_Producer__c = null;
    opp.Opportunity_Descriptor__c = null;
    opp.Shoot_Date__c = null;
    update opp;

    // Create controller directly to test internal methods
    PandadocCallSheetController controller = new PandadocCallSheetController(
      opp.Id
    );

    // Test by calling API
    PandaDocApiMock mock = PandaDocApiMock.createSuccessMock();
    Test.setMock(HttpCalloutMock.class, mock);

    // WHEN
    Test.startTest();
    Map<String, String> apiResult = PandadocCallSheetController.createPandaDocCallSheet(
      opp.Id
    );
    Test.stopTest();

    // THEN
    System.assertNotEquals(null, apiResult, 'API result should not be null');

    // Verify request body contains "Do Not Replace" values
    Map<String, Object> sentPayload = mock.lastRequestBody;
    List<Object> sentTokens = (List<Object>) sentPayload.get('tokens');

    Boolean foundLeadTypeReplacement = false;
    Boolean foundOpportunityDescriptionReplacement = false;
    Boolean foundShootDateReplacement = false;
    Boolean foundProjectDescriptionReplacement = false;

    for (Object tokenObj : sentTokens) {
      Map<String, Object> token = (Map<String, Object>) tokenObj;

      if (
        token.get('name') == 'Lead_Type__c' &&
        token.get('value') == 'Do Not Replace'
      ) {
        foundLeadTypeReplacement = true;
      }

      if (
        token.get('name') == 'OPPORTUNITY_DESCRIPTION' &&
        token.get('value') == 'Do Not Replace'
      ) {
        foundOpportunityDescriptionReplacement = true;
      }

      if (
        token.get('name') == 'SHOOT_DATE' &&
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
      foundLeadTypeReplacement,
      'Lead_Type__c should be replaced with "Do Not Replace" when null'
    );

    System.assert(
      foundOpportunityDescriptionReplacement,
      'OPPORTUNITY_DESCRIPTION should be replaced with "Do Not Replace" when null'
    );

    System.assert(
      foundShootDateReplacement,
      'SHOOT_DATE should be replaced with "Do Not Replace" when null'
    );

    System.assert(
      foundProjectDescriptionReplacement,
      'PROJECT_DESCRIPTION should be replaced with "Do Not Replace" when null'
    );
  }

  private class TokensReflectionHelper implements System.StubProvider {
    private PandadocCallSheetController controller;

    public TokensReflectionHelper(PandadocCallSheetController controller) {
      this.controller = controller;
    }

    public Object handleMethodCall(
      Object stubbedObject,
      String stubbedMethodName,
      Type returnType,
      List<Type> listOfParamTypes,
      List<String> listOfParamNames,
      List<Object> listOfArgs
    ) {
      if (stubbedMethodName == 'getTokens') {
        return controller.getTokens();
      }
      return null;
    }
  }
}
