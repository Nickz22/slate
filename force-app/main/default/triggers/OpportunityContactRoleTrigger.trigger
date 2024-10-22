trigger OpportunityContactRoleTrigger on OpportunityContactRole (after insert, after update) {

    if(Trigger.IsAfter && Trigger.IsInsert){
        OCRTriggerHandler.handleAfterInsert(Trigger.New);
    }else if(Trigger.IsAfter && Trigger.IsUpdate){
        OCRTriggerHandler.handleAfterUpdate(Trigger.New, Trigger.oldMap);
    }
}