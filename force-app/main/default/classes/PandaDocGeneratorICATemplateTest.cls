@isTest
public class PandaDocGeneratorICATemplateTest {
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
    
    @isTest
    static void pandaDocGeneratorICATemplateTest(){
        Test.setMock(HttpCalloutMock.class, new Mock());
        Account accRec = new Account(Name = 'TestAccount');
        Insert accRec;
        
        Contact conRec = new Contact(FirstName = 'test', LastName = 'Test1', Email='test@testc.om', AccountId = accRec.Id);
        Insert conRec;
        
        Id oppRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = oppRtId;
        opp.Name = 'Test';
        opp.AccountId = accRec.Id;
        opp.Lead_Producer__c = 'Cameron Krone';
        opp.Lead_Type__c = 'E-Commerce';
        opp.Service_Type_Sub_Type__c = 'Product';
        opp.StageName =  'Closed - Won';
        opp.CloseDate = System.today().addMonths(1);
        opp.Days__c = 1;
        insert opp;
        
        CallSheet__c callSheetRec = new CallSheet__c(Name = 'Test1', Opportunity__c = opp.Id);
        Insert callSheetRec;
        
        Call_Sheet_Prospect__c callProspect = new Call_Sheet_Prospect__c(Call_Sheet__c = callSheetRec.Id, Contact__c = conRec.Id);
        Insert callProspect;
        
        Test.startTest();
        PandaDocGeneratorICATemplate.getTemplateList();
        PandaDocGeneratorICATemplate.getDocumentList('test');
        PandaDocGeneratorICATemplate.getContactName(conRec.Id);
        PandaDocGeneratorICATemplate.getOpportunityName(callSheetRec.Id);
        PandaDocGeneratorICATemplate.createICAPandaDoc(conRec.Id);
        PandaDocGeneratorICATemplate.createCallSheetDocument(callSheetRec.Id);
        PandaDocGeneratorICATemplate.sendDocument('docId');
        Test.stopTest();
    }
}