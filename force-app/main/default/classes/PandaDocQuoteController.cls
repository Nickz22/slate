public class PandaDocQuoteController {
  private static final String PRICING_TABLE_NAME = 'Pricing Table - Cam Design - 11.04.20';
  private Id opportunityId;
  private Opportunity opp;
  private Boolean isCCPayment;
  private Pandadoc_Quote_Template_Mapping__mdt quoteTemplateMapping;
  private String quoteType;
  private static final String QUOTE_TYPE_ESTIMATE = 'Estimate';
  private static final String QUOTE_TYPE_INVOICE = 'Invoice';
  private Map<String, Decimal> percentToPayByQuoteType = new Map<String, Decimal>{
    QUOTE_TYPE_ESTIMATE.toLowerCase() => 0.7,
    QUOTE_TYPE_INVOICE.toLowerCase() => 0.3
  };

  public PandaDocQuoteController(Id oppId, String quoteType) {
    this.opportunityId = oppId;
    this.quoteType = quoteType;
    this.opp = new OpportunitySelector()
      .selectOpportunitiesByIds(new Set<Id>{ oppId })
      .get(0);
    this.isCCPayment = this.opp.CC_Payment__c;
    try {
      this.quoteTemplateMapping = new PandadocQuoteMappingSelector()
        .selectPandadocQuoteTemplateMappingByDivisionName(
          this.opp.Division__r.Name
        );
    } catch (Exception e) {
      throw new PandaDocQuoteException(
        'Error getting quote template mapping. Does a Quote Template mapping exist for this division? ' +
        e.getMessage()
      );
    }
  }

  @AuraEnabled(cacheable=true)
  public static Map<String, String> createPandaDocQuote(Id opportunityId, String quoteType) {
    PandaDocQuoteController controller = new PandaDocQuoteController(
      opportunityId, quoteType.toLowerCase()
    );

    // Fetch a fresh Opportunity every time
    Opportunity freshOpp = [
      SELECT
        Id,
        Name,
        CC_Payment__c,
        Division__r.Name,
        Account.Name,
        Upper_Descriptor__c,
        InvoiceNumber__c,
        Payment__c,
        Tax_to_collect__c,
        Shoot_Date__c,
        CC_Fee_invoice__c,
        PrimaryContact__r.Email,
        PrimaryContact__r.FirstName,
        PrimaryContact__r.LastName,
        Invoice_Amount__c
      FROM Opportunity
      WHERE Id = :opportunityId
      LIMIT 1
    ];

    controller.opp = freshOpp;
    controller.isCCPayment = freshOpp.CC_Payment__c;

    Map<String, Object> requestBody = new Map<String, Object>{
      'name' => controller.getDocumentName(),
      'template_uuid' => controller.isCCPayment
        ? controller.quoteTemplateMapping.Pandadoc_CC_Fee_Estimate_Template_Id__c
        : controller.quoteTemplateMapping.Pandadoc_Estimate_Template_Id__c,
      'recipients' => controller.getRecipients(),
      'owner' => new Map<String, String>{ 'email' => 'nickzsb.nz@gmail.com' },
      'tokens' => controller.getTokens(),
      'metadata' => controller.getMetadata(),
      'pricing_tables' => controller.getPricingItems()
    };

    System.debug(
      'Pandadoc Request Body \n\n' + JSON.serializePretty(requestBody)
    );

    try {
      return PandadocApi.createDocument(requestBody);
    } catch (PandadocApi.PandaDocException e) {
      // Log the error
      System.debug(e.getMessage());
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static Map<String, String> checkDocumentStatus(String statusUrl) {
    try {
      return PandadocApi.checkDocumentStatus(statusUrl);
    } catch (PandadocApi.PandaDocException e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static void attachDocumentToOpportunity(
    Id opportunityId,
    String documentId,
    String documentName
  ) {
    try {
      // Fetch the document content from PandaDoc API
      Blob documentContent = PandadocApi.getDocumentContent(documentId);

      ContentVersion cv = new ContentVersion();
      cv.Title = documentName;
      cv.PathOnClient = documentName + '.pdf';
      cv.VersionData = documentContent;
      cv.IsMajorVersion = true;
      insert cv;

      ContentDocumentLink cdl = new ContentDocumentLink();
      cdl.ContentDocumentId = [
        SELECT ContentDocumentId
        FROM ContentVersion
        WHERE Id = :cv.Id
      ]
      .ContentDocumentId;
      cdl.LinkedEntityId = opportunityId;
      cdl.ShareType = 'V';
      insert cdl;
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error attaching document: ' + e.getMessage()
      );
    }
  }

  // helpers
  private String getDocumentName() {
    return this.opp.Name;
  }

  private List<PandaDocQuoteToken> getTokens() {
    System.debug(JSON.serializePretty(this.opp));
    Decimal taxToCollect = this.opp.Tax_to_collect__c * this.percentToPayByQuoteType.get(this.quoteType);
    Decimal amount = this.opp.Invoice_Amount__c * this.percentToPayByQuoteType.get(this.quoteType);
    Decimal ccfee = this.opp.CC_Fee_invoice__c * this.percentToPayByQuoteType.get(this.quoteType);
    return new List<PandaDocQuoteToken>{
      new PandaDocQuoteToken('ACCOUNT_NAME', this.opp.Account.Name),
      new PandaDocQuoteToken('OPPORTUNITY_NAME', this.opp.Name),
      new PandaDocQuoteToken(
        'OPPORTUNITY_DESCRIPTION',
        this.opp.Upper_Descriptor__c
      ),
      new PandaDocQuoteToken('ESTIMATE', this.opp.InvoiceNumber__c),
      new PandaDocQuoteToken(
        'DUE_DATE',
        DateTime.newInstance(
            Date.today()
              .addDays(
                Integer.valueOf(
                  this.opp.Payment__c.split(' ')[
                    this.opp.Payment__c.split(' ').size() - 1
                  ]
                )
              ),
            Time.newInstance(0, 0, 0, 0)
          )
          .format('MM / dd / yyyy')
      ),
      new PandaDocQuoteToken('INVOICE_NUMBER', this.opp.InvoiceNumber__c),
      new PandaDocQuoteToken(
        'SALES_TAX',
        formatCurrency(taxToCollect)
      ),
      new PandaDocQuoteToken(
        'QUOTE_TOTAL',
        formatCurrency(amount)
      ),
      new PandaDocQuoteToken(
        'CC_FEE',
        formatCurrency(ccfee)
      ),
      new PandaDocQuoteToken(
        'SHOOT_DATE',
        this.opp.Shoot_Date__c != null
          ? DateTime.newInstance(
                this.opp.Shoot_Date__c,
                Time.newInstance(0, 0, 0, 0)
              )
              .format('MM / dd / yyyy')
          : 'N/A'
      )
    };
  }

  private String formatCurrency(Decimal value) {
    if (value == null) {
      return '$0.00';
    }
    // Format the value with exactly two decimal places
    String formattedValue = value.setScale(2).format();

    // Ensure there are always two decimal places
    if (!formattedValue.contains('.')) {
      formattedValue += '.00';
    } else if (formattedValue.endsWith('.')) {
      formattedValue += '00';
    } else if (formattedValue.split('\\.')[1].length() == 1) {
      formattedValue += '0';
    }

    return '$' + formattedValue;
  }

  private List<PandadocQuoteRecipient> getRecipients() {
    return new List<PandadocQuoteRecipient>{
      new PandadocQuoteRecipient(
        this.opp.PrimaryContact__r.Email,
        this.opp.PrimaryContact__r.FirstName,
        this.opp.PrimaryContact__r.LastName,
        'payer'
      ),
      new PandadocQuoteRecipient(
        UserInfo.getUserEmail(),
        UserInfo.getFirstName(),
        UserInfo.getLastName(),
        'sender'
      )
    };
  }

  private List<Map<String, Object>> getPricingItems() {
    Map<String, Object> table = new Map<String, Object>{
      'name' => PRICING_TABLE_NAME,
      'data_merge' => true,
      'sections' => new List<Map<String, Object>>{
        new Map<String, Object>{
          'title' => 'Products and Services',
          'default' => true,
          'rows' => getQuoteLineItemRows()
        }
      }
    };

    return new List<Map<String, Object>>{ table };
  }

  private List<Map<String, Object>> getQuoteLineItemRows() {
    List<Map<String, Object>> rows = new List<Map<String, Object>>();

    for (SBQQ__QuoteLine__c qli : [
      SELECT
        SBQQ__Product__r.Name,
        SBQQ__ListPrice__c,
        SBQQ__CustomerPrice__c,
        SBQQ__Quantity__c,
        SBQQ__CustomerTotal__c,
        SBQQ__SubscriptionTerm__c
      FROM SBQQ__QuoteLine__c
      WHERE
        SBQQ__Quote__r.SBQQ__Opportunity2__c = :this.opportunityId
        AND SBQQ__Quote__r.SBQQ__Primary__c = TRUE
    ]) {
      Map<String, Object> row = new Map<String, Object>{
        'options' => new Map<String, Object>{
          'optional' => false,
          'optional_selected' => true,
          'qty_editable' => false
        },
        'data' => new Map<String, Object>{
          'Name' => qli.SBQQ__Product__r.Name,
          'Text_Unit_Cost__c' => qli.SBQQ__ListPrice__c,
          'Quantity' => qli.SBQQ__Quantity__c,
          'QTY' => qli.SBQQ__Quantity__c,
          'Price' => qli.SBQQ__CustomerTotal__c,
          'Days_Required__c' => qli.SBQQ__SubscriptionTerm__c ?? 0
        }
      };
      rows.add(row);
    }

    return rows;
  }

  private Map<String, String> getMetadata() {
    Map<String, String> metadata = new Map<String, String>();
    metadata.put('opportunityId', opportunityId);
    return metadata;
  }

  public class PandaDocQuoteException extends Exception {
  }
}
