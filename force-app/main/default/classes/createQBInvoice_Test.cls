@isTest
public class createQBInvoice_Test {
    
    private static Opportunity createData(String connectTo)
    {
        
        List<PricebookEntry> listofPricebookEntry =  createPricebook();
        
        Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId();
        Account slate = new Account(Name = 'Slate Studios',RecordTypeId = rtId);
        Account client = new Account(Name = 'Client Account',RecordTypeId = rtId);
        insert new List<Account>{slate,client};
        
        Contact c = new Contact(FirstName = 'Test', LastName = 'Con', Email = 'testcon@test.com', AccountId = client.Id);
        insert c;
        
        SBQQ__Quote__c qu;
        
        if(connectTo == null)
            qu = createQuote(slate.Id,null,false);
        else if(connectTo == 'Client')
            qu = createQuote(client.Id,null,true);
            
        Id oppRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
        Division__c slateDivision = new Division__c(Name = 'Slate');
        insert slateDivision;
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = oppRtId;
        opp.Name = 'Test';
        opp.AccountId = client.Id;
        opp.Division__c = slateDivision.Id;
        opp.Lead_Producer__c = 'Cameron Krone';
        opp.Lead_Type__c = 'E-Commerce';
        opp.StageName = connectTo == 'Opp' ? 'Closed - Won' : 'Qualification';
        opp.CloseDate = System.today().addMonths(1);
        opp.PrimaryContact__c = c.Id;
        opp.Days__c = 1;
        insert opp;
        
        if(connectTo == 'Opp')
        {
            qu = createQuote(client.Id, opp.Id,true);
        }
        
        return opp;
    }
    
    private static List<PricebookEntry> createPricebook()
    {
        breadwinner_qbo__BW_QB_Item__c  objitem = new breadwinner_qbo__BW_QB_Item__c ();
        objitem.Name = 'test';
        objitem.breadwinner_qbo__Reference_ID__c = 'tetsdt-123';
        insert objitem;

        Product2 p1 = new Product2(Name = 'Photographer', isActive = true, ProductCode = 'PHOTO' ,breadwinner_qbo__QB_Item__c =objitem.id );
        Product2 p2 = new Product2(Name = 'Stylist', isActive = true, ProductCode = 'Style',breadwinner_qbo__QB_Item__c =objitem.id);
        Product2 p3 = new Product2(Name = 'Studio Assistant', isActive = true, ProductCode = 'StdAsst',breadwinner_qbo__QB_Item__c =objitem.id);
        insert new List<Product2>{p1,p2,p3};
        
        Id pbId = Test.getStandardPricebookId();
            
        PricebookEntry pe1 = new PricebookEntry(Product2Id = p1.Id, Pricebook2Id = pbId, UnitPrice = 100, IsActive = true);
        PricebookEntry pe2 = new PricebookEntry(Product2Id = p2.Id, Pricebook2Id = pbId, UnitPrice = 200, IsActive = true);
        PricebookEntry pe3 = new PricebookEntry(Product2Id = p3.Id, Pricebook2Id = pbId, UnitPrice = 300, IsActive = true);
        List<PricebookEntry> listofPricebookEntry = new List<PricebookEntry>();
        listofPricebookEntry.add(pe1);
        listofPricebookEntry.add(pe2);
        listofPricebookEntry.add(pe3);
        insert listofPricebookEntry;
        return listofPricebookEntry;
    }
    
    private static SBQQ__Quote__c createQuote(Id accId, Id oppId, boolean primary)
    {  
        SBQQ__Quote__c qt = new SBQQ__Quote__c();
        qt.SBQQ__Account__c = accId;
        qt.SBQQ__Opportunity2__c = oppId != null ? oppId : null;
        qt.Lead_Type__c = 'E-Commerce';
        qt.Is_Template__c = oppId != null ? false : true;
        qt.SBQQ__PriceBook__c = Test.getStandardPricebookId();
        qt.SBQQ__Primary__c = primary;
        qt.SBQQ__SubscriptionTerm__c = 1;
        insert qt;
        
        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        for(PricebookEntry pe:[SELECT Id, Product2Id, UnitPrice FROM PricebookEntry])
        {
            SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
            ql.SBQQ__Product__c = pe.Product2Id;
            ql.SBQQ__ListPrice__c = pe.UnitPrice;
            ql.SBQQ__Quote__c = qt.Id;
            lines.add(ql);
        }
        insert lines;
            
        return qt;
    }
    @isTest
    static void testcreateInvoice() {
        Opportunity oppRec = createData('Opp'); 
        breadwinner_qbo__Breadwinner_Account_Connection__c  obj = new breadwinner_qbo__Breadwinner_Account_Connection__c();
        obj.breadwinner_qbo__Salesforce_Account__c =oppRec.AccountId;
        obj.breadwinner_qbo__QBO_Org_Name__c = 'Standard Slate';
        obj.breadwinner_qbo__Reference_Id__c = 'tetsdt-123';
        insert obj;
        Test.startTest();
        try{
            createQBInvoice.createInvoice(oppRec.Id);
        }catch(exception ex){
        }
        createQBInvoice.createInvoiceJSON();
        createQBInvoice.createLineItemList();
        String oppid = CreateUpdateQBInvoiceByUser.CreateUpdateInvoice(oppRec.Id);
        updateInvoiceflow.CreateUpdateInvoice(new List<id>{oppRec.Id});
        Test.stopTest();

        Assert.areEqual(oppRec.Id, oppid);
    }
    @isTest
    static void testupdateInvoice() {
        Opportunity oppRec = createData('Opp'); 
        breadwinner_qbo__Breadwinner_Account_Connection__c  obj = new breadwinner_qbo__Breadwinner_Account_Connection__c();
        obj.breadwinner_qbo__Salesforce_Account__c =oppRec.AccountId;
        obj.breadwinner_qbo__QBO_Org_Name__c = 'Standard Slate';
        obj.breadwinner_qbo__Reference_Id__c = 'tetsdt-123';
        insert obj;
        breadwinner_qbo__Invoice__c invobj = new breadwinner_qbo__Invoice__c();
        invobj.breadwinner_qbo__Invoice_ID__c ='hsjdhfiwe43534tref';
        invobj.breadwinner_qbo__Due_Date__c = System.today().addDays(10);
        invobj.breadwinner_qbo__Opportunity__c  =oppRec.Id;
        invobj.breadwinner_qbo__Sync_Token__c = '0';
        insert invobj;
        Test.startTest();
        try{
            updateQBInvoice.updateInvoice(oppRec.Id);
        }catch(exception ex){
        }
        updateQBInvoice.createInvoiceJSON();
        updateQBInvoice.createLineItemList();
        String oppid = CreateUpdateQBInvoiceByUser.CreateUpdateInvoice(oppRec.Id);
        updateInvoiceflow.CreateUpdateInvoice(new List<id>{oppRec.Id});
        Test.stopTest();

        Assert.areEqual(oppRec.Id, oppid);
    }
    
    @isTest
    static void testCreateCustomer()
    {
        Opportunity oppRec = createData('Opp');
        
        Test.startTest();
        try{
        createQBCustomer.createCustomer(oppRec.Id);
        }catch(Exception e)
        {}
        Test.stopTest();
    }
}