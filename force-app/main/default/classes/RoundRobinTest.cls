@isTest
public class RoundRobinTest {
    private static void createData()
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
        opp.Lead_Type__c = 'E-Commerce';
        opp.Shoot_Date__c = System.today();
        opp.Shoot_Date_2__c = System.today() + 1;
        opp.Continuous__c = true;
        opp.Days__c = 2;
        insert opp;
        System.debug('RR OppId' + opp.Id);
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Account__c = opp.AccountId;
        quote.SBQQ__Opportunity2__c = opp.Id;
        quote.SBQQ__Primary__c = true;
        quote.Days_on_Project__c = 3;
        insert quote;
        System.debug('RR qId ' + quote.Id);
        
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
        ql.SBQQ__Product__c = pr.Id;
        ql.SBQQ__Quote__c = quote.Id;
        ql.SBQQ__Quantity__c = 2;
        ql.Lead_Type__c = 'E-Commerce';
        ql.SBQQ__UnitCost__c = 300;
        insert ql;
        System.debug('RR ql ' + ql);
        
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
    
    
    static testmethod void testRRController()
    {
        createData();
        
        Test.startTest();
        
        SBQQ__Quote__c q = [SELECT Id, (Select Id, SBQQ__ProductName__c FROM SBQQ__LineItems__r) FROM SBQQ__Quote__c LIMIT 1];
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
        ql.SBQQ__Product__c = [SELECT Id FROM Product2 LIMIT 1].Id;
        ql.SBQQ__Quote__c = q.Id;
        ql.SBQQ__Quantity__c = 2;
        ql.Lead_Type__c = 'E-Commerce';
        ql.SBQQ__UnitCost__c = 300;
        insert ql;
        System.debug('RR ql ' + ql);
        System.debug('RR Quote' + q);
        TeamRoundRobinController.startRoundRobin(new List<Id>{q.Id});
        
        Test.stopTest();
        
        List<Confirmed_Member__c> conf = [SELECT Status__c FROM Confirmed_Member__c WHERE Quote__c =: q.Id];
        System.assert(conf.size() == 3);
    }
    
    static testmethod void testRRReschedule()
    {
        createData();
        
        Opportunity opp = [SELECT Id, Shoot_Date__c, Shoot_Date_2__c FROM Opportunity LIMIT 1];
        Account_Team__c t = [SELECT Id, Email__c, Service_Type__c FROM Account_Team__c LIMIT 1];
        
        Test.startTest();
        
        SBQQ__Quote__c q = [SELECT Id, (Select Id, SBQQ__ProductName__c FROM SBQQ__LineItems__r) FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c =: opp.Id AND SBQQ__Primary__c = TRUE LIMIT 1];
        System.debug(q.Id);
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
        ql.SBQQ__Product__c = [SELECT Id FROM Product2 LIMIT 1].Id;
        ql.SBQQ__Quote__c = q.Id;
        ql.SBQQ__Quantity__c = 2;
        ql.Lead_Type__c = 'E-Commerce';
        ql.SBQQ__UnitCost__c = 300;
        insert ql;
        
        Confirmed_Member__c mbr = new Confirmed_Member__c();
        mbr.Account_Team_Member__c = t.Id;
        mbr.Quote__c = q.Id;
        mbr.Status__c = 'Confirmed';
        mbr.Start_Date__c = system.today();
        mbr.End_Date__c = system.today().addDays(2);
        mbr.Confirmed_Rate__c = 200;
        mbr.Quote_Line__c = ql.Id;
        insert mbr;
        

        opp.Shoot_Date_2__c = opp.Shoot_Date_2__c.addDays(1);
        opp.Shoot_Date__c = opp.Shoot_Date__c.addDays(1);
        update opp;
        
        Test.stopTest();
    }
    
    static testmethod void testManualRR()
    {
        createData();

        List<Account_Team__c> team = [SELECT Id, Account__c FROM Account_Team__c];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId =: team[0].Account__c LIMIT 1];
        
        Test.startTest();
        
        SBQQ__Quote__c q = [SELECT Id, (Select Id, SBQQ__ProductName__c FROM SBQQ__LineItems__r) FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c =: opp.Id AND SBQQ__Primary__c = TRUE LIMIT 1];
        System.debug(q.Id);
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
        ql.SBQQ__Product__c = [SELECT Id FROM Product2 LIMIT 1].Id;
        ql.SBQQ__Quote__c = q.Id;
        ql.SBQQ__Quantity__c = 2;
        ql.Lead_Type__c = 'E-Commerce';
        ql.SBQQ__UnitCost__c = 300;
        insert ql;
        
        ManualTeamRoundRobinController.manualRoundRobinRequest req = new ManualTeamRoundRobinController.manualRoundRobinRequest();
        req.quoteId = q.Id;
        req.accountTeamIds = team[0].Id + ';' + team[1].Id;
        
        ManualTeamRoundRobinController.startManualRoundRobin(new List<ManualTeamRoundRobinController.manualRoundRobinRequest>{req});
        
        Test.stopTest();
        
    }
    
    //////Start Availability Response Test Scenarios///////
    
    static testmethod void testRRHandlerAvlYes()
    {
        createData();
        
        SBQQ__Quote__c q = [SELECT Id, SBQQ__Opportunity2__r.Name FROM SBQQ__Quote__c LIMIT 1];
        Account_Team__c t = [SELECT Id, Email__c, Service_Type__c FROM Account_Team__c LIMIT 1];
        
        Test.startTest();
        
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
        ql.SBQQ__Product__c = [SELECT Id FROM Product2 LIMIT 1].Id;
        ql.SBQQ__Quote__c = q.Id;
        ql.SBQQ__Quantity__c = 2;
        ql.Lead_Type__c = 'E-Commerce';
        ql.SBQQ__UnitCost__c = 300;
        insert ql;
        
        Confirmed_Member__c mbr = new Confirmed_Member__c();
        mbr.Account_Team_Member__c = t.Id;
        mbr.Quote__c = q.Id;
        mbr.Status__c = 'Email Sent';
        mbr.Start_Date__c = system.today();
        mbr.End_Date__c = system.today().addDays(2);
        mbr.Confirmed_Rate__c = 200;
        mbr.Quote_Line__c = ql.Id;
        insert mbr;
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email.subject = 'RE: Slate Studios: ' + q.SBQQ__Opportunity2__r.Name + ' | ' + t.Service_Type__c + ' | ' + 'Availability';
        email.fromAddress = t.Email__c;
        email.plainTextBody = 'Yes';
        
        TeamRoundRobinHandler hnd = new TeamRoundRobinHandler();
        hnd.handleInboundEmail(email, env);
        
        Test.stopTest();
        
        mbr = [SELECT Status__c FROM Confirmed_Member__c WHERE Id =: mbr.Id];
        System.assertEquals('Available', mbr.Status__c);
    }
    
    static testmethod void testRRHandlerAvlManual()
    {
        createData();
        
        SBQQ__Quote__c q = [SELECT Id, SBQQ__Opportunity2__r.Name FROM SBQQ__Quote__c LIMIT 1];
        Account_Team__c t = [SELECT Id, Email__c, Service_Type__c FROM Account_Team__c LIMIT 1];
        
        Test.startTest();
        
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
        ql.SBQQ__Product__c = [SELECT Id FROM Product2 LIMIT 1].Id;
        ql.SBQQ__Quote__c = q.Id;
        ql.SBQQ__Quantity__c = 2;
        ql.Lead_Type__c = 'E-Commerce';
        ql.SBQQ__UnitCost__c = 300;
        insert ql;
        
        Confirmed_Member__c mbr = new Confirmed_Member__c();
        mbr.Account_Team_Member__c = t.Id;
        mbr.Quote__c = q.Id;
        mbr.Status__c = 'Email Sent';
        mbr.Start_Date__c = system.today();
        mbr.End_Date__c = system.today().addDays(2);
        mbr.Confirmed_Rate__c = 200;
        mbr.Quote_Line__c = ql.Id;
        insert mbr;
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email.subject = 'RE: Slate Studios: ' + q.SBQQ__Opportunity2__r.Name + ' | ' + t.Service_Type__c + ' | ' + 'Availability';
        email.fromAddress = t.Email__c;
        email.plainTextBody = 'What is this for?';
        
        TeamRoundRobinHandler hnd = new TeamRoundRobinHandler();
        hnd.handleInboundEmail(email, env);
        
        Test.stopTest();
        
        mbr = [SELECT Status__c FROM Confirmed_Member__c WHERE Id =: mbr.Id];
        System.assertEquals('Manual Review', mbr.Status__c);
    }
    
    static testmethod void testRRHandlerAvlNo()
    {
        createData();
        
        SBQQ__Quote__c q = [SELECT Id, SBQQ__Opportunity2__r.Name FROM SBQQ__Quote__c LIMIT 1];
        List<Account_Team__c> mbmrs = [SELECT Id, Email__c, Service_Type__c FROM Account_Team__c];
        
        Test.startTest();
        
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
        ql.SBQQ__Product__c = [SELECT Id FROM Product2 LIMIT 1].Id;
        ql.SBQQ__Quote__c = q.Id;
        ql.SBQQ__Quantity__c = 2;
        ql.Lead_Type__c = 'E-Commerce';
        ql.SBQQ__UnitCost__c = 300;
        insert ql;
        
        Confirmed_Member__c mbr = new Confirmed_Member__c();
        mbr.Account_Team_Member__c = mbmrs[0].Id;
        mbr.Quote__c = q.Id;
        mbr.Status__c = 'Email Sent';
        mbr.Start_Date__c = system.today();
        mbr.End_Date__c = system.today().addDays(2);
        mbr.Confirmed_Rate__c = 200;
        mbr.Quote_Line__c = ql.Id;
        
        Confirmed_Member__c mbr2 = new Confirmed_Member__c();
        mbr2.Account_Team_Member__c = mbmrs[1].Id;
        mbr2.Quote__c = q.Id;
        mbr2.Status__c = 'Queued';
        mbr2.Start_Date__c = system.today();
        mbr2.End_Date__c = system.today().addDays(2);
        mbr2.Confirmed_Rate__c = 200;
        mbr2.Quote_Line__c = ql.Id;
        
        insert new List<Confirmed_Member__c>{mbr,mbr2};
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email.subject = 'RE: Slate Studios: ' + q.SBQQ__Opportunity2__r.Name + ' | Photographer | Availability';
        email.fromAddress = mbmrs[0].Email__c;
        email.plainTextBody = 'Sorry, no I am not.';
        
        TeamRoundRobinHandler hnd = new TeamRoundRobinHandler();
        hnd.handleInboundEmail(email, env);
        
        Test.stopTest();
        
        mbr = [SELECT Status__c FROM Confirmed_Member__c WHERE Id =: mbr.Id];
        System.assertEquals('Rejected', mbr.Status__c);
        
        mbr2 = [SELECT Status__c FROM Confirmed_Member__c WHERE Id=: mbr2.Id];
        System.assertEquals('Email Sent', mbr2.Status__c);
    }
    
    //////End Availability Response Test Scenarios///////
    
    //////Start Re-Schedule Response Test Scenarios///////
    
    static testmethod void testRRHandlerRSYes()
    {
        createData();
        
        SBQQ__Quote__c q = [SELECT Id, SBQQ__Opportunity2__r.Name FROM SBQQ__Quote__c LIMIT 1];
        Account_Team__c t = [SELECT Id, Email__c, Service_Type__c FROM Account_Team__c LIMIT 1];
        
        Test.startTest();
        
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
        ql.SBQQ__Product__c = [SELECT Id FROM Product2 LIMIT 1].Id;
        ql.SBQQ__Quote__c = q.Id;
        ql.SBQQ__Quantity__c = 2;
        ql.Lead_Type__c = 'E-Commerce';
        ql.SBQQ__UnitCost__c = 300;
        insert ql;
        
        Confirmed_Member__c mbr = new Confirmed_Member__c();
        mbr.Account_Team_Member__c = t.Id;
        mbr.Quote__c = q.Id;
        mbr.Status__c = 'Re-Schedule Email Sent';
        mbr.Start_Date__c = system.today();
        mbr.End_Date__c = system.today().addDays(2);
        mbr.Confirmed_Rate__c = 200;
        mbr.Quote_Line__c = ql.Id;
        insert mbr;
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email.subject = 'RE: Slate Studios: ' + q.SBQQ__Opportunity2__r.Name + ' | ' + t.Service_Type__c + ' | ' + 'Re-Schedule Request';
        email.fromAddress = t.Email__c;
        email.plainTextBody = 'Yes';
        
        TeamRoundRobinHandler hnd = new TeamRoundRobinHandler();
        hnd.handleInboundEmail(email, env);
        
        Test.stopTest();
        
        mbr = [SELECT Status__c FROM Confirmed_Member__c WHERE Id =: mbr.Id];
        System.assertEquals('Confirmed', mbr.Status__c);
    }
    
    static testmethod void testRRHandlerRSManual()
    {
        createData();
        
        SBQQ__Quote__c q = [SELECT Id, SBQQ__Opportunity2__r.Name FROM SBQQ__Quote__c LIMIT 1];
        Account_Team__c t = [SELECT Id, Email__c, Service_Type__c FROM Account_Team__c LIMIT 1];
        
        Test.startTest();
        
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
        ql.SBQQ__Product__c = [SELECT Id FROM Product2 LIMIT 1].Id;
        ql.SBQQ__Quote__c = q.Id;
        ql.SBQQ__Quantity__c = 2;
        ql.Lead_Type__c = 'E-Commerce';
        ql.SBQQ__UnitCost__c = 300;
        insert ql;
        
        Confirmed_Member__c mbr = new Confirmed_Member__c();
        mbr.Account_Team_Member__c = t.Id;
        mbr.Quote__c = q.Id;
        mbr.Status__c = 'Re-Schedule Email Sent';
        mbr.Start_Date__c = system.today();
        mbr.End_Date__c = system.today().addDays(2);
        mbr.Confirmed_Rate__c = 200;
        mbr.Quote_Line__c = ql.Id;
        insert mbr;
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email.subject = 'RE: Slate Studios: ' + q.SBQQ__Opportunity2__r.Name + ' | ' + t.Service_Type__c + ' | ' + 'Re-Schedule Request';
        email.fromAddress = t.Email__c;
        email.plainTextBody = 'What is this for?';
        
        TeamRoundRobinHandler hnd = new TeamRoundRobinHandler();
        hnd.handleInboundEmail(email, env);
        
        Test.stopTest();
        
        mbr = [SELECT Status__c FROM Confirmed_Member__c WHERE Id =: mbr.Id];
        System.assertEquals('Manual Review', mbr.Status__c);
    }
    
    static testmethod void testRRHandlerRSNo()
    {
        createData();
        
        SBQQ__Quote__c q = [SELECT Id, SBQQ__Opportunity2__r.Name FROM SBQQ__Quote__c LIMIT 1];
        List<Account_Team__c> mbmrs = [SELECT Id, Email__c, Service_Type__c FROM Account_Team__c];
        
        Test.startTest();
        
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
        ql.SBQQ__Product__c = [SELECT Id FROM Product2 LIMIT 1].Id;
        ql.SBQQ__Quote__c = q.Id;
        ql.SBQQ__Quantity__c = 2;
        ql.Lead_Type__c = 'E-Commerce';
        ql.SBQQ__UnitCost__c = 300;
        insert ql;
        
        Confirmed_Member__c mbr = new Confirmed_Member__c();
        mbr.Account_Team_Member__c = mbmrs[0].Id;
        mbr.Quote__c = q.Id;
        mbr.Status__c = 'Re-Schedule Email Sent';
        mbr.Start_Date__c = system.today();
        mbr.End_Date__c = system.today().addDays(2);
        mbr.Confirmed_Rate__c = 200;
        mbr.Quote_Line__c = ql.Id;
        
        Confirmed_Member__c mbr2 = new Confirmed_Member__c();
        mbr2.Account_Team_Member__c = mbmrs[1].Id;
        mbr2.Quote__c = q.Id;
        mbr2.Status__c = 'Queued';
        mbr2.Start_Date__c = system.today();
        mbr2.End_Date__c = system.today().addDays(2);
        mbr2.Confirmed_Rate__c = 200;
        mbr2.Quote_Line__c = ql.Id;
        
        insert new List<Confirmed_Member__c>{mbr,mbr2};
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email.subject = 'RE: Slate Studios: ' + q.SBQQ__Opportunity2__r.Name + ' | Photographer | Re-Schedule Request';
        email.fromAddress = mbmrs[0].Email__c;
        email.plainTextBody = 'Sorry, no I am not.';
        
        TeamRoundRobinHandler hnd = new TeamRoundRobinHandler();
        hnd.handleInboundEmail(email, env);
        
        Test.stopTest();
        
        mbr = [SELECT Status__c FROM Confirmed_Member__c WHERE Id =: mbr.Id];
        System.assertEquals('Re-Schedule Rejected', mbr.Status__c);
        
        mbr2 = [SELECT Status__c FROM Confirmed_Member__c WHERE Id=: mbr2.Id];
        System.assertEquals('Email Sent', mbr2.Status__c);
    }
    
    //////End Availability Response Test Scenarios///////
    
    static testmethod void testRRConfirmations()
    {
        createData();
        
        SBQQ__Quote__c q = [SELECT Id, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Name FROM SBQQ__Quote__c LIMIT 1];
        Account_Team__c t = [SELECT Id, Email__c, Service_Type__c FROM Account_Team__c LIMIT 1];
        
        Test.startTest();
        
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
        ql.SBQQ__Product__c = [SELECT Id FROM Product2 LIMIT 1].Id;
        ql.SBQQ__Quote__c = q.Id;
        ql.SBQQ__Quantity__c = 2;
        ql.Lead_Type__c = 'E-Commerce';
        ql.SBQQ__UnitCost__c = 300;
        insert ql;
        
        Confirmed_Member__c mbr = new Confirmed_Member__c();
        mbr.Account_Team_Member__c = t.Id;
        mbr.Quote__c = q.Id;
        mbr.Status__c = 'Available';
        mbr.Start_Date__c = system.today();
        mbr.End_Date__c = system.today().addDays(2);
        mbr.Confirmed_Rate__c = 200;
        mbr.Quote_Line__c = ql.Id;
        insert mbr;
        
        TeamRoundRobinConfirmations.sendConfirmation(new List<Id>{q.Id});
        
        Test.stopTest();
        
        mbr = [SELECT Status__c FROM Confirmed_Member__c WHERE Id =: mbr.Id];
        System.assertEquals('Confirmed', mbr.Status__c);
        
        /*
        CallSheet__c callSheet = new CallSheet__c();
                callSheet.Name = q.SBQQ__Opportunity2__r.Name;
                callSheet.Opportunity__c = q.SBQQ__Opportunity2__c;
                insert callSheet;
        Call_Sheet_Prospect__c callSheetp = [SELECT Id,Call_Sheet__c FROM Call_Sheet_Prospect__c WHERE Confirmed_Member__c =: mbr.Id LIMIT 1];
        callSheetp.Call_Sheet__c = callSheet.Id;
        update callSheetp;
          PDFGenerationService.generatePDF(callSheet.id);
          pagereference pdf = page.GenerateInvoicePDF;
          pdf.getParameters().put('Id',callSheetp.id);
          try{
          GenerateInvoicePDFController obj = new GenerateInvoicePDFController();
          }catch(Exception e){}
		*/
    }
    
}