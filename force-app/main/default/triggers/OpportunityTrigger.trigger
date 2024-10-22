trigger OpportunityTrigger on Opportunity(
  before insert,
  after insert,
  before update,
  after update
) {
  OpportunityTriggerHandler objHandler = new OpportunityTriggerHandler();
  if (Trigger.isBefore) {
    if (Trigger.isInsert) {
      OpportunityTriggerHandler.onBeforeInsert(Trigger.new);
    }
    if (Trigger.isUpdate) {
    }
  }
  if (Trigger.isAfter) {
    if (Trigger.isInsert) {
      OpportunityTriggerHandler.onAfterInsert(Trigger.newMap);
    }
  }

}
