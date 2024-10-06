global class PandaDocQuoteController {
  private static final String PRICING_TABLE_NAME = 'Pricing Table - Cam Design - 11.04.20';
  private Id opportunityId;
  private Opportunity opp;
  private Boolean isCCPayment;
  private Pandadoc_Quote_Template_Mapping__mdt quoteTemplateMapping;

  global PandaDocQuoteController(Id oppId) {
    this.opportunityId = oppId;
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

  private String getDocumentName() {
    return this.opp.Name;
  }

  private List<PandaDocQuoteToken> getTokens() {
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
        Date.today()
          .addDays(
            Integer.valueOf(
              this.opp.Payment__c.split(' ')[
                this.opp.Payment__c.split(' ').size() - 1
              ]
            )
          )
      ),
      new PandaDocQuoteToken('INVOICE_NUMBER', this.opp.InvoiceNumber__c),
      new PandaDocQuoteToken('SALES_TAX', this.opp.Tax_to_collect__c),
      new PandaDocQuoteToken('QUOTE_TOTAL', this.opp.Invoice_Amount__c),
      new PandaDocQuoteToken('CC_FEE', this.opp.CC_Fee_invoice__c)
    };
  }

  private List<PandadocQuoteRecipient> getRecipients() {
    List<PandadocQuoteRecipient> recipients = new List<PandadocQuoteRecipient>();
    recipients.add(
      new PandadocQuoteRecipient(
        this.opp.PrimaryContact__r.Email,
        this.opp.PrimaryContact__r.FirstName,
        this.opp.PrimaryContact__r.LastName,
        'payer'
      )
    );
    return recipients;
  }

  private List<Map<String, Object>> getPricingItems() {
    Map<String, Object> table = new Map<String, Object>{
      'name' => PRICING_TABLE_NAME,
      'data_merge' => true,
      'sections' => new List<Map<String, Object>>{
        new Map<String, Object>{
          'title' => 'Products and Services',
          'default' => true,
          'rows' => getOpportunityLineItemRows()
        }
      }
    };

    return new List<Map<String, Object>>{ table };
  }

  private List<Map<String, Object>> getOpportunityLineItemRows() {
    List<Map<String, Object>> rows = new List<Map<String, Object>>();

    for (OpportunityLineItem oli : [
      SELECT
        Product2.Name,
        Text_Unit_Cost__c,
        Text_Customer_Price__c,
        Quantity,
        TotalPrice,
        Days_Required__c
      FROM OpportunityLineItem
      WHERE OpportunityId = :this.opportunityId
    ]) {
      Map<String, Object> row = new Map<String, Object>{
        'options' => new Map<String, Object>{
          'optional' => false,
          'optional_selected' => true,
          'qty_editable' => false
        },
        'data' => new Map<String, Object>{
          'Name' => oli.Product2.Name,
          'Text_Unit_Cost__c' => oli.Text_Unit_Cost__c,
          'Text_Customer_Price__c' => oli.Text_Customer_Price__c,
          'Quantity' => oli.Quantity,
          'QTY' => oli.Quantity,
          'Price' => oli.TotalPrice,
          'Days_Required__c' => oli.Days_Required__c
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

  @AuraEnabled(cacheable=true)
  public static Map<String, String> createPandaDocQuote(Id opportunityId) {
    PandaDocQuoteController controller = new PandaDocQuoteController(
      opportunityId
    );

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
      Map<String, String> response = PandadocApi.createDocument(requestBody);

      return response;
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

  public class PandaDocQuoteException extends Exception {
  }
}
