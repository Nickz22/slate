global class TypeformLeadConvert_Batch implements Database.Batchable<SObject> {
  global Database.QueryLocator start(Database.BatchableContext bc) {
    String query = 'SELECT Id FROM Lead WHERE isConverted = False AND isTypeForm__c = TRUE';

    return Database.getQueryLocator(query);
  }

  global void execute(
    Database.BatchableContext bc,
    List<SObject> needConversion
  ) {
    List<Lead> toConvert = (List<Lead>) needConversion;

    for (Lead newLead : toConvert) {
      LeadConvertController.convertLeads(newLead.Id);
    }
  }

  global void finish(Database.BatchableContext bc) {
  }
}
