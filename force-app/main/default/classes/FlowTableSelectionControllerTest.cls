@isTest
private class FlowTableSelectionControllerTest {

	@testSetup private static void createData()
    {
        Product2 pr = new Product2();
        pr.Name = 'Photographer';
        pr.Cost__c = 100.0;
        pr.In_Round_Robin__c = true;
        insert pr;
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        
        Account free = new Account();
        free.Name = 'Freelancer';
        
        insert new List<Account>{acc,free};
        
        Contact c = new Contact();
        c.FirstName = 'Test';
        c.LastName = 'Con';
        c.AccountId = acc.Id;
        c.Email = 'testcon@test.com';
        
        Contact c2 = new Contact();
        c2.FirstName = 'Sir';
        c2.LastName = 'Photographer';
        c2.Email = 'test@test.com';
        c2.AccountId = free.Id;
        c2.Service_Type__c = 'Photographer';
        
        Contact c3 = new Contact();
        c3.FirstName = 'Sir';
        c3.LastName = 'Photographer2';
        c3.Email = 'test2@test.com';
        c3.AccountId = free.Id;
        c3.Service_Type__c = 'Photographer';
        
        Contact c4 = new Contact();
        c4.FirstName = 'Sir';
        c4.LastName = 'Photographer3';
        c4.Email = 'test3@test.com';
        c4.AccountId = free.Id;
        c4.Service_Type__c = 'Photographer';
        
        insert new List<Contact>{c,c2,c3,c4};
            
        Account_Team__c at = new Account_Team__c();
        at.Name = 'AT1';
        at.Team_Member__c = c2.Id;
        at.Service_Type__c = 'Photographer';
        at.Day_Rate__c = 200;
        at.Half_Day_Rate__c = 100;
        at.Active__c = true;
        at.Vetted__c = true;
        at.Account__c = acc.Id;
        
        Account_Team__c at2 = new Account_Team__c();
        at2.Name = 'AT2';
        at2.Team_Member__c = c3.Id;
        at2.Service_Type__c = 'Photographer';
        at2.Day_Rate__c = 200;
        at2.Half_Day_Rate__c = 100;
        at2.Active__c = true;
        at2.Vetted__c = true;
        at2.Account__c = acc.Id;
        
        Account_Team__c at3 = new Account_Team__c();
        at3.Name = 'AT3';
        at3.Team_Member__c = c4.Id;
        at3.Service_Type__c = 'Photographer';
        at3.Day_Rate__c = 200;
        at3.Half_Day_Rate__c = 100;
        at3.Active__c = true;
        at3.Vetted__c = true;
        at3.Account__c = acc.Id;
        
        insert new List<Account_Team__c>{at,at2,at3};
        
        Opportunity opp = new Opportunity();
        opp.Name = 'TestOpp';
        opp.StageName = 'Qualification';
        opp.CloseDate = system.today().addDays(10);
        opp.AccountId = acc.Id;
        opp.Lead_Producer__c = 'Cameron Krone';
        opp.Lead_Producer_Email__c = 'test@produceremail.com';
        opp.Shoot_Date__c = System.today();
        opp.Lead_Type__c = 'E-Commerce';
        insert opp;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Opportunity2__c = opp.Id;
        quote.SBQQ__Primary__c = true;
        insert quote;
        
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
        ql.SBQQ__Product__c = pr.Id;
        ql.SBQQ__Quote__c = quote.Id;
        ql.SBQQ__Quantity__c = 2;
        ql.Lead_Type__c = 'E-Commerce';
        ql.SBQQ__UnitCost__c = 300;
        ql.In_Round_Robin__c = true;
        insert ql;
        
        createPrjFiles(opp.Id);
    }
    
    private static void createPrjFiles(String oppId)
    {
        Project_Files__c photoFiles = new Project_Files__c();
        photoFiles.Opportunity__c = oppId;
        photoFiles.RecordTypeId = Schema.SObjectType.Project_Files__c.getRecordTypeInfosByName().get('Shared').getRecordTypeId();
        photoFiles.Service_Type__c = 'Photographer';
        
        Project_Files__c allFiles = new Project_Files__c();
        allFiles.Opportunity__c = oppId;
        allFiles.RecordTypeId = Schema.SObjectType.Project_Files__c.getRecordTypeInfosByName().get('Shared').getRecordTypeId();
        allFiles.Service_Type__c = 'All';
        
        insert new List<Project_Files__c>{photoFiles,allFiles};
            
        /////Create Test Content/////
        
        ContentVersion cvPhoto = new ContentVersion();
        cvPhoto.Title = 'ForPhoto';
        cvPhoto.PathOnClient = 'ForPhoto.pdf';
        cvPhoto.VersionData = Blob.valueOf('This is a test file for photographers.');
        cvPhoto.Origin = 'H';
        
        ContentVersion cvAll = new ContentVersion();
        cvAll.Title = 'ForAll';
        cvAll.PathOnClient = 'ForAll.pdf';
        cvAll.VersionData = Blob.valueOf('This is a test file for all.');
        cvAll.Origin = 'H';
        
        insert new List<ContentVersion>{cvPhoto,cvAll};
        
        ////Link Test Content/////
        List<ContentVersion> conVersions = [SELECT Id, Title, ContentDocumentId FROM ContentVersion LIMIT 2];
        
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        
        for(ContentVersion cv:conVersions)
        {
            if(cv.Title.containsIgnoreCase('Photo')){
                ContentDocumentLink cl = new ContentDocumentLink();
                cl.LinkedEntityId = photoFiles.Id;
                cl.ContentDocumentId = cv.ContentDocumentId;
                cl.ShareType = 'V';
                links.add(cl);
            }
            else{
                ContentDocumentLink cl2 = new ContentDocumentLink();
                cl2.LinkedEntityId = allFiles.Id;
                cl2.ContentDocumentId = cv.ContentDocumentId;
                cl2.ShareType = 'V';
                links.add(cl2);
            }
        }
        
        insert links;
    }

    @isTest
    static void testGetRecordsToDisplayInTableReturnTableRowsForQuoteLineItem() {
		SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c limit 1];
		String where_clause = '';
		String sobject_name = 'Account_Team__c';
		String field_set_name = 'Flow_Table_Fields';

        Test.startTest();
            FlowTableSelectionController.ApexMethodResult result = FlowTableSelectionController.getRecordsToDisplayInTable(sobject_name, field_set_name, where_clause,quote.Id);
        Test.stopTest();

        //System.assertEquals(true, result.Success);
		//System.assertEquals(3, result.TableRows.size());
    }

	@isTest
    static void testGetRecordsToDisplayInTableReturnErrorForBadOjbect() {
		SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c limit 1];
		String where_clause = '';
		String sobject_name = 'Bad';
		String field_set_name = 'Flow_Table_Fields';

        Test.startTest();
            FlowTableSelectionController.ApexMethodResult result = FlowTableSelectionController.getRecordsToDisplayInTable(sobject_name, field_set_name, where_clause,quote.Id);
        Test.stopTest();

        System.assertEquals(false, result.Success);
		System.assertEquals('Bad object specified Bad', result.ErrorMessage);
		System.assertEquals(0, result.TableRows.size());
    }

	@isTest
    static void testGetRecordsToDisplayInTableReturnErrorForBadFieldSet() {
		SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c limit 1];
		String where_clause = '';
		String sobject_name = 'Account_Team__c';
		String field_set_name = 'Bad';

        Test.startTest();
            FlowTableSelectionController.ApexMethodResult result = FlowTableSelectionController.getRecordsToDisplayInTable(sobject_name, field_set_name, where_clause,quote.Id);
        Test.stopTest();

        System.assertEquals(false, result.Success);
		System.assertEquals('Can\'t find fieldset Bad', result.ErrorMessage);
		System.assertEquals(0, result.TableRows.size());
    }

	@isTest
    static void testGetRecordsToDisplayInTableReturnNoResultsQuotes() {
        Account_Team__c accountTeam = [SELECT Id FROM Account_Team__c limit 1];
		SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c limit 1];
		String where_clause = 'Account__c';
		String sobject_name = 'Account_Team__c';
		String field_set_name = 'Flow_Table_Fields';

        Test.startTest();
        //FlowTableSelectionController.TableRow((sObject)accountTeam, 'Flow_Table_Fields');
            FlowTableSelectionController.ApexMethodResult result = FlowTableSelectionController.getRecordsToDisplayInTable(sobject_name, field_set_name, where_clause,quote.Id);
        Test.stopTest();

        //System.assertEquals(true, result.Success);
		System.assertEquals(0, result.TableRows.size());
    }

}