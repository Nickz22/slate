@isTest
public class AutoQuoteGenerationTest {
	
    private static Opportunity createData(String connectTo)
    {
        
        createPricebook();
        
        Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId();
        Account slate = new Account(Name = 'Slate Studios',RecordTypeId = rtId);
        Account client = new Account(Name = 'Client Account',RecordTypeId = rtId);
        insert new List<Account>{slate,client};
        
		Contact c = new Contact(FirstName = 'Test', LastName = 'Con', Email = 'testcon@test.com', AccountId = client.Id);
        insert c;
        
        SBQQ__Quote__c qu;
        
        if(connectTo == null)
            qu = createQuote(slate.Id,null,false);
        else if(connectTo == 'Client')
            qu = createQuote(client.Id,null,false);
            
        Id oppRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = oppRtId;
        opp.Name = 'Test';
        opp.AccountId = client.Id;
        opp.Lead_Producer__c = 'Cameron Krone';
        opp.Lead_Type__c = 'E-Commerce';
        opp.StageName = connectTo == 'Opp' ? 'Closed - Won' : 'Qualification';
        opp.CloseDate = System.today().addMonths(1);
        opp.Days__c = 1;
        insert opp;
        
        if(connectTo == 'Opp')
        {
            qu = createQuote(client.Id, opp.Id,true);
        }
        
        return opp;
    }
    
    private static void createPricebook()
    {
        Product2 p1 = new Product2(Name = 'Photographer', isActive = true, ProductCode = 'PHOTO');
        Product2 p2 = new Product2(Name = 'Stylist', isActive = true, ProductCode = 'Style');
        Product2 p3 = new Product2(Name = 'Studio Assistant', isActive = true, ProductCode = 'StdAsst');
        insert new List<Product2>{p1,p2,p3};
        
        Id pbId = Test.getStandardPricebookId();
            
        PricebookEntry pe1 = new PricebookEntry(Product2Id = p1.Id, Pricebook2Id = pbId, UnitPrice = 100, IsActive = true);
        PricebookEntry pe2 = new PricebookEntry(Product2Id = p2.Id, Pricebook2Id = pbId, UnitPrice = 200, IsActive = true);
        PricebookEntry pe3 = new PricebookEntry(Product2Id = p3.Id, Pricebook2Id = pbId, UnitPrice = 300, IsActive = true);
        insert new List<PricebookEntry>{pe1,pe2,pe3};
    }
    
    private static SBQQ__Quote__c createQuote(Id accId, Id oppId, boolean primary)
    {  
        SBQQ__Quote__c qt = new SBQQ__Quote__c();
        qt.SBQQ__Account__c = accId;
        qt.SBQQ__Opportunity2__c = oppId != null ? oppId : null;
        qt.Lead_Type__c = 'E-Commerce';
        qt.Is_Template__c = oppId != null ? false : true;
        qt.SBQQ__PriceBook__c = Test.getStandardPricebookId();
        qt.SBQQ__Primary__c = primary;
        qt.SBQQ__SubscriptionTerm__c = 1;
        insert qt;
        
        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
		for(PricebookEntry pe:[SELECT Id, Product2Id, UnitPrice FROM PricebookEntry])
        {
            SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
            ql.SBQQ__Product__c = pe.Product2Id;
            ql.SBQQ__ListPrice__c = pe.UnitPrice;
            ql.SBQQ__Quote__c = qt.Id;
            lines.add(ql);
        }
        insert lines;
            
        return qt;
    }
    
    static testMethod void testPreviousQuote()
    {
        Opportunity opp = createData('Opp');
        
        test.startTest();
        
        Opportunity opp2 = new Opportunity();
        opp2.RecordTypeId = opp.RecordTypeId;
        opp2.AccountId = opp.AccountId;
        opp2.Lead_Type__c = opp.Lead_Type__c;
        opp2.StageName = 'Qualification';
        opp2.Lead_Producer__c = opp.Lead_Producer__c;
        opp2.CloseDate = System.today().addMonths(1);
        opp2.Days__c = 1;
        insert opp2;
        
        test.stopTest();
        
        SBQQ__Quote__c clonedQuote = [SELECT Id, SBQQ__Primary__c, (SELECT SBQQ__Product__r.Name, SBQQ__ListPrice__c FROM SBQQ__LineItems__r) FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c =: opp2.Id LIMIT 1];
        
        System.assert(clonedQuote != null);
        System.assert(clonedQuote.SBQQ__Primary__c);
    }
    
    static testMethod void testAccTemplate()
    {
        test.startTest();
        
     		Opportunity opp = createData('Client');   
        
        test.stopTest();
        
        SBQQ__Quote__c clonedQuote = [SELECT Id, SBQQ__Primary__c, (SELECT SBQQ__Product__r.Name, SBQQ__ListPrice__c FROM SBQQ__LineItems__r) FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c =: opp.Id LIMIT 1];
        
        System.assert(clonedQuote != null);
        System.assert(clonedQuote.SBQQ__Primary__c);
    }
    
    static testMethod void testDefaultTemp()
    {
        test.startTest();
        
     		Opportunity opp = createData(null);   
        
        test.stopTest();
        
        SBQQ__Quote__c clonedQuote = [SELECT Id, SBQQ__Primary__c, (SELECT SBQQ__Product__r.Name, SBQQ__ListPrice__c FROM SBQQ__LineItems__r) FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c =: opp.Id LIMIT 1];
        
        System.assert(clonedQuote != null);
        System.assert(clonedQuote.SBQQ__Primary__c);
    }
    
    static testMethod void testSchedulable()
    {
        test.startTest();
        
        Datetime added = Datetime.now().addMinutes(2);
        String hour = String.valueOf(added.hour());
        String min = String.valueOf(added.minute()); 
        String ss = String.valueOf(added.second());
        
        //parse to cron expression
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        
        System.schedule('CreateAutoQuoteLines_test', nextFireTime, new CreateAutoQuoteLines_Schedule(quoteLines));
        
        test.stopTest();
    }
}