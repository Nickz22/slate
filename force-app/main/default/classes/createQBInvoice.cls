public class createQBInvoice {
  public static Opportunity opp;
  public static SBQQ__Quote__c quote;
  public static breadwinner_qbo__Breadwinner_Account_Connection__c qbCo;
  public static Map<String, Map<String, String>> customFieldMap;
  public static Boolean fromCreateCustomer = false;

  public static void createInvoice(Id opportunityId) {
    opp = [
      SELECT
        Id,
        Name,
        AccountId,
        Shoot_Date__c,
        Additional_Client_CC__c,
        CloseDate,
        Opportunity_Descriptor__c,
        Service_Type__c,
        Due_Date_Retouching_R1__c,
        Payment_terms__c,
        PO__c,
        Primary_E_mail__c,
        InvoiceNumber__c,
        StageName,
        Invoice_Due_Date_Override__c
      FROM Opportunity
      WHERE Id = :opportunityId
    ];
    quote = new SBQQ__Quote__c();
    quote = [
      SELECT
        Id,
        SBQQ__Pricebook__r.Name,
        (
          SELECT
            Id,
            SBQQ__Product__c,
            SBQQ__Product__r.breadwinner_qbo__QB_Item__c,
            SBQQ__Product__r.breadwinner_qbo__QB_Item__r.breadwinner_qbo__Reference_ID__c,
            SBQQ__ProductName__c,
            SBQQ__CustomerTotal__c,
            SBQQ__CustomerPrice__c,
            SBQQ__Quantity__c,
            SBQQ__Taxable__c,
            SBQQ__Number__c
          FROM SBQQ__LineItems__r
          ORDER BY SBQQ__Number__c ASC
        )
      FROM SBQQ__Quote__c
      WHERE SBQQ__Primary__c = TRUE AND SBQQ__Opportunity2__c = :opportunityId
      LIMIT 1
    ];
    System.debug('=====>' + quote);
    List<String> pbParts = new List<String>();
    if (Test.isRunningTest()) {
      pbParts.add('Standard');
    } else {
      pbParts = quote.SBQQ__Pricebook__r.Name.split(' ');
    }
    String co = pbParts[0];

    String criteria = co + '%';
    try {
      qbCo = [
        SELECT
          Id,
          breadwinner_qbo__Reference_Id__c,
          breadwinner_qbo__QBO_Org_Name__c
        FROM breadwinner_qbo__Breadwinner_Account_Connection__c
        WHERE
          breadwinner_qbo__Salesforce_Account__c = :opp.AccountId
          AND breadwinner_qbo__Active__c = TRUE
          AND breadwinner_qbo__QBO_Org_Name__c LIKE :criteria
        LIMIT 1
      ];
    } catch (Exception e) {
      System.debug(e.getMessage());
      System.debug(e.getStackTraceString());

      if (!fromCreateCustomer) {
        createQBCustomer.createCustomer(opp.Id);
        return;
      }
    }

    Map<String, Object> finalReqMap = createInvoiceJSON();

    try {
      Map<String, Object> respMap = breadwinner_qbo.BreadwinnerQBAPI.call(
        finalReqMap
      );
      System.debug('Response ::: ' + respMap);

      InvQBResponseJsonCls res = (InvQBResponseJsonCls) JSON.deserialize(
        String.valueOf(respMap.get('responseJSON')),
        InvQBResponseJsonCls.class
      );
      String invSFId = res.invoices[0].SFRecordID;

      breadwinner_qbo__Invoice__c inv = [
        SELECT Id, breadwinner_qbo__Opportunity__c, breadwinner_qbo__Due_Date__c
        FROM breadwinner_qbo__Invoice__c
        WHERE Id = :invSFId
      ];
      inv.breadwinner_qbo__Opportunity__c = opp.Id;

      update inv;
    } catch (Exception e) {
      System.debug(e);
      System.debug(e.getStackTraceString());
    }
  }

  public static Map<String, Object> createInvoiceJSON() {
    List<Object> invoiceList = new List<Object>();
    Map<String, Object> invoiceMap = new Map<String, Object>();
    Datetime txnDate = opp.CloseDate;
    invoiceMap.put('TxnDate', txnDate.format('YYYY-MM-dd'));
    invoiceMap.put('DueDate', dueDate());
    invoiceMap.put(
      'DocNumber',
      getInvoicePrefix() + '-' + String.valueOf(opp.InvoiceNumber__c)
    );
    invoiceMap.put('ExchangeRate', 1.0);
    invoiceMap.put('AllowOnlineCreditCardPayment', false);
    invoiceMap.put('AllowOnlineACHPayment', true);
    invoiceMap.put(
      'CustomerMemo',
      new Map<String, Object>{
        'value' => String.valueOf(
          opp.Name + '\n' + opp.Opportunity_Descriptor__c
        )
      }
    );
    invoiceMap.put('PrivateNote', opp.Name);

    String custRef = qbCo.breadwinner_qbo__Reference_Id__c;
    String custRefId = custRef.substring(
      custRef.indexOf('-') + 1,
      custRef.length()
    );
    invoiceMap.put(
      'CustomerRef',
      new Map<String, Object>{ 'value' => custRefId }
    );

    invoiceMap.put(
      'BillEmail',
      new Map<String, Object>{ 'Address' => opp.Primary_E_mail__c }
    );
    invoiceMap.put('SalesTermRef', new Map<String, Object>{ 'value' => '3' });
    invoiceMap.put(
      'BillEmailCc',
      new Map<String, Object>{ 'Address' => opp.Additional_Client_CC__c }
    );
    invoiceMap.put('CurrencyRec', new Map<String, Object>{ 'value' => 'USD' });
    invoiceMap.put('ApplyTaxAfterDiscount', true);

    List<Object> customFieldList = new List<Object>();
    if (qbCo.breadwinner_qbo__QBO_Org_Name__c.containsIgnoreCase('Slate')) {
      Map<String, Object> customField1Map = new Map<String, Object>();
      customField1Map.put('DefinitionId', '1');
      customField1Map.put('Type', 'StringType');
      customField1Map.put('StringValue', opp.Name);
      customFieldList.add(customField1Map);

      Map<String, Object> customField2Map = new Map<String, Object>();
      customField2Map.put('DefinitionId', '2');
      customField2Map.put('Type', 'StringType');
      customField2Map.put('StringValue', string.valueOf(opp.Shoot_Date__c));
      customFieldList.add(customField2Map);
    } else if (
      qbCo.breadwinner_qbo__QBO_Org_Name__c.containsIgnoreCase('Palermo')
    ) {
      Map<String, Object> customField1Map = new Map<String, Object>();
      customField1Map.put('DefinitionId', '1');
      customField1Map.put('Type', 'StringType');
      customField1Map.put('StringValue', opp.Name);
      customFieldList.add(customField1Map);
    } else if (
      qbCo.breadwinner_qbo__QBO_Org_Name__c.containsIgnoreCase('Align')
    ) {
      Map<String, Object> customField1Map = new Map<String, Object>();
      customField1Map.put('DefinitionId', '7');
      customField1Map.put('Type', 'StringType');
      customField1Map.put('StringValue', opp.Name);
      customFieldList.add(customField1Map);

      Map<String, Object> customField2Map = new Map<String, Object>();
      customField2Map.put('DefinitionId', '5');
      customField2Map.put('Type', 'StringType');
      customField2Map.put('StringValue', opp.PO__c);
      customFieldList.add(customField1Map);
    }
    invoiceMap.put('CustomField', customFieldList);

    invoiceMap.put('Line', createLineItemList());

    if (qbCo.breadwinner_qbo__QBO_Org_Name__c.contains('Slate')) {
      Map<String, Object> txnTaxDetail = new Map<String, Object>();
      txnTaxDetail.put(
        'TxnTaxCodeRef',
        new Map<String, Object>{ 'value' => '5', 'name' => 'NY Sales Tax' }
      );
      invoiceMap.put('TxnTaxDetail', txnTaxDetail);
    }

    invoiceList.add(invoiceMap);

    Map<String, Object> reqJSONMap = new Map<String, Object>();
    reqJSONMap.put('invoices', invoiceList);
    String reqJSON = JSON.serialize(reqJSONMap);
    System.debug('Invoice JSON: ' + reqJSON);

    Map<String, Object> finalReqMap = new Map<String, Object>();
    Map<String, Object> reqOptions = new Map<String, Object>();
    finalReqMap.put('options', reqOptions);
    finalReqMap.put('version', '1.0');
    finalReqMap.put('action', 'createinvoice');
    finalReqMap.put('RequestJSON', reqJSON);
    finalReqMap.put('skipDML', false);

    String orgId = qbCo.breadwinner_qbo__Reference_Id__c;
    orgId = orgId.substring(0, orgId.indexOf('-'));
    finalReqMap.put('qbOrgId', orgId);

    System.debug('Request ::: ' + finalReqMap);

    return finalReqMap;
  }

  public static List<Object> createLineItemList() {
    List<Object> lineItemList = new List<Object>();

    Integer linenum = 1;

    for (SBQQ__QuoteLine__c ql : quote.SBQQ__LineItems__r) {
      if (ql.SBQQ__Quantity__c > 0) {
        Map<String, Object> lineItemMap = new Map<String, Object>();
        lineItemMap.put('LineNum', linenum);
        lineItemMap.put('Amount', ql.SBQQ__CustomerTotal__c);
        lineItemMap.put('Description', ql.SBQQ__ProductName__c);
        lineItemMap.put('DetailType', 'SalesItemLineDetail');

        Map<String, Object> salesLineItemDetailMap = new Map<String, Object>();
        String itemCode = ql.SBQQ__Product__r.breadwinner_qbo__QB_Item__r.breadwinner_qbo__Reference_ID__c;
        String itemRef = itemCode.subString(
          itemCode.indexOf('-') + 1,
          itemCode.length()
        );
        salesLineItemDetailMap.put(
          'ItemRef',
          new Map<String, Object>{ 'value' => itemRef }
        );
        salesLineItemDetailMap.put('UnitPrice', ql.SBQQ__CustomerPrice__c);
        salesLineItemDetailMap.put('Qty', ql.SBQQ__Quantity__c);

        if (ql.SBQQ__Taxable__c)
          salesLineItemDetailMap.put(
            'TaxCodeRef',
            new Map<String, Object>{ 'value' => 'TAX' }
          );
        else
          salesLineItemDetailMap.put(
            'TaxCodeRef',
            new Map<String, Object>{ 'value' => 'NON' }
          );

        lineItemMap.put('SalesItemLineDetail', salesLineItemDetailMap);
        lineItemList.add(lineItemMap);

        linenum++;
      }
    }

    return lineItemList;
  }

  private static string dueDate() {
    Datetime dueDate;

    if (opp.Invoice_Due_Date_Override__c != null) {
      dueDate = opp.Invoice_Due_Date_Override__c;
    } else {
      if (
        opp.StageName.equalsIgnoreCase('Won - Production Complete') ||
        opp.StageName.equalsIgnoreCase('Closed Won')
      )
        dueDate = system.today();
      else
        dueDate = opp.CloseDate;

      switch on opp.Payment_terms__c {
        when 'Net 15' {
          dueDate = dueDate.addDays(15);
        }
        when 'Net 30' {
          dueDate = dueDate.addDays(30);
        }
        when 'Net 60' {
          dueDate = dueDate.addDays(60);
        }
      }
    }

    return dueDate.format('YYYY-MM-dd');
  }

  private static string getInvoicePrefix() {
    if (qbCo.breadwinner_qbo__QBO_Org_Name__c.containsIgnoreCase('Align'))
      return 'AL';
    else if (
      qbCo.breadwinner_qbo__QBO_Org_Name__c.containsIgnoreCase('Palermo')
    )
      return 'PL';
    else
      return 'SL';
  }
}
