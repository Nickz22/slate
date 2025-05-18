@isTest
private class PandaDocWebhookHandlerTest {
  private static final String ACCOUNT_NAME = 'Test Account';
  private static final String CONTACT_EMAIL = 'test@example.com';

  private static User testAdminUser {
    get {
      if (testAdminUser == null) {
        testAdminUser = [
          SELECT Id
          FROM User
          WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE
          LIMIT 1
        ];
      }
      return testAdminUser;
    }
    set;
  }

  @TestSetup
  static void setupTestData() {
    Division__c slateDivision = new Division__c(
      Division_Leader__c = UserInfo.getUserId(),
      Name = 'Slate'
    );
    insert slateDivision;
    // Create test Account
    Account testAccount = new Account(Name = ACCOUNT_NAME);
    insert testAccount;

    // Create test Contact
    Contact testContact = new Contact(
      FirstName = 'Test',
      LastName = 'Contact',
      Email = CONTACT_EMAIL,
      AccountId = testAccount.Id
    );
    insert testContact;

    // Create test Opportunity
    Opportunity testOpportunity = new Opportunity(
      Name = 'x', // automatically set downstream
      AccountId = testAccount.Id,
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      PrimaryContact__c = testContact.Id,
      Lead_Type__c = 'Slate - CGI',
      Division__c = slateDivision.Id
    );
    insert testOpportunity;
  }

  @isTest
  static void testMockError() {
    Integer numEmails = 0;
    Test.startTest();
    PandaDocWebhookHandler.mockError = true;
    Boolean hitNoSingleEmailPermissionError = false;
    try {
      PandaDocWebhookHandler.handleWebhook();
    } catch (Exception e) {
      if (e.getMessage().contains('NO_SINGLE_MAIL_PERMISSION')) {
        hitNoSingleEmailPermissionError = true;
      }
    }
    numEmails += Limits.getEmailInvocations();
    Test.stopTest();

    Assert.isTrue(
      numEmails == 1 || hitNoSingleEmailPermissionError,
      'Error email should be sent or at least attempted to be sent'
    );
  }

  @isTest
  static void testMockErrorWhileSendingErrorEmail() {
    Test.startTest();
    PandaDocWebhookHandler.mockError = true;
    ErrorHandlingAbstractClass.mockError = true;
    Boolean hasMockErrorHandlingAbstractClassError = false;
    try {
      PandaDocWebhookHandler.handleWebhook();
    } catch (Exception e) {
      if (e.getMessage().contains('Mock error while sending error email')) {
        hasMockErrorHandlingAbstractClassError = true;
      }
    }
    Test.stopTest();

    Assert.isTrue(
      hasMockErrorHandlingAbstractClassError,
      'Mock error handling abstract class error should be thrown'
    );
  }

  @isTest
  static void testQuoteSentStatus_Slate() {
    Opportunity opp = [
      SELECT Id
      FROM Opportunity
      LIMIT 1
    ];

    Test.startTest();
    new PandaDocWebhookHandler()
      .syncDocumentStatusToOpportunityStage(
        new List<PandaDocDocumentChange>{
          createDocumentChange_Quote(
            'document_state_changed',
            'document.sent',
            opp.Id
          )
        }
      );
    Test.stopTest();

    opp = [
      SELECT Stage_Document_Automated__c
      FROM Opportunity
      WHERE Id = :opp.Id
    ];
    System.assertEquals(
      'Quote Sent',
      opp.Stage_Document_Automated__c,
      'Opportunity Document Automated Stage should be updated to Quote Sent'
    );
  }

  @isTest
  static void testProposalSentStatus_Align() {
    Opportunity opp = [
      SELECT Id, Division__c
      FROM Opportunity
      LIMIT 1
    ];

    Division__c alignDivision = new Division__c(Name = 'Align');
    insert alignDivision;

    opp.Division__c = alignDivision.Id;
    update opp;

    Test.startTest();

    new PandaDocWebhookHandler()
      .syncDocumentStatusToOpportunityStage(
        new List<PandaDocDocumentChange>{
          createDocumentChange_Proposal(
            'document_state_changed',
            PandaDocWebhookHandler.DOCUMENT_SENT_STATUS,
            opp.Id
          )
        }
      );
    Test.stopTest();

    Opportunity updatedOpp = [
      SELECT Stage_Document_Automated__c
      FROM Opportunity
      WHERE Id = :opp.Id
    ];

    Assert.areEqual(
      'Proposal Sent',
      updatedOpp.Stage_Document_Automated__c,
      'Opportunity Document Automated Stage should be "Proposal Sent" for Align division'
    );
  }

  @isTest
  static void testInvoiceSentStatus_Palermo() {
    Opportunity opp = [SELECT Id, Division__c FROM Opportunity LIMIT 1];

    Division__c palermoDivision = new Division__c(Name = 'Palermo');
    insert palermoDivision;

    opp.Division__c = palermoDivision.Id;
    update opp;

    Test.startTest();

    new PandaDocWebhookHandler()
      .syncDocumentStatusToOpportunityStage(
        new List<PandaDocDocumentChange>{
          createDocumentChange_Invoice(
            'document_state_changed',
            PandaDocWebhookHandler.DOCUMENT_SENT_STATUS,
            opp.Id
          )
        }
      );

    Test.stopTest();

    Opportunity updatedOpp = [
      SELECT Stage_Document_Automated__c
      FROM Opportunity
      WHERE Id = :opp.Id
    ];

    Assert.areEqual(
      'Invoice Sent',
      updatedOpp.Stage_Document_Automated__c,
      'Opportunity Document Automated Stage should be "Invoice Sent".'
    );
  }

  @isTest
  static void testQuoteSignedStatus_Align() {
    Opportunity opp = [
      SELECT Id, Division__c
      FROM Opportunity
      LIMIT 1
    ];

    // Create a test Division
    Division__c testDivision = new Division__c(Name = 'Align');
    insert testDivision;

    // Update Opportunity with the test Division
    opp.Division__c = testDivision.Id;
    update opp;

    Test.startTest();
    new PandaDocWebhookHandler()
      .syncDocumentStatusToOpportunityStage(
        new List<PandaDocDocumentChange>{
          createDocumentChange_Quote(
            'document_state_changed',
            PandaDocWebhookHandler.DOCUMENT_COMPLETED_STATUS,
            opp.Id
          )
        }
      );
    Test.stopTest();

    opp = [
      SELECT Stage_Document_Automated__c, StageName
      FROM Opportunity
      WHERE Id = :opp.Id
    ];
    System.assertEquals(
      'Quote Signed',
      opp.Stage_Document_Automated__c,
      'Opportunity Document Automated Stage should be updated to Quote Signed'
    );
    System.assertEquals(
      'Won - Post Production',
      opp.StageName,
      'Opportunity stage should be updated to Won - Post Production'
    );
  }

  @isTest
  static void testQuoteSignedStatus_Palermo() {
    Opportunity opp = [
      SELECT Id, Division__c
      FROM Opportunity
      LIMIT 1
    ];

    // Create a test Division
    Division__c testDivision = new Division__c(Name = 'Palermo');
    insert testDivision;

    // Update Opportunity with the test Division
    opp.Division__c = testDivision.Id;
    update opp;

    Test.startTest();
    new PandaDocWebhookHandler()
      .syncDocumentStatusToOpportunityStage(
        new List<PandaDocDocumentChange>{
          createDocumentChange_Quote(
            'document_state_changed',
            PandaDocWebhookHandler.DOCUMENT_COMPLETED_STATUS,
            opp.Id
          )
        }
      );
    Test.stopTest();

    opp = [
      SELECT Stage_Document_Automated__c, StageName
      FROM Opportunity
      WHERE Id = :opp.Id
    ];
    System.assertEquals(
      'Quote Signed',
      opp.Stage_Document_Automated__c,
      'Opportunity Document Automated Stage should be updated to Quote Signed'
    );
    System.assertEquals(
      'Won - Production',
      opp.StageName,
      'Opportunity stage should be updated to Won - Production'
    );
  }

  @isTest
  static void testQuoteSignedStatus_Slate() {
    Opportunity opp = [
      SELECT Id, Division__c
      FROM Opportunity
      LIMIT 1
    ];

    Test.startTest();
    new PandaDocWebhookHandler()
      .syncDocumentStatusToOpportunityStage(
        new List<PandaDocDocumentChange>{
          createDocumentChange_Quote(
            'document_state_changed',
            PandaDocWebhookHandler.DOCUMENT_COMPLETED_STATUS,
            opp.Id
          )
        }
      );
    Test.stopTest();

    opp = [
      SELECT Stage_Document_Automated__c, StageName
      FROM Opportunity
      WHERE Id = :opp.Id
    ];
    System.assertEquals(
      'Quote Signed',
      opp.Stage_Document_Automated__c,
      'Opportunity Document Automated Stage should be updated to Quote Signed'
    );
    System.assertEquals(
      'Won - Production',
      opp.StageName,
      'Opportunity stage should be updated to Won - Production'
    );
  }

  @isTest
  static void testProposalSigned_Palermo() {
    Id palermoPermissionSetId = [
      SELECT Id
      FROM PermissionSet
      WHERE Name = 'Palermo_User'
      LIMIT 1
    ]
    .Id;

    insert new PermissionSetAssignment(
      AssigneeId = testAdminUser.Id,
      PermissionSetId = palermoPermissionSetId
    );

    System.runAs(testAdminUser) {
      Opportunity opp = [
        SELECT Stage_Document_Automated__c, StageName
        FROM Opportunity
      ];

      Test.startTest();

      new PandaDocWebhookHandler()
        .syncDocumentStatusToOpportunityStage(
          new List<PandaDocDocumentChange>{
            createDocumentChange_Proposal(
              'document_state_changed',
              PandaDocWebhookHandler.DOCUMENT_COMPLETED_STATUS,
              opp.Id
            )
          }
        );
      Test.stopTest();

      opp = [
        SELECT Stage_Document_Automated__c, StageName
        FROM Opportunity
        WHERE Id = :opp.Id
        WITH USER_MODE
      ];

      Assert.areEqual(
        'Proposal Signed',
        opp.Stage_Document_Automated__c,
        'The Stage_Document_Automated__c should be "Proposal Signed"!'
      );
    }
  }

  @isTest
  static void testInvoiceSigned_Slate() {
    Id palermoPermissionSetId = [
      SELECT Id
      FROM PermissionSet
      WHERE Name = 'Palermo_User'
      LIMIT 1
    ]
    .Id;

    insert new PermissionSetAssignment(
      AssigneeId = testAdminUser.Id,
      PermissionSetId = palermoPermissionSetId
    );

    System.runAs(testAdminUser) {
      Opportunity opp = [
        SELECT Id, Division__c
        FROM Opportunity
        LIMIT 1
      ];

      Test.startTest();

      new PandaDocWebhookHandler()
        .syncDocumentStatusToOpportunityStage(
          new List<PandaDocDocumentChange>{
            createDocumentChange_Invoice(
              'document_state_changed',
              PandaDocWebhookHandler.DOCUMENT_COMPLETED_STATUS,
              opp.Id
            )
          }
        );
      Test.stopTest();

      opp = [
        SELECT Stage_Document_Automated__c, StageName
        FROM Opportunity
        WHERE Id = :opp.Id
        WITH USER_MODE
      ];

      Assert.areEqual(
        'Invoice Paid',
        opp.Stage_Document_Automated__c,
        'The Stage_Document_Automated__c should be "Invoice Signed".'
      );
    }
  }

  @isTest
  static void testDocumentDraftStatus() {
    Opportunity opp = [
      SELECT Id
      FROM Opportunity
      LIMIT 1
    ];

    Test.startTest();
    RestContext.request = new RestRequest();
    RestContext.request.requestBody = Blob.valueOf(
      JSON.serialize(
        new List<PandaDocDocumentChange>{
          createDocumentChange_Quote(
            'document_state_changed',
            'document.draft',
            opp.Id
          )
        }
      )
    );
    PandaDocWebhookHandler.handleWebhook();
    Test.stopTest();

    opp = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
    System.assertNotEquals(
      'Proposal',
      opp.StageName,
      'Opportunity stage should not be updated for draft status'
    );
    System.assertNotEquals(
      'Won - Post Production',
      opp.StageName,
      'Opportunity stage should not be updated for draft status'
    );
  }

  private static PandaDocDocumentChange createDocumentChange_Quote(
    String event,
    String status,
    Id opportunityId
  ) {
    PandaDocDocumentChange change = new PandaDocDocumentChange();
    change.event = event;
    change.data = new PandaDocDocumentChange.DocumentData();
    change.data.status = status;
    change.data.metadata = new PandaDocDocumentChange.Metadata();
    change.data.metadata.salesforce_opportunity_id = opportunityId;
    change.data.template = new PandaDocDocumentChange.Template();
    change.data.template.name = 'Test Estimate';
    return change;
  }

  private static PandaDocDocumentChange createDocumentChange_Proposal(
    String event,
    String status,
    Id opportunityId
  ) {
    PandaDocDocumentChange change = createDocumentChange_Quote(
      event,
      status,
      opportunityId
    );
    change.data.template.name = 'Test Proposal';
    return change;
  }

  private static PandaDocDocumentChange createDocumentChange_Invoice(
    String event,
    String status,
    Id opportunityId
  ) {
    PandaDocDocumentChange change = createDocumentChange_Proposal(
      event,
      status,
      opportunityId
    );
    change.data.template.name = 'Test Invoice';
    return change;
  }
}