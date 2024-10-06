@isTest
public class createQBPaymentsByUserTest {

    @testSetup
    static void createDummyData(){
        
	    bw_payments__BWP_Transaction__c pymtsRec = new bw_payments__BWP_Transaction__c();
        pymtsRec.bw_payments__Amount__c = 2002;
        pymtsRec.bw_payments__Receipt_URL__c = 'test@gmail.com';
        pymtsRec.bw_payments__Status__c = 'Open';
        pymtsRec.Synced_to_QB__c = true;
        pymtsRec.Batch_Process_Status__c = 'Processed';
        pymtsRec.bw_payments__Description__c = 'test - opp';
        pymtsRec.bw_payments__Created_Date_in_Processor__c = System.now();
        insert pymtsRec;
        
        breadwinner_qbo__Invoice__c invRec = new breadwinner_qbo__Invoice__c();
        invRec.breadwinner_qbo__Invoice_Id__c = 'A12234';
        invRec.breadwinner_qbo__QBO_Org_Name__c = 'Test';
        invRec.breadwinner_qbo__QBO_Org_Id__c = 'A12';
        invRec.breadwinner_qbo__Due_Date__c = Date.today();
        invRec.breadwinner_qbo__Amount_Due__c = 2;
        invRec.breadwinner_qbo__Internal_Status__c = 'Open';
        invRec.breadwinner_qbo__Customer_Reference__c = 'test-test';
        invRec.breadwinner_qbo__Custom_Field_1_Value__c = 'test';
        insert invRec;
    }
    @isTest
    static void testsyncPayment() {
        bw_payments__BWP_Transaction__c pymtsRec = [Select Id From bw_payments__BWP_Transaction__c limit 1];
        Test.startTest();
        try{
            createQBPaymentsByUser.syncPayment(pymtsRec.Id);
        }catch(exception ex){
        }
        Test.stopTest();
    }
    
    @isTest
    static void testpassBWPaymentsToQB() {
        bw_payments__BWP_Transaction__c pymtsRec = [Select Id From bw_payments__BWP_Transaction__c limit 1];
        Test.startTest();
        try{
            createQBPaymentsByUser.passBWPaymentsToQB(new List<Id>{pymtsRec.Id});
        }catch(exception ex){
        }
        Test.stopTest();
    }
}