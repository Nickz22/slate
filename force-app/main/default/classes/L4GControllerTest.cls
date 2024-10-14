@isTest
public class L4GControllerTest {
    
    @testSetup
    public static void makeData(){
        Opportunity opp = new Opportunity(Name = 'Slate Studios', CloseDate = Date.today(), StageName = 'Qualification - Project');
        insert opp;
        Account acc = new Account(Name = 'Test Slate Account');
        insert acc;
        Contact con = new Contact(LastName = 'LastName', AccountId = acc.Id, Email = 'test@slate.com', Service_Type__c = 'E-Commerce');
        insert con;
        insert new OpportunityContactRole(ContactId = con.Id, OpportunityId = opp.Id);
        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Primary__c = true, SBQQ__PrimaryContact__c = con.Id, SBQQ__Opportunity2__c = opp.Id);
        insert quote;
        opp.SBQQ__PrimaryQuote__c = quote.Id;
        opp.PrimaryContact__c = con.Id;
        update opp;
        
        insert new Division__c(Division_Leader__c = UserInfo.getUserId(), Name = 'Slate');
    }
    
    @isTest
    public static void testGetFieldSet(){
        Test.startTest();
        List<L4GController.FieldWrapper> fields = L4GController.getFieldSet('L4G_NewContact','Contact');
        Test.stopTest();
        Assert.isTrue(!fields.IsEmpty());
    }
    @isTest
    public static void testFetchLookupData(){
        Test.startTest();
        List<SObject> sobjList = L4GController.fetchLookupData('Test','Account');
        Test.stopTest();
        Assert.isTrue(!sobjList.IsEmpty());
    }
    @IsTest
    public static void testGetAccountId(){
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        Test.startTest();
        Id accId = L4GController.getAccountId('Test');
        Sobject accRecord = L4GController.fetchDefaultRecord(acc.Id,'Account');
        Test.stopTest();
        Assert.areEqual(acc.Name,(String)accRecord.get('Name'));
        Assert.areNotEqual(acc.Id, accId);
    }
    @isTest
    public static void testCheckIfContactExists(){
        Test.startTest();
        Map<String,String> existingContactsMap = L4GController.checkIfContactExists(new List<String>{'test@slate.com'});
        Test.stopTest();
        Assert.isTrue(existingContactsMap.containsKey('test@slate.com'));
    }
    @isTest
    public static void testCloneRecord(){
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Test.startTest();
        L4GController.cloneRecord(oppId, 'Test email body');
        Test.stopTest();
        Integer opportunityCount = [SELECT COUNT() FROM Opportunity];
        Assert.areEqual(2, opportunityCount);
    }
    @isTest
    public static void testGetFieldsToView(){
        Test.startTest();
        List<String> fields = L4GController.getFieldsToView('L4G_NewContact','Contact');
        Test.stopTest();
        Assert.isTrue(!fields.IsEmpty());
    }
    @isTest
    public static void testGetRelatedOpportunities(){
        Id conId = [Select id from Contact LIMIT 1].Id;
        Test.startTest();
        L4GController.getRelatedOpportunities(conId);
        Test.stopTest();
    }
    @isTest
    public static void testGetDivisionNames(){
        Test.startTest();
        List<String> divisions = L4GController.getDivisionNames();
        Test.stopTest();
        Assert.areEqual('Slate', divisions[0]);
    }
    @isTest
    public static void testGetPricebook(){
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;
        Test.startTest();
        List<Pricebook2> pricebooks = L4GController.getPricebook();
        Test.stopTest();
        Assert.areEqual(standardPricebook.Id, pricebooks[0].Id);
    }
    @isTest
    public static void testQuoteLineTrigger(){
        Id conId = [Select id from contact limit 1].Id;
        Id quoteId = [Select id from SBQQ__Quote__c limit 1].Id;
        Product2 product = new Product2(Name = 'Test Product');
        insert product;
        Test.startTest();
        insert new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteId, Vendor__c = conId, Lead_Type__c = 'E-Commerce', SBQQ__Product__c = product.Id);            
        Test.stopTest();
        List<OpportunityContactRole> oppContactRoles = [SELECT Id FROM OpportunityContactRole WHERE ContactId = :conId];
        Assert.isTrue(!oppContactRoles.isEmpty());
    }

}