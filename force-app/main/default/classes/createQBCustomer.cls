public class createQBCustomer {
    
    public static Opportunity opp;
    
    public static void createCustomer(Id oppId)
    {
        opp = [SELECT Id, AccountId, Account.Name, QB_Company__c, Primary_E_mail__c FROM Opportunity WHERE Id =: oppId];
        
        Map<String,Object> finalReq = createCustomerJson();
        
        try{
        	Map<String, Object> respMap = breadwinner_qbo.BreadwinnerQBAPI.call(finalReq);
    		System.debug('Cus Response ::: ' + respMap);
            
            CusQBResponseJsonCls res = (CusQBResponseJsonCls)JSON.deserialize(String.valueOf(respMap.get('responseJSON')), CusQBResponseJsonCls.class);
            String cusSFId = res.customers[0].SFRecordID;
            
            breadwinner_qbo__Breadwinner_Account_Connection__c cus = [SELECT Id, breadwinner_qbo__Salesforce_Account__c FROM breadwinner_qbo__Breadwinner_Account_Connection__c WHERE Id =: cusSFId];
            cus.breadwinner_qbo__Salesforce_Account__c = opp.AccountId;                        
            
            update cus;
            
            callCreateInvoice(opp.Id);
        }catch(Exception e)
        {
            System.debug(e);
            System.debug(e.getStackTraceString());
        }
    }
    
    private static Map<String, Object> createCustomerJson()
    {
        List<Object> customerList = new List<Object>();
        
        Map<String, Object> customerMap = new Map<String,Object>();
        customerMap.put('CompanyName',opp.Account.Name);
        customerMap.put('DisplayName',opp.Account.Name);
        customerMap.put('EmailAddress',opp.Primary_E_mail__c);
        customerMap.put('PrimaryEmailAddr', new Map<String,Object>{'Address' => opp.Primary_E_mail__c});
        customerMap.put('Active',true);
        
        customerList.add(customerMap);
        
        Map<String,Object> requestJSONMap = new Map<String,Object>();
        requestJSONMap.put('customers',customerList);
        
        String reqJSON = JSON.serialize(requestJSONMap);
        
        Map<String, Object> reqObj = new Map<String, Object>();
    	reqObj.put('version', '1.0');
    	reqObj.put('action', 'createCustomer');
    	reqObj.put('requestJSON', reqJSON);
    	reqObj.put('qbOrgId', getOrgRefId());
        
        System.debug('Cus Req Map: ' + reqObj);
        
        return reqObj;
    }
    
    private static string getOrgRefId()
    {
        switch on opp.QB_Company__c{
            when 'Align Retouch'{
                return System.Label.Align_Retouch_QB_Id;
            }
            when 'Palermo Studio'{
                return System.Label.Palermo_Studio_QB_Id;
            }
        }
        
        return System.Label.Slate_Studios_QB_Id;
    }
	
    
    @future(callout=true)
    private static void callCreateInvoice(Id opportunityId)
    {
        createQBInvoice.fromCreateCustomer = true;
    	createQBInvoice.createInvoice(opportunityId);
    }
}