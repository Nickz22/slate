@isTest
public  class cloneAccountTeamMembersHelperTest {
    
    static testmethod  void createData()
    {
        Account a = new Account();
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Retainer').getRecordTypeId();
        a.Name = 'Source Acc';
        insert a;
        
        Account a1 = new Account();
        a1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Retainer').getRecordTypeId();
        a1.Name = 'Target Acc';
        insert a1;
        
        Contact c = new Contact();
        c.FirstName = 'Test';
        c.LastName = '1';
        c.AccountId = a.Id;
        c.Email = 'test1@test.com';
        
        Contact c2 = new Contact();
        c2.FirstName = 'Test';
        c2.LastName = '2';
        c2.Email = 'test2@test.com';
        c2.AccountId = a.Id;
        
        Contact c3 = new Contact();
        c3.FirstName = 'Not';
        c3.LastName = 'Active';
        c3.AccountId = a.Id;
        c3.Email = 'test3@test.com';
        
        insert new List<Contact>{c,c2,c3};
            
        Account_Team__c at1 = new Account_Team__c();
        at1.Name = '1';
        at1.Team_Member__c = c.Id;
        at1.Active__c = true;
        at1.Account__c = a.Id;
        at1.Service_Type__c = 'Photographer';
        
        Account_Team__c at2 = new Account_Team__c();
        at2.Name = '2';
        at2.Team_Member__c = c2.Id;
        at2.Active__c = true;
        at2.Account__c = a.Id;
        at2.Service_Type__c = 'Stylist';
        
        Account_Team__c at3 = new Account_Team__c();
        at3.Name = '3';
        at3.Team_Member__c = c3.Id;
        at3.Active__c = false;
        at3.Account__c = a.Id;
        at3.Service_Type__c = 'Makeup Artist';
        
        insert new List<Account_Team__c>{at1,at2,at3};
        List<Id> ids = new List<Id>{at1.Id,at2.Id,at3.Id};
        test.startTest();
        cloneAccountTeamMembersHelper.getTeamMembers(a.Id);
        cloneAccountTeamMembersHelper.getTeamMembersName(ids);
        cloneAccountTeamMembersHelper.cloneRecords(a1.Id,ids);
        cloneAccountTeamMembersHelper.getAccountName(a.Id);
        test.stopTest();
    }

    public cloneAccountTeamMembersHelperTest() {

    }
}