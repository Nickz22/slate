public class chargeCustomer {
    
    private static Opportunity opp;
    private static List<bw_payments__BWP_Customer__c> pymtCust = new List<bw_payments__BWP_Customer__c>();
    private static bw_payments__BWP_Payment_Method__c defaultMethod;
    
	public static void charge(Id oppId)
    {
        try
        {
        	opp = [SELECT Id, Name, QB_Company__c, AccountId, breadwinner_qbo__Total_Amount_Overdue__c FROM Opportunity WHERE Id =: oppId];
            
            String likeFilter = opp.QB_Company__c + '%';
            
        	pymtCust = [SELECT Id, bw_payments__Processor_Customer_Id__c, bw_payments__Processor_Org_Id__c, bw_payments__Default_Source__c,
                       (SELECT Id, bw_payments__Processor_Id__c, bw_payments__Type__c, bw_payments__Processor_Customer_Id__c,
                        bw_payments__Processor_Org_Id__c FROM bw_payments__Source__r) FROM bw_payments__BWP_Customer__c 
                        WHERE bw_payments__Salesforce_Account__c =: opp.AccountId AND bw_payments__Processor_Org_Name__c LIKE: likeFilter];
            
            if(!pymtCust.isEmpty())
            {
                for(bw_payments__BWP_Payment_Method__c mtd: pymtCust[0].bw_payments__Source__r)
                {
                    if(pymtCust[0].bw_payments__Default_Source__c == mtd.bw_payments__Processor_Id__c)
                        defaultMethod = mtd;
                }
            }
            
            if(defaultMethod != null)
                submitTransaction();
            
        }catch(Exception e)
        {
            System.debug('Charge Customer Error: ' + e.getMessage());
            System.debug('Charge Customer Stack Trace: ' + e.getStackTraceString());
        }
    }
    
    private static void submitTransaction()
    {
        System.debug('Cust Id: ' + pymtCust[0].Id);
        System.debug('Method: ' + defaultMethod.Id);
        
        Map<String, Object> chargeData = new Map<String, Object>();
        chargeData.put('processorCustomerId', defaultMethod.bw_payments__Processor_Customer_Id__c); 
        chargeData.put('paymentMethodId', defaultMethod.bw_payments__Processor_Id__c); 
       
        chargeData.put('amount', opp.breadwinner_qbo__Total_Amount_Overdue__c); 
        chargeData.put('chargeCurrency', 'USD'); 
        chargeData.put('description', opp.Name + ' - ' + 'Overdue Payment'); 
        chargeData.put('paymentMethodType', defaultMethod.bw_payments__Type__c);
        chargeData.put('source', defaultMethod.Id);
        chargeData.put('customer', pymtCust[0].Id);
                
        //  Initializing the RequestJSON Data to be passed.
        Map<String, Object> requestJSONMap = new Map<String, Object>();
        requestJSONMap.put('transactions', new List<Object>{chargeData});
        String reqJSON = JSON.serialize(requestJSONMap);
        System.debug(reqJSON);
        
        Map<String, Object> reqObj = new Map<String, Object>();
        reqObj.put('version','1.0');
        reqObj.put('action','ChargeProcessor');
        reqObj.put('processorId', defaultMethod.bw_payments__Processor_Org_Id__c);
        reqObj.put('requestJSON',reqJSON);
        
        //  Placing a request to Breadwinner Global API
        Map<String,Object> resp = bw_payments.BreadwinnerPaymentsAPI.call(reqObj);
        System.debug(resp);
    }
}