trigger QuoteTrigger on SBQQ__Quote__c (after insert) {
    if(Trigger.IsAfter && Trigger.IsInsert){
        QuoteTriggerHandler.handleAfterInsert(Trigger.New);
    }
}