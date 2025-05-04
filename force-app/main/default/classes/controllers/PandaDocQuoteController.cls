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

  private static Map<String, String> pandadocEmailByDivisionName = new Map<String, String>{
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

    if (
      quoteType.equalsIgnoreCase('Invoice') &&
      (this.opp.SBQQ__Quotes2__r == null || this.opp.SBQQ__Quotes2__r.isEmpty())
    ) {
      throw new PandaDocQuoteException('No Primary Quote');
    }
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
        templateUuid = this.quoteTemplateMapping.Pandadoc_Estimate_Template_Id__c;
      }
      when PROPOSAL {
        templateUuid = this.quoteTemplateMapping.Pandadoc_Proposal_Template_Id__c;
      }
      when INVOICE {
        templateUuid = this.quoteTemplateMapping.Pandadoc_Invoice_Template_Id__c;
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
    if (quoteType.equalsIgnoreCase('Callsheet')) {
      return PandadocCallSheetController.createPandaDocCallSheet(opportunityId);
    }
    if (!((String) opportunityId).startsWith('006')) {
      Opportunity oppFromQuote = new OpportunitySelector()
        .selectOpportunitiesByQuoteIds(new Set<Id>{ opportunityId })
        .get(0);
      opportunityId = oppFromQuote.Id;
    }
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

    String divisionName = freshOpp.Division__r.Name.toLowerCase();
    if (!pandadocEmailByDivisionName.containsKey(divisionName)) {
      throw new PandaDocQuoteException(
        'Running user must have an email containing "Align", "Slate", or "Palermo" to send a PandaDoc quote.'
      );
    }

    String ownerEmail = pandadocEmailByDivisionName.get(divisionName);
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
      Opportunity opp;
      if (((String) opportunityId).startsWith('006')) {
        opp = new OpportunitySelector()
          .selectOpportunitiesByIds(new Set<Id>{ opportunityId })
          .get(0);
      } else {
        opp = new OpportunitySelector()
          .selectOpportunitiesByQuoteIds(new Set<Id>{ opportunityId })
          .get(0);
      }

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

      Opportunity opp;
      if (((String) opportunityId).startsWith('006')) {
        opp = new OpportunitySelector()
          .selectOpportunitiesByIds(new Set<Id>{ opportunityId })
          .get(0);
      } else {
        opp = new OpportunitySelector()
          .selectOpportunitiesByQuoteIds(new Set<Id>{ opportunityId })
          .get(0);
        opportunityId = opp.Id;
      }
      Blob documentContent = PandadocApi.getDocumentContent(
        documentId,
        opp.Division__r.Name.toLowerCase()
      );
      String formattedDate = System.now().format('YYMMdd');
      String attachmentName =
        opp.Name +
        '_' +
        (opp.Division__r.Name != 'Palermo'
          ? opp.Division__r.Name.substring(0, 2).toUpperCase()
          : 'PL') +
        '_' +
        (quoteType == 'estimate'
          ? 'EST'
          : quoteType == 'proposal'
              ? 'PRO'
              : (quoteType == 'callsheet' ? 'CS' : 'INV')) +
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
      if (quoteType != 'callsheet') {
        updateOpportunityDocumentStage(opp, quoteType, documentId);
      }
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error attaching document: ' + e.getMessage()
      );
    }
  }

  // helpers
  private static void updateOpportunityDocumentStage(
    Opportunity opp,
    String quoteType,
    String documentId
  ) {
    String url = 'https://app.pandadoc.com/a/#/documents/' + documentId;
    Date dueDate = Date.today();

    if (quoteType == 'Proposal') {
      opp.Last_Proposal__c = url;
      opp.Stage_Document_Automated__c = 'Proposal Generated';
    } else if (quoteType == 'Invoice') {
      opp.Last_Invoice__c = url;
      opp.Stage_Document_Automated__c = 'Invoice Generated';
    } else if (quoteType == 'Estimate') {
      opp.Last_Estimate__c = url;
      opp.Stage_Document_Automated__c = 'Quote Generated';
    }
    if (opp.Stage_Document_Automated__c == 'Invoice Generated') {
      switch on opp.Payment__c {
        when 'Net 15' {
          opp.Invoice_Due_Date__c = dueDate.addDays(15);
        }
        when 'Net 30' {
          opp.Invoice_Due_Date__c = dueDate.addDays(30);
        }
        when 'Net 45' {
          opp.Invoice_Due_Date__c = dueDate.addDays(45);
        }
        when 'Net 60' {
          opp.Invoice_Due_Date__c = dueDate.addDays(60);
        }
      }
    }
    if (opp.Stage_Document_Automated__c != null) {
      update opp;
    }
  }
  private String getDocumentName() {
    String divisionAbbreviation = this.opp.Division__r.Name.substring(0, 2)
      .toUpperCase();
    String typeAbbrev = '';
    if (this.quoteType == PandaDocQuoteType.Invoice) {
      typeAbbrev = ' INV';
    } else if (this.quoteType == PandaDocQuoteType.Estimate) {
      typeAbbrev = ' EST';
    } else {
      typeAbbrev = ' PRO';
    }
    String dateFormatted = System.now().format('YYMMdd');
    return (this.opp.Name +
      typeAbbrev +
      ' ' +
      divisionAbbreviation +
      ' ' +
      dateFormatted)
      .replaceAll('_', ' ');
  }

  private List<PandaDocQuoteToken> getTokens() {
    // invoice amount already includes tax
    Decimal opportunityTotal = this.opp.Amount_QB__c;
    Decimal taxToCollect =
      this.opp.Tax_to_collect__c *
      this.percentToPayByQuoteType.get(this.quoteType);
    Decimal deposit = opportunityTotal * (this.opp.Required_Deposit__c / 100);
    Decimal balance = opportunityTotal - deposit;
    return new List<PandaDocQuoteToken>{
      new PandaDocQuoteToken(
        'Account.Name',
        this.opp.Account.Name != null ? this.opp.Account.Name : 'Do Not Replace'
      ),
      new PandaDocQuoteToken(
        'Opportunity Name',
        this.opp.Name != null ? this.opp.Name : 'Do Not Replace'
      ),
      new PandaDocQuoteToken(
        'Opportunity_Descriptor__c',
        this.opp.Opportunity_Descriptor__c != null
          ? this.opp.Opportunity_Descriptor__c.toUpperCase()
          : 'Do Not Replace'
      ),
      new PandaDocQuoteToken(
        'Invoice_Due_Date_Override__c',
        this.opp.Payment__c == 'due on receipt'
          ? 'Due on Receipt'
          : DateTime.newInstance(
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
        'InvoiceNumber__c',
        opp.Division__r.Name.substring(0, 2).toUpperCase() +
          '-' +
          this.opp.InvoiceNumber__c
      ),
      new PandaDocQuoteToken(
        'Payment__c',
        this.opp.Payment__c != null ? this.opp.Payment__c : 'Do Not Replace'
      ),
      new PandaDocQuoteToken('SALES_TAX', formatCurrency(taxToCollect)),
      new PandaDocQuoteToken('QUOTE_DEPOSIT', formatCurrency(deposit)),
      new PandaDocQuoteToken('QUOTE_BALANCE', formatCurrency(balance)),
      new PandaDocQuoteToken('QUOTE_TOTAL', formatCurrency(opportunityTotal)),
      new PandaDocQuoteToken(
        'Shoot_Date__c',
        this.opp.Shoot_Date__c != null
          ? DateTime.newInstance(
                this.opp.Shoot_Date__c,
                Time.newInstance(0, 0, 0, 0)
              )
              .format('MM / dd / yyyy')
          : 'Do Not Replace'
      ),
      new PandaDocQuoteToken(
        'PROJECT_DESCRIPTION',
        String.isNotBlank(this.opp.Lead_Type__c) &&
          this.opp.Lead_Type__c.contains('-')
          ? this.opp.Lead_Type__c.substringAfter('-').trim()
          : String.isNotBlank(this.opp.Lead_Type__c) &&
              !this.opp.Lead_Type__c.contains('-')
              ? this.opp.Lead_Type__c
              : 'Do Not Replace'
      ),
      new PandaDocQuoteToken(
        'Required_Deposit__c',
        this.opp.Required_Deposit__c
      ),
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
        'Client'
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
        Client_Info__c,
        SBQQ__ListPrice__c,
        SBQQ__CustomerPrice__c,
        SBQQ__Quantity__c,
        Days_on_Project5__c,
        SBQQ__CustomerTotal__c,
        SBQQ__SubscriptionTerm__c
      FROM SBQQ__QuoteLine__c
      WHERE
        SBQQ__Quote__r.SBQQ__Opportunity2__c = :this.opportunityId
        AND SBQQ__Quantity__c > 0
        AND SBQQ__Quote__r.SBQQ__Primary__c = TRUE
        AND SBQQ__CustomerTotal__c != 0
      ORDER BY SBQQ__Number__c ASC
    ]) {
      Decimal listPriceRoundedToTwoDecimals = qli.SBQQ__ListPrice__c.setScale(
        2
      );
      Decimal customerPriceRoundedToTwoDecimals = qli.SBQQ__CustomerPrice__c.setScale(
        2
      );
      Decimal customerTotalRoundedToTwoDecimals = qli.SBQQ__CustomerTotal__c.setScale(
        2
      );

      Map<String, Object> row = new Map<String, Object>{
        'options' => new Map<String, Object>{
          'optional' => false,
          'optional_selected' => true,
          'qty_editable' => false
        },
        'data' => new Map<String, Object>{
          'Name' => qli.SBQQ__Product__r.Name,
          /**
           * both descriptions need to be here
           */
          'Client_Info__c' => String.isNotBlank(qli.Client_Info__c)
            ? qli.Client_Info__c
            : '',
          'Text_Unit_Cost__c' => String.valueOf(listPriceRoundedToTwoDecimals),
          'Text_Customer_Price__c' => String.valueOf(
            customerPriceRoundedToTwoDecimals
          ),
          /**
           * both quantities need to be here
           */
          'SBQQ__Quantity__c' => String.valueOf(
            Integer.valueOf(qli.SBQQ__Quantity__c)
          ),
          'Quantity' => String.valueOf(Integer.valueOf(qli.SBQQ__Quantity__c)),
          'Days_on_Project5__c' => String.valueOf(qli.Days_on_Project5__c),
          'qty' => String.valueOf(1), // has to be 1 to allow us to directly set the Pandadoc SubTotal via the Customer Total
          'QTY' => String.valueOf(1), // has to be 1 to allow us to directly set the Pandadoc SubTotal via the Customer Total
          'Qty' => String.valueOf(1), // has to be 1 to allow us to directly set the Pandadoc SubTotal via the Customer Total
          'Price' => customerTotalRoundedToTwoDecimals,
          'SBQQ__CustomerTotal__c' => (customerTotalRoundedToTwoDecimals *
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
