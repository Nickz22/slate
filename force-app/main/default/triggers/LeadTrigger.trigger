trigger LeadTrigger on Lead(after insert, after update) {
  if (Trigger.isAfter) {
    if (Trigger.isInsert) {
      LeadTriggerHandler.onAfterInsert(Trigger.new);
    }
    if (Trigger.isUpdate) {
      LeadTriggerHandler.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
    }
  }

}
