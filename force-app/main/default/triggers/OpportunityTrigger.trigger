trigger OpportunityTrigger on Opportunity (before insert, after insert, before update, after update) {  
    OpportunityTriggerHandler objHandler = new OpportunityTriggerHandler();
    if(trigger.isBefore){
        if(trigger.isInsert){
            objHandler.OnBeforeInsertObj(trigger.New);
            OpportunityTriggerHandler.onBeforeInsert(trigger.new);
        }
        if(trigger.isUpdate){
            objHandler.OnBeforeUpdate(trigger.newMap,trigger.oldMap);
        }
    }
    if(trigger.isAfter){
        if(trigger.isInsert){
            objHandler.OnAfterInsertObj(trigger.newMap);
            OpportunityTriggerHandler.onAfterInsert(trigger.newMap);
            //OpportunityTriggerHelper.AfterInsert(trigger.newMap,trigger.oldMap);
        }  
        if(trigger.isUpdate){
            objHandler.OnAfterUpdate(trigger.newMap,trigger.oldMap);
        }
    }
    
}