public class AutoQuoteGeneration 
{
    private static Opportunity opp;
    private static SBQQ__Quote__c newQuote;
    //Entry function for auto quote generation
    public static void autoQuote(Id oppId)
    {
        opp = [SELECT Id, AccountId, Lead_Type__c, Pricebook2Id, OwnerId, CreatedDate, Days__c FROM Opportunity WHERE Id =: oppId];
        
        SBQQ__Quote__c autoQuote;
        
        System.debug('Prev Quote');
        autoQuote = getPreviousQuote(opp.Lead_Type__c,opp.AccountId);
		System.debug('Prev Return>>'+autoQuote);        
        if(autoQuote == null){
            System.debug('Account Temp');
            autoQuote = getAccountTemplate(opp.Lead_Type__c, opp.AccountId);
            System.debug('Account Temp Return>>'+autoQuote);
        }
        if(autoQuote == null){
            System.debug('Default');
            autoQuote = getDefaultQuote(opp.Lead_Type__c);
            System.debug('Default Return>>'+autoQuote);
        }
            
        createQuote();
        
        
        if(autoQuote != null)
        {
            System.debug('autoQuote>>' + autoQuote.Id);
            List<SBQQ__QuoteLine__c> quoteLines = duplicateLines(autoQuote);
            
            if(System.isBatch() || System.isFuture() || System.isQueueable())
            {
                Datetime added = Datetime.now().addMinutes(2);
                String hour = String.valueOf(added.hour());
                String min = String.valueOf(added.minute()); 
                String ss = String.valueOf(added.second());
                
                //parse to cron expression
                String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
                
                System.schedule('CreateAutoQuoteLines_' + newQuote.Id, nextFireTime, new CreateAutoQuoteLines_Schedule(quoteLines));
            }
            else
            	insert quoteLines;
            
            //recalculateQuote(new Set<Id>{newQuote.Id});
        }
    }
    
    private static SBQQ__Quote__c getPreviousQuote(String LeadType, Id AccountId)
    {
		List<SBQQ__Quote__c> prevQuote = [SELECT Id, SBQQ__Account__c, SBQQ__Opportunity2__c,
                                          SBQQ__PricebookId__c, 
                                          (SELECT SBQQ__Product__c, SBQQ__Quantity__c,
                                           SBQQ__UnitCost__c, SBQQ__ListPrice__c, SBQQ__SubscriptionTerm__c, SBQQ__SubscriptionPricing__c,
                                           SBQQ__Number__c, SBQQ__CustomerPrice__c, SBQQ__ProrateMultiplier__c,
                                           Client_Info__c, Producer_Notes__c, Team_Preference__c, In_Round_Robin__c,
                                           SBQQ__ProductSubscriptionType__c, SBQQ__DefaultSubscriptionTerm__c,
                                           SBQQ__SubscriptionType__c, SBQQ__SubscriptionScope__c, SBQQ__SubscriptionBase__c
                                           FROM SBQQ__LineItems__r ORDER BY SBQQ__Number__c ASC)
                                          FROM SBQQ__Quote__c WHERE SBQQ__Account__c =: AccountId 
                                          AND SBQQ__Opportunity2__r.Lead_Type__c =: LeadType 
                                          AND SBQQ__Opportunity2__r.StageName LIKE '%Won%'
                                          AND SBQQ__Primary__c = TRUE
                                          ORDER BY CreatedDate DESC LIMIT 1];
        
        
        if(prevQuote != null && !prevQuote.isEmpty())
            return prevQuote[0];
        else
            return null;
    }
    
    private static SBQQ__Quote__c getAccountTemplate(String LeadType, Id AccountId)
    {
        List<SBQQ__Quote__c> accountTemplate = [SELECT Id, SBQQ__Account__c, SBQQ__Opportunity2__c,
                                          		SBQQ__PricebookId__c, 
                                          		(SELECT SBQQ__Product__c, SBQQ__Quantity__c,
                                           		SBQQ__UnitCost__c, SBQQ__ListPrice__c, SBQQ__SubscriptionTerm__c, SBQQ__SubscriptionPricing__c,
                                           		SBQQ__Number__c, SBQQ__CustomerPrice__c, SBQQ__ProrateMultiplier__c,
                                           		Client_Info__c, Producer_Notes__c, Team_Preference__c, In_Round_Robin__c,
                                                SBQQ__ProductSubscriptionType__c, SBQQ__DefaultSubscriptionTerm__c,
                                                SBQQ__SubscriptionType__c, SBQQ__SubscriptionScope__c, SBQQ__SubscriptionBase__c
                                           		FROM SBQQ__LineItems__r ORDER BY SBQQ__Number__c ASC)
                                          		FROM SBQQ__Quote__c WHERE SBQQ__Account__c =: AccountId 
                                          		AND Is_Template__c = true
                                                AND Lead_Type__c =: LeadType LIMIT 1];
        
        if(accountTemplate != null && !accountTemplate.isEmpty())
        	return accountTemplate[0];
        else
            return null;
    }
    
    private static SBQQ__Quote__c getDefaultQuote(String LeadType)
    {
        String templateAccount;
        
        if(LeadType.containsIgnoreCase('Casablanca'))
            templateAccount = 'Casablanca Films';
        else if(LeadType.containsIgnoreCase('Palermo'))
            templateAccount = 'Palermo Studio';
        else if(LeadType.containsIgnoreCase('Align'))
        	templateAccount = 'Align Retouch';
        else
            templateAccount = System.Label.Quote_Template_Account;
        
        List<SBQQ__Quote__c> quoteTemplate = [SELECT Id, SBQQ__Account__c, SBQQ__Opportunity2__c,
                                              SBQQ__PricebookId__c, 
                                              (SELECT SBQQ__Product__c, SBQQ__Quantity__c,
                                           	  SBQQ__UnitCost__c, SBQQ__ListPrice__c, SBQQ__SubscriptionTerm__c, SBQQ__SubscriptionPricing__c,
                                           	  SBQQ__Number__c, SBQQ__CustomerPrice__c, SBQQ__ProrateMultiplier__c,
                                           	  Client_Info__c, Producer_Notes__c, Team_Preference__c, In_Round_Robin__c,
                                              SBQQ__ProductSubscriptionType__c, SBQQ__DefaultSubscriptionTerm__c,
                                              SBQQ__SubscriptionType__c, SBQQ__SubscriptionScope__c, SBQQ__SubscriptionBase__c
                                           	  FROM SBQQ__LineItems__r ORDER BY SBQQ__Number__c ASC)
                                              FROM SBQQ__Quote__c WHERE SBQQ__Account__r.Name =: templateAccount
                                              AND Is_Template__c = true
                                              AND Lead_Type__c =: LeadType LIMIT 1];
        
        
        if(quoteTemplate != null && !quoteTemplate.isEmpty())
            return quoteTemplate[0];
        else
            return null;
    }
    
    
    private static void createQuote()
    {
        newQuote = new SBQQ__Quote__c();
        
        newQuote.OwnerId = opp.OwnerId;
        newQuote.SBQQ__Account__c = opp.AccountId;
        newQuote.SBQQ__Opportunity2__c = opp.Id;
        newQuote.SBQQ__PricebookId__c = opp.Pricebook2Id;
        newQuote.SBQQ__Primary__c = true;
        newQuote.SBQQ__StartDate__c = opp.CreatedDate.date();
        newQuote.SBQQ__SubscriptionTerm__c = opp.Days__c;
        
        insert newQuote;
    }
    
    private static List<SBQQ__QuoteLine__c> duplicateLines(SBQQ__Quote__c toClone)
    {
        List<SBQQ__QuoteLine__c> newLines = new List<SBQQ__QuoteLine__c>();
        
        for(SBQQ__QuoteLine__c line:toClone.SBQQ__LineItems__r)
        {
            SBQQ__QuoteLine__c newLine = new SBQQ__QuoteLine__c();
            newLine.SBQQ__CostEditable__c = true;
            newLine.SBQQ__PriceEditable__c = true;
            newLine.SBQQ__Product__c = line.SBQQ__Product__c;
            newLine.SBQQ__Quantity__c = line.SBQQ__Quantity__c;
            newLine.SBQQ__Quote__c = newQuote.Id;
            newLine.SBQQ__UnitCost__c = line.SBQQ__UnitCost__c;
            newLine.SBQQ__ListPrice__c = line.SBQQ__ListPrice__c;
            newLine.SBQQ__CustomerPrice__c = line.SBQQ__CustomerPrice__c;
            newLine.Producer_Notes__c = line.Producer_Notes__c;
            newLine.Team_Preference__c = line.Team_Preference__c;
            newLine.In_Round_Robin__c = line.In_Round_Robin__c;
            newLine.SBQQ__Number__c = line.SBQQ__Number__c;
            newLine.Client_Info__c = line.Client_Info__c;
            newLine.SBQQ__ProductSubscriptionType__c = line.SBQQ__ProductSubscriptionType__c;
            newLine.SBQQ__DefaultSubscriptionTerm__c = line.SBQQ__DefaultSubscriptionTerm__c;
            newLine.SBQQ__SubscriptionType__c = line.SBQQ__SubscriptionType__c;
            newLine.SBQQ__SubscriptionTerm__c = line.SBQQ__SubscriptionTerm__c;
            newLine.SBQQ__SubscriptionScope__c = line.SBQQ__SubscriptionScope__c;
            newLine.SBQQ__SubscriptionBase__c = line.SBQQ__SubscriptionBase__c;
            newLine.SBQQ__SubscriptionPricing__c = line.SBQQ__SubscriptionPricing__c;
            
            newLines.add(newLine);
        }
        
        return newLines;
    }
    
    /*
    @Future(callout=true)
    public static void recalculateQuote(Set<Id> quoteId)
    {
        List<SBQQ__Quote__c> quotes = [SELECT Id, CPQ_Recalculate__c FROM SBQQ__Quote__c WHERE Id IN: quoteId];
        
        for(SBQQ__Quote__c q:quotes)
        {
            if(q.CPQ_Recalculate__c)
                q.CPQ_Recalculate__c = false;
            else
                q.CPQ_Recalculate__c = true;
        }
        
        if(!quotes.isEmpty())
            update quotes;
    }
	*/
}