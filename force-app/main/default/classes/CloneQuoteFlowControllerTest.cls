@isTest
private  class CloneQuoteFlowControllerTest {
    @testSetup
    private static void createData(){
        Account testAccount= new Account(name='Test Account',BillingCity='Wilmington');
		insert testAccount;
        Opportunity testOpp = new Opportunity(name='Test Opportunity', 
                                              AccountId=testAccount.Id,
                                              StageName='Prospecting',
                                              closeDate=System.today(),
                                              Lead_Type__c='Slate - CGI');
        insert testOpp;
    }

    @isTest 
    private static void cloneQuoteTest(){
        Test.startTest();
        SBQQ__Quote__c q = [SELECT Id, Name FROM SBQQ__Quote__c LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(q);
        CloneQuoteFlowController cqfc = new CloneQuoteFlowController(sc);
        Pagereference pr = cqfc.cloneQuote();
        System.assertNotEquals(null, cqfc.newRecordId);
        Test.stopTest();
    }
}