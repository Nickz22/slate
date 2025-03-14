public class CreateUpdateQBInvoiceByUser {
    @AuraEnabled
    public static String CreateUpdateInvoice(String recordId){        
        list<breadwinner_qbo__Invoice__c> relatedInvoice = new list<breadwinner_qbo__Invoice__c>([SELECT id from breadwinner_qbo__Invoice__c where breadwinner_qbo__Opportunity__c =:recordId AND breadwinner_qbo__Status__c NOT IN('Deleted','Voided','Closed')]);
        System.debug('=====relatedInvoice===>'+relatedInvoice);
        if(relatedInvoice.size()>0){
            updateQBInvoice.updateInvoice(recordId);
        }else{
            createQBInvoice.createInvoice(recordId);
        }
        
        
        return recordId;
    }
}