@RestResource(urlMapping='/pandadoc/webhook/*')
global without sharing class PandaDocWebhookHandler extends ErrorHandlingAbstractClass {
  public static final String DOCUMENT_SENT_STATUS = 'document.sent';
  public static final String DOCUMENT_PAID_STATUS = 'document.paid';
  public static final String DOCUMENT_COMPLETED_STATUS = 'document.completed';

  public enum DivisionName {
    ALIGN,
    SLATE,
    PALERMO
  }

  @HttpPost
  global static void handleWebhook() {
    new PandaDocWebhookHandler().execute();
  }

  protected override void executeWithErrorHandling() {
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
      // we don't change the opportunity stage for invoices
      if (!change.data.template.name.containsIgnoreCase('estimate')) {
        continue;
      }

      if (change.event == 'document_state_changed') {
        String status = change.data.status;
        String opportunityId = change.data.metadata.salesforce_opportunity_id;

        if (String.isNotBlank(opportunityId)) {
          updateOpportunityStage(opportunityId, status);
        }
      }
    }
  }

  private static void updateOpportunityStage(
    String opportunityId,
    String documentStatus
  ) {
    Opportunity opp = [
      SELECT Name, Division__r.Name
      FROM Opportunity
      WHERE Id = :opportunityId
      LIMIT 1
    ];

    String newStage = getNewStage(opp, documentStatus);

    if (String.isBlank(newStage)) {
      return;
    }

    opp.StageName = newStage;
    Boolean isWon = opp.StageName.containsIgnoreCase('Won');

    if (isWon) {
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

      notification.setTitle('Opportunity Won - ' + opp.Name);
      notification.setBody('Click for opportunity details.');

      notification.setTargetId(opp.Id);

      try {
        notification.send(new Set<String>{ camUser.Id });
      } catch (Exception e) {
        System.debug('Error sending custom notification: ' + e.getMessage());
      }
    }

    Database.update(opp, true);
  }

  private static String getNewStage(Opportunity opp, String documentStatus) {
    String newStage;
    Boolean isSent = documentStatus.toLowerCase() == DOCUMENT_SENT_STATUS;
    Boolean isClosed =
      documentStatus.toLowerCase() == DOCUMENT_PAID_STATUS ||
      documentStatus.toLowerCase() == DOCUMENT_COMPLETED_STATUS;

    if (isSent) {
      newStage = 'Proposal';
    } else if (isClosed) {
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

  private class CustomException extends Exception {
  }
}
