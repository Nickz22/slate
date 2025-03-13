public class PandadocCallSheetController {
  private static final String PRICING_TABLE_NAME = 'Pricing_Table';
  private Id opportunityId;
  private Opportunity opp;
  private Pandadoc_Quote_Template_Mapping__mdt callSheetTemplateMapping;

  private static Map<String, String> companyEmailByUserEmailPhrase = new Map<String, String>{
    'align' => 'info@align-ny.com',
    'slate' => 'info@slate-nyc.com',
    'palermo' => 'info@palermo-studio.com'
  };

  public PandadocCallSheetController(Id oppId) {
    this.opportunityId = oppId;
    this.opp = new OpportunitySelector()
      .selectOpportunitiesByIds(new Set<Id>{ oppId })
      .get(0);

    
    try {
      this.callSheetTemplateMapping = new PandadocQuoteMappingSelector()
        .selectPandadocQuoteTemplateMappingByDivisionName(
          this.opp.Division__r.Name
        );
    } catch (Exception e) {
      throw new PandaDocQuoteException(
        'Error getting call sheet template mapping. Does a Callsheet Template mapping exist for this division? ' +
        e.getMessage()
      );
    }
  }

  public String getCallSheetTemplateUuid() {
    return this.callSheetTemplateMapping.Pandadoc_Call_Sheet_Template_Id__c;
  }

  @AuraEnabled(cacheable=true)
  public static Map<String, String> createPandaDocCallSheet(
    Id opportunityId
  ) {
    PandadocCallSheetController controller = new PandadocCallSheetController(
      opportunityId
    );

    // Fetch a fresh Opportunity every time
    Opportunity freshOpp = new OpportunitySelector()
      .selectOpportunitiesByIds(new Set<Id>{ opportunityId })
      .get(0);

    controller.opp = freshOpp;

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
      'template_uuid' => controller.getCallSheetTemplateUuid(),
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
      String formattedDate = System.now().format('YYMMdd');
      String attachmentName =
        opp.Name +
        '_' +
        (opp.Division__r.Name != 'Palermo'
          ? opp.Division__r.Name.substring(0, 2).toUpperCase()
          : 'PL') +
        '_CS_' +
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
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error attaching document: ' + e.getMessage()
      );
    }
  }

  private String getDocumentName() {
    String divisionAbbreviation = this.opp.Division__r.Name.substring(0, 2)
      .toUpperCase();
    String typeAbbrev = 'CS';
    String dateFormatted = System.now().format('YYMMdd');
    return (this.opp.Name +
      typeAbbrev +
      ' ' +
      divisionAbbreviation +
      ' ' +
      dateFormatted).replaceAll('_',' ');
  }

  private List<PandaDocQuoteToken> getTokens() {
    // invoice amount already includes tax
    
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
        Client_Info__c,
        SBQQ__ListPrice__c,
        SBQQ__CustomerPrice__c,
        SBQQ__Quantity__c,
        Days_on_Project5__c,
        SBQQ__CustomerTotal__c,
        SBQQ__SubscriptionTerm__c,
        Vendor__r.Email
      FROM SBQQ__QuoteLine__c
      WHERE
        SBQQ__Quote__r.SBQQ__Opportunity2__c = :this.opportunityId
        AND SBQQ__Quote__r.SBQQ__Primary__c = TRUE
        AND Include_in_Call_Sheet__c = true
    ]) {
      Map<String, Object> row = new Map<String, Object>{
        'options' => new Map<String, Object>{
          'optional' => false,
          'optional_selected' => true,
          'qty_editable' => false
        },
        'data' => new Map<String, Object>{
          'Name' => qli.SBQQ__Product__r.Name,
          'Role__c' => qli.SBQQ__Product__r.Name,
          /**
           * both descriptions need to be here
           */
          'DESCRIPTION' => String.isNotBlank(qli.Client_Info__c) ? qli.Client_Info__c : '',
          'Description' => String.isNotBlank(qli.Client_Info__c) ? qli.Client_Info__c : '',
          'E_mail__c' => String.isNotBlank(qli.Vendor__r.Email)? qli.Vendor__r.Email : '',
          'Text_Customer_Price__c' => String.valueOf(
            qli.SBQQ__CustomerPrice__c
          ),
          /**
           * both quantities need to be here
           */
          'QUANTITY' => String.valueOf(Integer.valueOf(qli.SBQQ__Quantity__c)),
          'Quantity' => String.valueOf(Integer.valueOf(qli.SBQQ__Quantity__c)),
          'Days_Required__c' => String.valueOf(qli.Days_on_Project5__c),
          'qty' => String.valueOf(1), // has to be 1 to allow us to directly set the Pandadoc SubTotal via the Customer Total
          'QTY' => String.valueOf(1), // has to be 1 to allow us to directly set the Pandadoc SubTotal via the Customer Total
          'Qty' => String.valueOf(1), // has to be 1 to allow us to directly set the Pandadoc SubTotal via the Customer Total
          'Price' => qli.SBQQ__CustomerTotal__c
        }
      };
      System.debug('Pricing Row: ' + JSON.serializePretty(row));
      rows.add(row);
    }

    if(this.opp.CC_Payment__c){
      Map<String, Object> row = new Map<String, Object>{
        'options' => new Map<String, Object>{
          'optional' => false,
          'optional_selected' => true,
          'qty_editable' => false
        },
        'data' => new Map<String, Object>{
          'Name' => 'CC Fee',
          'Text_Unit_Cost__c' => String.valueOf(this.opp.CC_Fee_invoice__c),
          'Quantity' => String.valueOf(1),
          'Days_Required__c' => String.valueOf(0),
          'qty' => String.valueOf(1),
          'QTY' => String.valueOf(1),
          'Price' => this.opp.CC_Fee_invoice__c,
          'SBQQ__CustomerTotal__c' => this.opp.CC_Fee_invoice__c
        }
      };
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