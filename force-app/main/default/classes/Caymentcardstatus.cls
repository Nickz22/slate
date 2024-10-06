public class Caymentcardstatus {
    @AuraEnabled(cacheable=true)
    public static Boolean getPaymentCard(String recordId) {
        Boolean returnval=false;
        opportunity opprec = [SELECT Id,AccountId from opportunity where id=:recordId];
        for(bw_payments__BWP_Payment_Method__c pmtmethod: [SELECT Id, bw_payments__Salesforce_Account__c,bw_payments__Type__c from bw_payments__BWP_Payment_Method__c where bw_payments__Salesforce_Account__c=:opprec.AccountId and bw_payments__Type__c='Card']){            
                returnval =true;
                break;             
        } 
        return returnval;
    }
}