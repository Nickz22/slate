public class createQBPayments {
    private static Map<String, bw_payments__BWP_Transaction__c> oppPmt;
    private static Map<String, breadwinner_qbo__Invoice__c> qbInvoices;
    private static Map<String,Map<String,Object>> reqObjs;
    
    public static Boolean createPayments(Set<Id> paymentIds)
    {
    	Boolean isSuccess = false;
        
        List<bw_payments__BWP_Transaction__c> pymts = [SELECT Id, bw_payments__Amount__c, bw_payments__Receipt_URL__c, bw_payments__Status__c,Synced_to_QB__c,
                 Batch_Process_Status__c, bw_payments__Description__c,bw_payments__Created_Date_in_Processor__c FROM bw_payments__BWP_Transaction__c WHERE Id IN: paymentIds];
        
        oppPmt = new Map<String,bw_payments__BWP_Transaction__c>();
        for(bw_payments__BWP_Transaction__c bwpmt:pymts)
        {
            String oppName;
            String des = bwpmt.bw_payments__Description__c;
            
            if(des.contains('-'))
            	oppName = des.substring(0, des.indexOf('-')).trim();
            else
                oppName = des.trim();
            
            oppPmt.put(oppName, bwpmt);
        }
        
        List<breadwinner_qbo__Invoice__c> bwInvoices = [SELECT Id, breadwinner_qbo__Invoice_Id__c, breadwinner_qbo__Custom_Field_1_Value__c, breadwinner_qbo__QBO_Org_Name__c,
                                                       breadwinner_qbo__QBO_Org_Id__c,breadwinner_qbo__Status__c, breadwinner_qbo__Amount_Due__c,breadwinner_qbo__Customer_Reference__c
                                                       FROM breadwinner_qbo__Invoice__c WHERE breadwinner_qbo__Status__c IN ('Open','Partial') AND breadwinner_qbo__Custom_Field_1_Value__c IN: oppPmt.keySet()];
        
        qbInvoices = new Map<String, breadwinner_qbo__Invoice__c>();
        
        for(breadwinner_qbo__Invoice__c qbIn:bwInvoices)
        {
            if(!String.isEmpty(qbIn.breadwinner_qbo__Custom_Field_1_Value__c))
            {
                qbInvoices.put(qbIn.breadwinner_qbo__Custom_Field_1_Value__c.trim(), qbIn);
            }
        }
        
        if(!oppPmt.isEmpty() && !qbInvoices.isEmpty())
        {
            generateQBPayments();
        }
        
        return isSuccess;
    }
    
    private static boolean generateQBPayments()
    {
        Boolean isSuccess = false;
        reqObjs = new Map<String,Map<String,Object>>();
        
        for(String oppName:oppPmt.keySet())
        {
            bw_payments__BWP_Transaction__c bwPmt = oppPmt.get(oppName);
            
            if(qbInvoices.containsKey(oppName))
            {
            	breadwinner_qbo__Invoice__c inv = qbInvoices.get(oppName);
                
                reqObjs.put(oppName,createJSON(bwPmt,inv));
            }
        }
        
        if(!reqObjs.isEmpty())
            callBreadwinnerAPI();
        
        return isSuccess;
    }
    
    private static Map<String, Object> createJSON(bw_payments__BWP_Transaction__c bwPmt, breadwinner_qbo__Invoice__c inv)
    {
        Map<String,Object> linkedTrxn = new Map<String,Object>();
        String invId = inv.breadwinner_qbo__Invoice_Id__c;
        String qbInvId = invId.substring(invId.lastIndexOf('-')+1,invId.length());
        linkedTrxn.put('TxnId',qbInvId);
        linkedTrxn.put('TxnType','Invoice');
        List<Map<String,Object>> linkedTrxns = new List<Map<String,Object>>{linkedTrxn};
        
        List<Map<String,Object>> line = new List<Map<String,Object>>();
        Map<String,Object> lines = new Map<String,Object>();
        lines.put('Amount', bwPmt.bw_payments__Amount__c);
        lines.put('LinkedTxn',linkedTrxns);
        line.add(lines);
        
        Map<String,Object> paymentMap = new Map<String, Object>();
        paymentMap.put('TotalAmt',bwPmt.bw_payments__Amount__c);
        String ref = inv.breadwinner_qbo__Customer_Reference__c;
        String cRef = ref.substring(ref.IndexOf('-')+1,ref.length());
        String orgRef = ref.substring(0,ref.IndexOf('-'));
        paymentMap.put('CustomerRef',new Map<String,Object>{'value' => cRef});
        paymentMap.put('Line',line);
        paymentMap.put('TxnDate',bwPmt.bw_payments__Created_Date_in_Processor__c.format('YYYY-MM-dd'));
        
        Map<String,Object> requestJSONMap = new Map<String, Object>();
        requestJSONMap.put('payments', new List<Object>{paymentMap});
        String reqJSON = JSON.serialize(requestJSONMap);
        System.debug(reqJSON);
        Map<String, Object> reqObj = new Map<String, Object>();
        reqObj.put('version','1.0');
        reqObj.put('action','createPayment');
        reqObj.put('requestJSON',reqJSON);
        reqObj.put('qbOrgId',orgRef);
        
        return reqObj;
    }
    
    private static void callBreadwinnerAPI()
    {
        List<bw_payments__BWP_Transaction__c> toUpdate = new List<bw_payments__BWP_Transaction__c>();
        
        for(String oppName:reqObjs.keySet())
        {
            bw_payments__BWP_Transaction__c pmt = oppPmt.get(oppName);
            
            try{
                
                Map<String,Object> respMap = breadwinner_qbo.BreadwinnerQBAPI.call(reqObjs.get(oppName));
                pmt.Synced_to_QB__c = true;
                system.debug('respMap' + respMap);
                toUpdate.add(pmt);
                if(respMap.containsKey('apiErrors'))
                {
                    throw new CreateQBPaymentException(String.valueOf(respMap.get('apiErrors')));
                }
                
                
            }catch(Exception e){
                System.debug(e);
                System.debug(e.getStackTraceString());
                Error_Log__c log = new Error_Log__c();
                log.Component_Name__c = 'createQBPayments';
                log.Component_Type__c = 'Apex Class';
                log.Error_Message__c = e.getMessage();
                log.Error_Type__c = e.getTypeName();
                log.Record_Reference__c = pmt.Id;
            }
        }
        if(!toUpdate.isEmpty()){
            update toUpdate;
        }
    }
    
    public class CreateQBPaymentException extends Exception{}
}