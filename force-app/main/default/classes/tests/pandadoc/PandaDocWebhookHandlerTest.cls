@isTest
private class PandaDocWebhookHandlerTest {
  private static final String ACCOUNT_NAME = 'Test Account';
  private static final String CONTACT_EMAIL = 'test@example.com';

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
  static void testDocumentSentStatus() {
    Opportunity opp = [
      SELECT Id
      FROM Opportunity
      LIMIT 1
    ];

    Test.startTest();
    new PandaDocWebhookHandler()
      .syncDocumentStatusToOpportunityStage(
        new List<PandaDocDocumentChange>{
          createDocumentChange(
            'document_state_changed',
            'document.sent',
            opp.Id
          )
        }
      );
    Test.stopTest();

    opp = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
    System.assertEquals(
      'Proposal',
      opp.StageName,
      'Opportunity stage should be updated to Proposal'
    );
  }

  @isTest
  static void testDocumentPaidStatus_Align() {
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
          createDocumentChange(
            'document_state_changed',
            'document.paid',
            opp.Id
          )
        }
      );
    Test.stopTest();

    opp = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
    System.assertEquals(
      'Won - Post Production',
      opp.StageName,
      'Opportunity stage should be updated to Won - Post Production'
    );
  }

  @isTest
  static void testDocumentPaidStatus_Palermo() {
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
          createDocumentChange(
            'document_state_changed',
            'document.paid',
            opp.Id
          )
        }
      );
    Test.stopTest();

    opp = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
    System.assertEquals(
      'Won - Production',
      opp.StageName,
      'Opportunity stage should be updated to Won - Production'
    );
  }

  @isTest
  static void testDocumentPaidStatus_Slate() {
    Opportunity opp = [
      SELECT Id, Division__c
      FROM Opportunity
      LIMIT 1
    ];

    // Create a test Division
    Division__c testDivision = new Division__c(Name = 'Slate');
    insert testDivision;

    // Update Opportunity with the test Division
    opp.Division__c = testDivision.Id;
    update opp;

    Test.startTest();
    new PandaDocWebhookHandler()
      .syncDocumentStatusToOpportunityStage(
        new List<PandaDocDocumentChange>{
          createDocumentChange(
            'document_state_changed',
            'document.paid',
            opp.Id
          )
        }
      );
    Test.stopTest();

    opp = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
    System.assertEquals(
      'Won - Production',
      opp.StageName,
      'Opportunity stage should be updated to Won - Production'
    );
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
          createDocumentChange(
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

  @isTest
  static void testDocumentSignedStatus_Slate_WithNotification() {
    Opportunity opp = [
      SELECT Id, Division__c
      FROM Opportunity
      LIMIT 1
    ];

    // Create a test Division
    Division__c testDivision = new Division__c(Name = 'Slate');
    insert testDivision;

    // Update Opportunity with the test Division
    opp.Division__c = testDivision.Id;
    update opp;

    Test.startTest();

    new PandaDocWebhookHandler()
      .syncDocumentStatusToOpportunityStage(
        new List<PandaDocDocumentChange>{
          createDocumentChange(
            'document_state_changed',
            'document.completed',
            opp.Id
          )
        }
      );
    Test.stopTest();

    opp = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
    Assert.areEqual(
      'Won - Production',
      opp.StageName,
      'Opportunity stage should be updated to Won - Production'
    );
  }

  private static PandaDocDocumentChange createDocumentChange(
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
}
