public class createQBPaymentsByUser {
    @AuraEnabled
    public static String syncPayment(String recordId){
        System.debug('=====oppid===>'+recordId);       
        Set<Id> pmtIds = new Set<Id>();
        pmtIds.add(recordId); 
        if(pmtIds.size()>0){       
            createQBPayments.createPayments(pmtIds);
        }
        
        return recordId;
    }

    @InvocableMethod(label='Stripe to QB' description='Take a list of BW Transaction Ids and passes those payments to correspoding QB Invoice.')
    public static void passBWPaymentsToQB(List<ID> Ids)
    {
        Set<Id> pmtIds = new Set<Id>();  
        pmtIds.addAll(Ids);       
        if(pmtIds.size()>0){       
            createQBPayments.createPayments(pmtIds);
        }
    }
}