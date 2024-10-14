trigger QuoteLineItemTrigger on SBQQ__QuoteLine__c (after insert, after update) {
    if(Trigger.IsInsert){
        QuoteLineItemTriggerHandler.handleAfterInsert(Trigger.New);
    }else if(Trigger.IsUpdate){
        QuoteLineItemTriggerHandler.handleAfterUpdate(Trigger.New, Trigger.OldMap);
    }
}