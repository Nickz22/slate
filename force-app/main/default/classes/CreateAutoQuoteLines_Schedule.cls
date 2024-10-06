/*This schedulable is used to insert Quote Lines that are generated from the AutoQuoteGeneration class.
 *When in a Async context, inserting a quote and quote lines causes SF CPQ to enqueue 2 queueables which is not allowed.
 *Instead in an Async context (ex. Typeform Lead Conversion) we will insert the quote in the AutoQuoteGeneratio class and
 *then we will schedule this class insert the quote lines. This way we separate the transactions of inserting the quote and 
 *quote lines
*/
public class CreateAutoQuoteLines_Schedule implements Schedulable {
	
    public List<SBQQ__QuoteLine__c> lines;
    
    public CreateAutoQuoteLines_Schedule(List<SBQQ__QuoteLine__c> toInsert)
    {
        lines = toInsert;
    }
    
    public void execute(SchedulableContext sc){
        try
        {
        	insert lines;
        }Catch(Exception e){
            System.debug('Insert Quote Lines Error: ' + e);
            System.debug('Insert Quote Lines Error Stack: ' + e.getStackTraceString());
        }
        
        System.abortJob(sc.getTriggerId());
    }
}