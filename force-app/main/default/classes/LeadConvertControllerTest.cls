@isTest
public class LeadConvertControllerTest 
{
	static testMethod void testPalermo()
    {
        Lead newLead = new Lead();
        newLead.Company = 'Test Company';
        newLead.FirstName = 'Test';
        newLead.LastName = 'Person';
        newLead.Email = 'what@whatever.com';
        newLead.Services_of_Interest__c = 'Graphic Design;Print Design;Typography';
        newLead.Service_of_Interest__c = 'Branding & Identity';
        newLead.Project_Brief__c = 'This is a project brief.';
        newLead.Project_Start_Date__c = system.today().addDays(2);
        newLead.Project_Deadline__c = system.today().addDays(5);
        newLead.Project_Budget__c = '$20,000 - $25,000';
        newLead.LeadSource = 'Mailing List';
        newLead.isTypeForm__c = true;
        newLead.Inquiry_For__c = 'Palermo';
        insert newLead;
        
        Test.startTest();
        
        Database.executeBatch(new TypeformLeadConvert_Batch(), 1);
        
        Test.stopTest();
        
        Opportunity opp = [SELECT Id, Name, Lead_Type__c, Opportunity_Descriptor__c FROM Opportunity LIMIT 1];
    }
}