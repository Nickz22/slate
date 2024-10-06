public class updateInvoiceflow {
    @InvocableMethod(label='Create/UpdateInvoice'description='Return created/updated Invoice')
    public static void CreateUpdateInvoice(List<ID> Ids){
        System.debug('=====oppid===>'+Ids);
        list<breadwinner_qbo__Invoice__c> relatedInvoice = new list<breadwinner_qbo__Invoice__c>([
                                                                                    SELECT id 
                                                                                    FROM breadwinner_qbo__Invoice__c 
                                                                                    WHERE breadwinner_qbo__Opportunity__c in :Ids AND breadwinner_qbo__Status__c NOT IN('Deleted','Voided','Closed')]);
        if(relatedInvoice.size()>0){
            updateQBInvoice.updateInvoice(Ids[0]);
        }else{
            createQBInvoice.createInvoice(Ids[0]);
        }        
    }

   
}