public class TypeformLeadConvert_Schedule implements Schedulable {
    
    public void execute(SchedulableContext sc)
    {
        Database.executeBatch(new TypeformLeadConvert_Batch(), 1);
        
        System.abortJob(sc.getTriggerId());
    }

}