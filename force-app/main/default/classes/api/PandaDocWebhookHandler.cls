@RestResource(urlMapping='/pandadoc/webhook/*')
global without sharing class PandaDocWebhookHandler extends ErrorHandlingAbstractClass {
  public static final String DOCUMENT_SENT_STATUS = 'document.sent';
  public static final String DOCUMENT_PAID_STATUS = 'document.paid';

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
    RestRequest req = RestContext.request;
    String jsonBody = req.requestBody.toString();
    List<PandaDocDocumentChange> changes = (List<PandaDocDocumentChange>) JSON.deserialize(
      jsonBody,
      List<PandaDocDocumentChange>.class
    );

    for (PandaDocDocumentChange change : changes) {
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
    String status
  ) {
    Opportunity opp = [
      SELECT Id, Division__r.Name
      FROM Opportunity
      WHERE Id = :opportunityId
      LIMIT 1
    ];

    String newStage;

    if (status.toLowerCase() == DOCUMENT_SENT_STATUS) {
      newStage = 'Proposal';
    } else if (status.toLowerCase() == DOCUMENT_PAID_STATUS) {
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

    if (String.isNotBlank(newStage)) {
      opp.StageName = newStage;
      update opp;
      System.debug(
        'Updated Opportunity ' + opportunityId + ' to stage: ' + newStage
      );
    }
  }
}
