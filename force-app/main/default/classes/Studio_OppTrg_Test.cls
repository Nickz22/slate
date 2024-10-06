@isTest
public class Studio_OppTrg_Test {

    static testmethod void method1(){
		Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;
        
        Opportunity opp1 = new Opportunity();
        opp1.Name = 'TestOpp1';
        opp1.StageName = 'Qualification';
        opp1.CloseDate = system.today().addDays(10);
        opp1.AccountId = acc.Id;
        opp1.Lead_Producer__c = 'Cameron Krone';
        opp1.Lead_Producer_Email__c = 'test@produceremail.com';
        opp1.Lead_Type__c = 'Slate - CGI';
        opp1.First_Hold_1__c = Date.newInstance(2022, 01, 25);
        opp1.First_Hold_2__c = Date.newInstance(2022, 01, 27);
        insert opp1;
        
        OpportunityTriggerHandler.ToCreateCalendarRecord = true;
        opp1.Continuous__c = false;
        opp1.Shoot_Hold_1__c = Date.newInstance(2022, 01, 28);
        opp1.Shoot_Hold_2__c = Date.newInstance(2022, 01, 30);
        update opp1;
        
        OpportunityTriggerHandler.ToCreateCalendarRecord = true;
        opp1.Shoot_Date__c = Date.newInstance(2022, 01, 28);
        opp1.Shoot_Date_2__c = Date.newInstance(2022, 01, 30);
        update opp1;
        
        Opportunity opp2 = new Opportunity();
        opp2.Name = 'TestOpp2';
        opp2.StageName = 'Qualification';
        opp2.CloseDate = system.today().addDays(10);
        opp2.AccountId = acc.Id;
        opp2.Lead_Producer__c = 'Cameron Krone';
        opp2.Lead_Producer_Email__c = 'test@produceremail.com';
        opp2.Lead_Type__c = 'E-Commerce';
        opp2.Continuous__c = false;
        opp2.First_Hold_1__c = Date.newInstance(2022, 01, 01);
        opp2.First_Hold_2__c = Date.newInstance(2022, 01, 02);
        opp2.Shoot_Hold_1__c = Date.newInstance(2022, 01, 03);
        opp2.Shoot_Hold_2__c = Date.newInstance(2022, 01, 04);
        OpportunityTriggerHandler.ToCreateCalendarRecord = true;
        insert opp2;
        
        OpportunityTriggerHandler.ToCreateCalendarRecord = true;
        opp2.First_Hold_1__c = null;
        opp2.First_Hold_2__c = null;
        opp2.Shoot_Hold_1__c = null;
        opp2.Shoot_Hold_2__c = null;
        update opp2;
        
        
        System.debug('Error '+[SELECT id,Component_Name__c, Component_Type__c, Error_Message__c, Error_Type__c, Record_Reference__c, Response_Request__c, CreatedDate from Error_Log__c]);
        
    }
    
    static testmethod void method2(){
		Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;
        
        Opportunity opp1 = new Opportunity();
        opp1.Name = 'TestOpp1';
        opp1.StageName = 'Qualification';
        opp1.CloseDate = system.today().addDays(10);
        opp1.AccountId = acc.Id;
        opp1.Lead_Producer__c = 'Cameron Krone';
        opp1.Lead_Producer_Email__c = 'test@produceremail.com';
        opp1.Lead_Type__c = 'Brand Content';
        opp1.First_Hold_1__c = Date.newInstance(2022, 01, 25);
        opp1.First_Hold_2__c = Date.newInstance(2022, 01, 27);
        insert opp1;
        
        Test.startTest();
        
        opp1.Lead_Type__c = 'Palermo - Digital/UX';
        update opp1;
        
      	Test.stopTest();
    }
    
    static testmethod void method3(){
		Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;
        
        Opportunity opp1 = new Opportunity();
        opp1.Name = 'TestOpp1';
        opp1.StageName = 'Qualification';
        opp1.CloseDate = system.today().addDays(10);
        opp1.AccountId = acc.Id;
        opp1.Lead_Producer__c = 'Cameron Krone';
        opp1.Lead_Producer_Email__c = 'test@produceremail.com';
        opp1.Lead_Type__c = 'Palermo - Branding';
        opp1.First_Hold_1__c = Date.newInstance(2022, 01, 25);
        opp1.First_Hold_2__c = Date.newInstance(2022, 01, 27);
        insert opp1;
        
        Test.startTest();
        
        opp1.Lead_Type__c = 'Palermo - CGI';
        update opp1;
        
      	Test.stopTest();
    }
}