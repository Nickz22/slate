trigger QuoteTrigger on SBQQ__Quote__c(before insert, after insert) {
  if (Trigger.isBefore && Trigger.isInsert) {
    QuoteTriggerHandler.setDivisionName(Trigger.new);
  }
  if (Trigger.isAfter && Trigger.isInsert) {
    QuoteTriggerHandler.handleAfterInsert(Trigger.new);
  }
}
