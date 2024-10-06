public class LeadTriggerHandler {
    
    private static Boolean convertIsScheduled = Label.Typeform_Lead_Convert == 'on' || Test.isRunningTest() ? false : true;
    
    public static void onAfterInsert(List<Lead> newLeads)
    {
        for(Lead ld:newLeads)
        {
            if(ld.isTypeForm__c && !convertIsScheduled)
            	scheduleConverter();
        }
    }
    
    public static void onAfterUpdate(Map<Id, Lead> updated, Map<Id, Lead> previous)
    {
        for(Lead ld:updated.values())
        {
            if(ld.isTypeForm__c && !previous.get(ld.Id).isTypeForm__c && !convertIsScheduled)
                scheduleConverter();
        }
    }
    
    private static void scheduleConverter()
    {
        Datetime added = Datetime.now().addMinutes(10);
        String hour = String.valueOf(added.hour());
        String min = String.valueOf(added.minute()); 
        String ss = String.valueOf(added.second());
        
        //parse to cron expression
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        
        System.schedule('TypeformLeadConvert_' + String.valueOf(Datetime.now()), nextFireTime, new TypeformLeadConvert_Schedule());
        
        convertIsScheduled = true;
    }
}