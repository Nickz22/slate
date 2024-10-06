/*
 * Name: PandaDocControllerTest
 * Description: Test to check send estimation flow
 */
@isTest
public class PandaDocControllerTest {
    private class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            if (req.getEndpoint().contains('templates') && req.getMethod() == 'GET') {
                res.setBody('{"results":[{"id":"UgNqHrtsGFqTSk8wtdzqPM","name":"API Sample Document from PandaDoc Template","date_created":"2017-08-06T08:42:13.836022Z","date_modified":"2017-09-04T02:21:13.963750Z","version":"1"}]}');
                res.setStatusCode(200);
            } else if (req.getEndpoint().contains('documents') && req.getMethod() == 'GET') {
                res.setBody('{"results":[{"id":"UgNqHrtsGFqTSk8wtdzqPM","name":"API Sample Document from PandaDoc Template","date_created":"2017-08-06T08:42:13.836022Z","date_modified":"2017-09-04T02:21:13.963750Z","version":"1"}]}');
                res.setStatusCode(200);
            } else if (req.getEndpoint().contains('documents') && req.getMethod() == 'POST') {
                res.setBody('{"id":"UgNqHrtsGFqTSk8wtdzqPM","name":"API Sample Document from PandaDoc Template","date_created":"2017-08-06T08:42:13.836022Z","date_modified":"2017-09-04T02:21:13.963750Z","version":"1"}');
                res.setStatusCode(201);
            } else if (req.getEndpoint().contains('documents') && req.getEndpoint().contains('send') && req.getMethod() == 'POST') {
                res.setBody('{"results":[{"id":"UgNqHrtsGFqTSk8wtdzqPM","name":"API Sample Document from PandaDoc Template","date_created":"2017-08-06T08:42:13.836022Z","date_modified":"2017-09-04T02:21:13.963750Z","version":"1"}]}');
                res.setStatusCode(200);
            }
            return res;
        }
    }
    @testSetup
    private static void createData(){
        Account testAccount= new Account(name='Test Account',BillingCity='Wilmington');
		insert testAccount;
        Contact contact = new Contact(
            LastName= 'ContactTest',
            AccountId = testAccount.Id,
            Email = 'test@slatest-nyc.com'
        );
        insert contact;
        /*Account_Team__c at = new Account_Team__c(
            Account__c = testAccount.Id,
            Name = 'Account Team Test'
        );
        insert at;*/
        Opportunity testOpp = new Opportunity(name='Test Opportunity', 
                                              AccountId=testAccount.Id,
                                              StageName='Prospecting',
                                              closeDate=System.today(),
                                              Lead_Type__c='Slate - CGI',
                                              ContactId = contact.Id);
        insert testOpp;
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = testOpp.Id
        );
        insert quote;  

        Product2 pr = new Product2();
        pr.Name = 'Photographer';
        pr.Cost__c = 100.0;
        pr.In_Round_Robin__c = true;
        insert pr;  

        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c= quote.id,
            SBQQ__Product__c = pr.Id,
            SBQQ__Quantity__c = 2,
            Lead_Type__c = 'E-Commerce',
            SBQQ__UnitCost__c = 300
        );
        insert ql;
        insert new EndpointSetup__c(PandaDocAPIKey__c = 'apiKey', Name = 'API Keys');
    }

    @isTest 
    private static void getTemplatesTest(){
        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        PandaDocController.getTemplates();
        Test.stopTest();
    }

    @isTest 
    private static void getTemplatesErrorTest(){
        Test.startTest();
        PandaDocController.getTemplates();
        Test.stopTest();
    }

    @isTest 
    private static void generateEstimationTest(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        PandaDocController.generateEstimation(new List<String>{opp.Id + ';true'});
        Test.stopTest();
    }

    @isTest 
    private static void sendEstimateTest(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        PandaDocManager.sendEstimate(new List<String>{'idTest'});
        Test.stopTest();
    }
}