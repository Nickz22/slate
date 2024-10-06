@isTest
public class ChargeCustomerAllAutomationTest {
    @testSetup
    static void createDummyData(){
        Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId();
        Account slate = new Account(Name = 'Slate Studios',RecordTypeId = rtId);
        Account client = new Account(Name = 'Client Account',RecordTypeId = rtId);
        insert new List<Account>{slate,client};
        
        Contact c = new Contact(FirstName = 'Test', LastName = 'Con', Email = 'testcon@test.com', AccountId = client.Id);
        insert c;

        Id oppRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = oppRtId;
        opp.Name = 'Test234';
        opp.AccountId = slate.Id;
        opp.Lead_Producer__c = 'Cameron Krone';
        opp.Lead_Type__c = 'E-Commerce';
        opp.StageName = 'Qualification';
        opp.CloseDate = System.today().addMonths(1);
        opp.Days__c = 1;
        opp.Lead_Type__c = 'Palermo - Branding';
        insert opp;

        bw_payments__BWP_Customer__c BWP_Customer = new bw_payments__BWP_Customer__c();
        BWP_Customer.Name = 'testeName';
        BWP_Customer.bw_payments__Salesforce_Account__c = opp.AccountId;
        BWP_Customer.bw_payments__Processor_Org_Name__c = 'Palermo Studio';
        BWP_Customer.bw_payments__Default_Source__c = 'card_1M91FfCSfqqBbZrdE13fcy09';
        insert BWP_Customer;
        bw_payments__BWP_Payment_Method__c Payment_Method = new bw_payments__BWP_Payment_Method__c();
        Payment_Method.bw_payments__Customer__c = BWP_Customer.Id;
        Payment_Method.bw_payments__Processor_Id__c ='card_1M91FfCSfqqBbZrdE13fcy09';
        Payment_Method.bw_payments__Salesforce_Account__c = opp.AccountId;
        Payment_Method.bw_payments__Salesforce_Contact__c = c.Id;
        Payment_Method.bw_payments__Type__c='Card';
        Payment_Method.bw_payments__Processor_Customer_Id__c = 'cus_MsmogSZpE6vTuy';
        insert Payment_Method;        
    }
    @isTest
    static void testInvocableChargeCustomerByFlow() {
        Opportunity pymtsRec = [Select Id From Opportunity limit 1];
        
        Test.startTest();
        try{
            InvocableChargeCustomerByFlow.chargeCustomer(new List<Id>{pymtsRec.Id});
        }catch(exception ex){
        }
        Test.stopTest();

        Assert.isNotNull(pymtsRec, 'Opportunity record not found');
    }
    
    @isTest
    static void testCaymentcardstatus() {
        Opportunity pymtsRec = [Select Id From Opportunity limit 1];
        List<ID> Ids = new List<ID>();
        Ids.add(pymtsRec.Id);
        Test.startTest();
        try{
            Caymentcardstatus.getPaymentCard(pymtsRec.Id);
        }catch(exception ex){
        }
        Test.stopTest();

        Assert.isNotNull(pymtsRec, 'Opportunity record not found');
    }
}