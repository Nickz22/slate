public class PandaDocQuoteController {
  // all pandadoc pricing tables have to be named Pricing_Table
  private static final String PRICING_TABLE_NAME = 'Pricing_Table';
  private Id opportunityId;
  private Opportunity opp;
  private Boolean isCCPayment;
  private Pandadoc_Quote_Template_Mapping__mdt quoteTemplateMapping;
  private PandaDocQuoteType quoteType;
  enum PandaDocQuoteType {
    ESTIMATE,
    PROPOSAL,
    INVOICE
  }

  private static Map<String, String> companyEmailByUserEmailPhrase = new Map<String, String>{
    'align' => 'info@align-ny.com',
    'slate' => 'info@slate-nyc.com',
    'palermo' => 'info@palermo-studio.com'
  };

  private Map<PandaDocQuoteType, Decimal> percentToPayByQuoteType = new Map<PandaDocQuoteType, Decimal>();

  public PandaDocQuoteController(Id oppId, String quoteType) {
    this.opportunityId = oppId;
    this.quoteType = PandaDocQuoteType.valueOf(quoteType.toUpperCase());
    this.opp = new OpportunitySelector()
      .selectOpportunitiesByIds(new Set<Id>{ oppId })
      .get(0);

    if (this.opp.Required_Deposit__c == null) {
      throw new PandaDocQuoteException('Required deposit cannot be null.');
    }
    this.percentToPayByQuoteType.put(
      PandaDocQuoteType.ESTIMATE,
      (this.opp.Required_Deposit__c / 100)
    );
    this.percentToPayByQuoteType.put(
      PandaDocQuoteType.PROPOSAL,
      (this.opp.Required_Deposit__c / 100)
    );
    this.percentToPayByQuoteType.put(
      PandaDocQuoteType.INVOICE,
      1 - (this.opp.Required_Deposit__c / 100)
    );
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

  public String getQuoteTemplateUuid() {
    String templateUuid;
    switch on this.quoteType {
      when ESTIMATE {
        templateUuid = this.isCCPayment
          ? this.quoteTemplateMapping.Pandadoc_CC_Fee_Estimate_Template_Id__c
          : this.quoteTemplateMapping.Pandadoc_Estimate_Template_Id__c;
      }
      when PROPOSAL {
        templateUuid = this.isCCPayment
          ? this.quoteTemplateMapping.Pandadoc_CC_Fee_Proposal_Template_Id__c
          : this.quoteTemplateMapping.Pandadoc_Proposal_Template_Id__c;
      }
      when INVOICE {
        templateUuid = this.isCCPayment
          ? this.quoteTemplateMapping.Pandadoc_CC_Fee_Invoice_Template_Id__c
          : this.quoteTemplateMapping.Pandadoc_Invoice_Template_Id__c;
      }
      when else {
        throw new PandaDocQuoteException(
          'Invalid quote type: ' + this.quoteType
        );
      }
    }
    return templateUuid;
  }

  @AuraEnabled(cacheable=true)
  public static Map<String, String> createPandaDocQuote(
    Id opportunityId,
    String quoteType
  ) {
    PandaDocQuoteController controller = new PandaDocQuoteController(
      opportunityId,
      quoteType.toLowerCase()
    );

    // Fetch a fresh Opportunity every time
    Opportunity freshOpp = new OpportunitySelector()
      .selectOpportunitiesByIds(new Set<Id>{ opportunityId })
      .get(0);

    controller.opp = freshOpp;
    controller.isCCPayment = freshOpp.CC_Payment__c;

    String ownerEmail = '';

    for (String phrase : companyEmailByUserEmailPhrase.keySet()) {
      if (UserInfo.getUserName().toLowerCase().contains(phrase.toLowerCase())) {
        ownerEmail = companyEmailByUserEmailPhrase.get(phrase);
        break;
      }
    }

    if (String.isBlank(ownerEmail)) {
      throw new PandaDocQuoteException(
        'Running user must have an email containing "Align", "Slate", or "Palermo" to send a PandaDoc quote.'
      );
    }

    Map<String, Object> requestBody = new Map<String, Object>{
      'name' => controller.getDocumentName(),
      'template_uuid' => controller.getQuoteTemplateUuid(),
      'recipients' => controller.getRecipients(),
      'owner' => new Map<String, String>{ 'email' => ownerEmail },
      'tokens' => controller.getTokens(),
      'metadata' => controller.getMetadata(),
      'pricing_tables' => controller.getPricingItems()
    };
    System.debug('PandaDoc Request Body: ' + JSON.serializePretty(requestBody));

    try {
      return PandadocApi.createDocument(
        requestBody,
        freshOpp.Division__r.Name.toLowerCase()
      );
    } catch (PandadocApi.PandaDocException e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static Map<String, String> checkDocumentStatus(
    String statusUrl,
    String opportunityId
  ) {
    try {
      Opportunity opp = new OpportunitySelector()
        .selectOpportunitiesByIds(new Set<Id>{ opportunityId })
        .get(0);
      return PandadocApi.checkDocumentStatus(
        statusUrl,
        opp.Division__r.Name.toLowerCase()
      );
    } catch (PandadocApi.PandaDocException e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static void attachDocumentToOpportunity(
    Id opportunityId,
    String documentId,
    String documentName,
    String quoteType
  ) {
    try {
      // Fetch the document content from PandaDoc API

      Opportunity opp = new OpportunitySelector()
        .selectOpportunitiesByIds(new Set<Id>{ opportunityId })
        .get(0);
      Blob documentContent = PandadocApi.getDocumentContent(
        documentId,
        opp.Division__r.Name.toLowerCase()
      );
      DateTime createdDate = opp.CreatedDate;
      String month = createdDate.month() < 10
        ? '0' + createdDate.month()
        : String.valueOf(createdDate.month());
      String day = createdDate.day() < 10
        ? '0' + createdDate.day()
        : String.valueOf(createdDate.day());
      String year = String.valueOf(createdDate.year());

      String formattedDate = month + '_' + day + '_' + year;
      String attachmentName =
        opp.Name +
        '_' +
        (opp.Division__r.Name != 'Palermo'
          ? opp.Division__r.Name.substring(0, 2).toUpperCase()
          : 'PL') +
        '_' +
        (quoteType == 'estimate'
          ? 'EST'
          : quoteType == 'proposal' ? 'PRO' : 'INV') +
        '_' +
        formattedDate;
      ContentVersion cv = new ContentVersion();
      cv.Title = attachmentName;
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
            updateOpportunityDocumentStage(opportunityId,quoteType);
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error attaching document: ' + e.getMessage()
      );
    }
  }

  // helpers
    private static void updateOpportunityDocumentStage(Id opportunityId,String quoteType){
        String stageValue;
        if(quoteType == 'Proposal'){
            stageValue = 'Proposal Generated';
        }
        else if(quoteType == 'Invoice'){
            stageValue = 'Invoice Generated';
        }
        else if(quoteType == 'Estimate'){
            stageValue = 'Quote Generated';
        }
        
        if(stageValue != null){
            update new Opportunity(Id=opportunityId,Stage_Document_Automated__c=stageValue);
        }
    }
  private String getDocumentName() {
    String divisionAbbreviation = this.opp.Division__r.Name.substring(0, 2)
      .toUpperCase();
    String typeAbbrev = '';
    if (this.quoteType == PandaDocQuoteType.Invoice) {
      typeAbbrev = '_INV';
    } else if (this.quoteType == PandaDocQuoteType.Estimate) {
      typeAbbrev = '_EST';
    } else {
      typeAbbrev = '_PRO';
    }
    String dateFormatted = this.opp.CreatedDate.format('MM_dd_yyyy');
    return this.opp.Name +
      typeAbbrev +
      '_' +
      divisionAbbreviation +
      '_' +
      dateFormatted;
  }

  private List<PandaDocQuoteToken> getTokens() {
    Decimal opportunityTotal =
      this.opp.Invoice_Amount__c +
      (this.opp.CC_Payment__c ? this.opp.CC_Fee_invoice__c : 0) +
      this.opp.Tax_to_collect__c;
    Decimal taxToCollect =
      this.opp.Tax_to_collect__c *
      this.percentToPayByQuoteType.get(this.quoteType);
    Decimal ccfee =
      this.opp.CC_Fee_invoice__c *
      this.percentToPayByQuoteType.get(this.quoteType);
    Decimal deposit = opportunityTotal * (this.opp.Required_Deposit__c / 100);
    Decimal balance = opportunityTotal - deposit;
    return new List<PandaDocQuoteToken>{
      new PandaDocQuoteToken('ACCOUNT_NAME', this.opp.Account.Name),
      new PandaDocQuoteToken('OPPORTUNITY_NAME', this.opp.Name),
      new PandaDocQuoteToken(
        'OPPORTUNITY_DESCRIPTION',
        this.opp.Upper_Descriptor__c
      ),
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
      new PandaDocQuoteToken(
        'INVOICE_NUMBER',
        opp.Division__r.Name.substring(0, 2).toUpperCase() +
          '-' +
          this.opp.InvoiceNumber__c
      ),
      new PandaDocQuoteToken('SALES_TAX', formatCurrency(taxToCollect)),
      new PandaDocQuoteToken('QUOTE_DEPOSIT', formatCurrency(deposit)),
      new PandaDocQuoteToken('BALANCE_DUE', formatCurrency(balance)),
      new PandaDocQuoteToken('CC_FEE', formatCurrency(ccfee)),
      new PandaDocQuoteToken('QUOTE_TOTAL', formatCurrency(opportunityTotal)),
      new PandaDocQuoteToken(
        'SHOOT_DATE',
        this.opp.Shoot_Date__c != null
          ? DateTime.newInstance(
                this.opp.Shoot_Date__c,
                Time.newInstance(0, 0, 0, 0)
              )
              .format('MM / dd / yyyy')
          : 'N/A'
      ),
      new PandaDocQuoteToken(
        'PROJECT_DESCRIPTION',
        String.isNotBlank(this.opp.Lead_Type__c) &&
          this.opp.Lead_Type__c.contains('-')
          ? this.opp.Lead_Type__c.substringAfter('-').trim()
          : String.isNotBlank(this.opp.Lead_Type__c) &&
              !this.opp.Lead_Type__c.contains('-')
              ? this.opp.Lead_Type__c
              : ''
      ),
      new PandaDocQuoteToken('DEPOSIT', this.opp.Required_Deposit__c),
      new PandaDocQuoteToken('BALANCE', (100.0 - this.opp.Required_Deposit__c))
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
    List<PandadocQuoteRecipient> recipients = new List<PandadocQuoteRecipient>{
      new PandadocQuoteRecipient(
        this.opp.PrimaryContact__r.Email,
        this.opp.PrimaryContact__r.FirstName,
        this.opp.PrimaryContact__r.LastName,
        'Payer'
      ),
      new PandadocQuoteRecipient(UserInfo.getUserEmail(), '', '', 'Sender')
    };

    if (String.isNotBlank(this.opp.Additional_Client_CC__c)) {
      for (String email : this.opp.Additional_Client_CC__c.split(',')) {
        recipients.add(
          new PandadocQuoteRecipient(email.trim(), '', '', null, 'cc')
        );
      }
    }

    return recipients;
  }

  private List<Map<String, Object>> getPricingItems() {
    Map<String, Object> table = new Map<String, Object>{
      'name' => PRICING_TABLE_NAME,
      'data_merge' => true,
      'options' => new Map<String, Object>{
        'Discount' => new Map<String, Object>{
          'type' => 'absolute',
          'name' => 'Global Discount',
          'value' => 50
        }
      },
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
        SBQQ__Description__c,
        SBQQ__ListPrice__c,
        SBQQ__CustomerPrice__c,
        SBQQ__Quantity__c,
        Days_on_Project5__c,
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
          'DESCRIPTION' => qli.SBQQ__Description__c,
          'Text_Unit_Cost__c' => String.valueOf(qli.SBQQ__ListPrice__c),
          'Text_Customer_Price__c' => String.valueOf(
            qli.SBQQ__CustomerPrice__c
          ),
          'Quantity' => String.valueOf(Integer.valueOf(qli.SBQQ__Quantity__c)),
          'Days_Required__c' => String.valueOf(qli.Days_on_Project5__c),
          'QTY' => String.valueOf(1), // has to be 1 to allow us to directly set the Pandadoc SubTotal via the Customer Total
          'Price' => qli.SBQQ__CustomerTotal__c,
          'SBQQ__CustomerTotal__c' => (qli.SBQQ__CustomerTotal__c *
          this.percentToPayByQuoteType.get(this.quoteType))
        }
      };
      System.debug('Pricing Row: ' + JSON.serializePretty(row));
      rows.add(row);
    }

    return rows;
  }

  private Map<String, String> getMetadata() {
    Map<String, String> metadata = new Map<String, String>();
    metadata.put('salesforce_opportunity_id', opportunityId);
    metadata.put('folder', 'opportunity');
    return metadata;
  }

  public class PandaDocQuoteException extends Exception {
  }
}
