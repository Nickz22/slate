@RestResource(urlMapping='/pandadoc/webhook/*')
global without sharing class PandaDocWebhookHandler extends ErrorHandlingAbstractClass {
  @TestVisible
  static Boolean mockError = false;
  public static final String DOCUMENT_SENT_STATUS = 'document.sent';
  public static final String DOCUMENT_PAID_STATUS = 'document.paid';
  public static final String DOCUMENT_COMPLETED_STATUS = 'document.completed';

  public enum DivisionName {
    ALIGN,
    SLATE,
    PALERMO
  }

  public enum DocumentType {
    ESTIMATE,
    PROPOSAL,
    INVOICE
  }

  public PandaDocWebhookHandler() {
    super('PandaDocWebhookHandler');
  }

  @HttpPost
  global static void handleWebhook() {
    new PandaDocWebhookHandler().execute();
  }

  protected override void executeWithErrorHandling() {
    if (mockError) {
      throw new CustomException('Mock error');
    }

    this.syncDocumentStatusToOpportunityStage(
      (List<PandaDocDocumentChange>) JSON.deserialize(
        RestContext.request.requestBody.toString(),
        List<PandaDocDocumentChange>.class
      )
    );
  }

  @TestVisible
  private void syncDocumentStatusToOpportunityStage(
    List<PandaDocDocumentChange> changes
  ) {
    for (PandaDocDocumentChange change : changes) {
      System.debug('change: ' + JSON.serializePretty(change));
      DocumentType thisDocumentType = change.data.template.name.containsIgnoreCase(
          'Quote'
        )
        ? DocumentType.ESTIMATE
        : change.data.template.name.containsIgnoreCase('Proposal')
            ? DocumentType.PROPOSAL
            : change.data.template.name.containsIgnoreCase('Invoice')
                ? DocumentType.INVOICE
                : null;
      if (thisDocumentType == null) {
        continue;
      }
      if (change.event == 'document_state_changed') {
        String status = change.data.status;
        String opportunityId = change.data.metadata.salesforce_opportunity_id;

        if (String.isNotBlank(opportunityId)) {
          this.updateDocumentStage(opportunityId, status, thisDocumentType);
        }
      }
    }
  }

  private void updateDocumentStage(
    String opportunityId,
    String documentStatus,
    DocumentType docType
  ) {
    Opportunity opp = [
      SELECT Name, Division__r.Name, StageName, Stage_Document_Automated__c
      FROM Opportunity
      WHERE Id = :opportunityId
      LIMIT 1
    ];

    String newDocumentStage = this.getNewDocumentStage(
      opp,
      documentStatus,
      docType
    );
    String newOpportunityStage = this.getNewOpportunityStage(
      opp,
      documentStatus,
      docType
    );

    opp.Stage_Document_Automated__c = String.isBlank(newDocumentStage)
      ? opp.Stage_Document_Automated__c
      : newDocumentStage;
    opp.StageName = String.isBlank(newOpportunityStage)
      ? opp.StageName
      : newOpportunityStage;

    Boolean isProposalSigned =
      opp.Stage_Document_Automated__c == 'Proposal Signed';

    if (isProposalSigned) {
      this.sendProposalSignedNotification(opp);
    }

    Database.update(opp, true);
  }

  /**
   * return according to the document type
   */
  private String getNewDocumentStage(
    Opportunity opp,
    String documentStatus,
    DocumentType docType
  ) {
    String newStage;
    Boolean isSent = documentStatus.toLowerCase() == DOCUMENT_SENT_STATUS;
    Boolean isSigned =
      documentStatus.toLowerCase() == DOCUMENT_COMPLETED_STATUS;

    if (isSent) {
      newStage = docType == DocumentType.PROPOSAL
        ? 'Proposal Sent'
        : docType == DocumentType.ESTIMATE
            ? 'Quote Sent'
            : docType == DocumentType.INVOICE ? 'Invoice Sent' : null;
    }

    if (isSigned) {
      newStage = docType == DocumentType.PROPOSAL
        ? 'Proposal Signed'
        : docType == DocumentType.ESTIMATE
            ? 'Quote Signed'
            : docType == DocumentType.INVOICE ? 'Invoice Paid' : null;
    }

    return newStage;
  }

  private String getNewOpportunityStage(
    Opportunity opp,
    String documentStatus,
    DocumentType docType
  ) {
    String newStage;
    Boolean isQuoteClosed =
      docType == DocumentType.ESTIMATE &&
      (documentStatus.toLowerCase() == DOCUMENT_PAID_STATUS ||
      documentStatus.toLowerCase() == DOCUMENT_COMPLETED_STATUS);

    if (isQuoteClosed) {
      if (
        opp.Division__r.Name.toLowerCase() ==
        DivisionName.ALIGN.name().toLowerCase()
      ) {
        newStage = 'Won - Post Production';
      } else if (
        opp.Division__r.Name.toLowerCase() ==
        DivisionName.SLATE.name().toLowerCase() ||
        opp.Division__r.Name.toLowerCase() ==
        DivisionName.PALERMO.name().toLowerCase()
      ) {
        newStage = 'Won - Production';
      }
    }

    return newStage;
  }

  private void sendProposalSignedNotification(Opportunity opp) {
    User camUser = [
      SELECT Id
      FROM User
      WHERE Username LIKE 'info@slate-nyc.com%'
      LIMIT 1
    ];

    Messaging.CustomNotification notification = new Messaging.CustomNotification();

    CustomNotificationType notificationType = [
      SELECT Id
      FROM CustomNotificationType
      WHERE DeveloperName = 'Won_Opportunity'
      LIMIT 1
    ];
    notification.setNotificationTypeId(notificationType.Id);

    notification.setTitle('Proposal Signed - ' + opp.Name);
    notification.setBody('Click for opportunity details.');

    notification.setTargetId(opp.Id);

    try {
      notification.send(new Set<String>{ camUser.Id });
    } catch (Exception e) {
      System.debug('Error sending custom notification: ' + e.getMessage());
    }
  }

  private class CustomException extends Exception {
  }
}
