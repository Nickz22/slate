public class L4GController {
  @AuraEnabled(cacheable=true)
  public static List<FieldWrapper> getFieldSet(
    String fieldSetName,
    String objectName
  ) {
    List<FieldWrapper> lstfieldWrapper = new List<FieldWrapper>();
    if (String.isNotBlank(fieldSetName) && String.isNotBlank(ObjectName)) {
      Schema.DescribeSObjectResult describeSObjectResult = Schema.getGlobalDescribe()
        .get(ObjectName)
        .getDescribe();
      Map<String, Schema.SObjectField> objFieldMap = describeSObjectResult.fields.getMap();
      Schema.FieldSet fieldSetObj = describeSObjectResult.FieldSets.getMap()
        .get(fieldSetName);
      if (fieldSetObj != null) {
        for (Schema.FieldSetMember fieldSet : fieldSetObj.getFields()) {
          String fieldApiName = fieldSet.getFieldPath();
          Schema.DescribeFieldResult fieldResult = objFieldMap.get(fieldApiName)
            .getDescribe();
          Boolean isReference = false;
          String referencedObjName;
          if (fieldResult.getType() == Schema.DisplayType.Reference) {
            isReference = true;
            referencedObjName = fieldResult.getReferenceTo()
              .get(0)
              .getDescribe()
              .getName();
          }
          lstfieldWrapper.add(
            new FieldWrapper(
              String.ValueOf(fieldSet.getLabel()),
              String.ValueOf(fieldSet.getFieldPath()),
              (fieldSet.getDBRequired() || fieldSet.getRequired()),
              isReference,
              referencedObjName
            )
          );
        }
      }
    }
    return lstfieldWrapper;
  }
  public class FieldWrapper {
    @AuraEnabled
    public String fieldName { get; set; }
    @AuraEnabled
    public String fieldLabel { get; set; }
    @AuraEnabled
    public Boolean isRequired { get; set; }
    @AuraEnabled
    public Boolean isReference { get; set; }
    @AuraEnabled
    public String referencedObjectName { get; set; }
    public FieldWrapper(
      String fieldLabel,
      String fieldName,
      Boolean isRequired,
      Boolean isReference,
      String referencedObjectName
    ) {
      this.fieldLabel = fieldLabel;
      this.fieldName = fieldName;
      this.isRequired = isRequired;
      this.isReference = isReference;
      this.referencedObjectName = referencedObjectName;
    }
  }
  @AuraEnabled(cacheable=true)
  public static list<sObject> fetchLookupData(
    string searchKey,
    string sObjectApiName
  ) {
    List<sObject> returnList = new List<sObject>();
    string sWildCardText = '%' + searchKey + '%';
    string sQuery =
      'Select Id,Name From ' +
      sObjectApiName +
      ' Where Name Like : sWildCardText order by createdDate DESC LIMIT 5';
    for (sObject obj : database.query(sQuery)) {
      returnList.add(obj);
    }
    return returnList;
  }
  @AuraEnabled
  public static Id getAccountId(String domain) {
    List<Account> acc = [SELECT Id FROM Account WHERE Name = :domain];
    if (acc.size() > 0) {
      return acc[0].Id;
    }
    return null;
  }
  @AuraEnabled
  public static Map<String, String> checkIfContactExists(
    List<String> emailIds
  ) {
    Map<String, String> conEmailToIds = new Map<String, String>();
    List<Contact> contacts = [
      SELECT Id, Email
      FROM Contact
      WHERE Email = :emailIds
    ];
    if (contacts.size() > 0) {
      for (Contact con : contacts) {
        conEmailToIds.put(con.Email, con.Id);
      }
      return conEmailToIds;
    }
    return null;
  }
  @AuraEnabled
  public static sObject fetchDefaultRecord(
    string recordId,
    string sObjectApiName
  ) {
    string sRecId = recordId;
    string sQuery =
      'Select Id,Name From ' +
      sObjectApiName +
      ' Where Id = : sRecId LIMIT 1';
    for (sObject obj : database.query(sQuery)) {
      return obj;
    }
    return null;
  }
  @AuraEnabled
  public static Id cloneRecord(
    Id recordId,
    Map<String, Object> opportunityData
  ) {
    System.debug(JSON.serializePretty(opportunityData));
    List<String> fields = new List<String>(
      Opportunity.SObjectType.getDescribe().fields.getMap().keySet()
    );
    String soql =
      '' +
      ' select ' +
      String.join(fields, ',') +
      ', Account.Name' +
      ' from Opportunity' +
      ' where Id = \'' +
      recordId +
      '\'';
    List<Opportunity> originalRecord = Database.query(soql);
    Opportunity clonedRecord = originalRecord[0]
      ?.clone(false, true, false, false);
    for (String field : opportunityData.keySet()) {
      if (
        field.containsIgnoreCase('date') && opportunityData.get(field) != null
      ) {
        clonedRecord.put(
          field,
          Date.valueOf((String) opportunityData.get(field))
        );
      } else {
        clonedRecord.put(field, opportunityData.get(field));
      }
    }
    //clonedRecord.CloseDate = Date.today();
    clonedRecord.Invoice_Due_Date_Override__c = null;
    String oppNamee = OpportunityTriggerHandler.setOppName(
      clonedRecord.Lead_Type__c,
      originalRecord[0].Account.Name
    );
    clonedRecord.Name = oppNamee;
    List<OpportunityContactRole> existingOCRs = [
      SELECT Id, OpportunityId, ContactId, Role, IsPrimary
      FROM OpportunityContactRole
      WHERE OpportunityId = :recordId
    ];
    if (originalRecord[0].SBQQ__PrimaryQuote__c != null) {
      OpportunityTriggerHandler.autoGenerateQuote = false;
    }
    insert clonedRecord;
    if (originalRecord[0].SBQQ__PrimaryQuote__c != null) {
      List<String> quoteFields = new List<String>(
        SBQQ__Quote__c.SObjectType.getDescribe().fields.getMap().keySet()
      );
      String quoteSoql =
        '' +
        ' select ' +
        String.join(quoteFields, ',') +
        ' from SBQQ__Quote__c' +
        ' where Id = \'' +
        originalRecord[0].SBQQ__PrimaryQuote__c +
        '\'';
      List<SBQQ__Quote__c> originalQuote = Database.query(quoteSoql);
      System.debug('originalQuote' + originalQuote);
      SBQQ__Quote__c clonedQuote = originalQuote[0]
        ?.clone(false, true, false, false);
      clonedQuote.SBQQ__Opportunity2__c = clonedRecord.Id;
      insert clonedQuote;
      clonedRecord.SBQQ__PrimaryQuote__c = clonedQuote.Id;
      update clonedRecord;
    }

    if (clonedRecord.SBQQ__PrimaryQuote__c != null) {
      List<String> quoteFields = new List<String>(
        SBQQ__QuoteLine__c.SObjectType.getDescribe().fields.getMap().keySet()
      );
      String quoteLineSoql =
        '' +
        ' select ' +
        String.join(quoteFields, ',') +
        ' from SBQQ__QuoteLine__c' +
        ' where SBQQ__Quote__c = \'' +
        originalRecord[0].SBQQ__PrimaryQuote__c +
        '\'';
      List<SBQQ__QuoteLine__c> quoteLineItems = Database.query(quoteLineSoql);
      List<SBQQ__QuoteLine__c> clonedItems = new List<SBQQ__QuoteLine__c>();
      if (quoteLineItems != null && quoteLineItems.size() > 0) {
        for (SBQQ__QuoteLine__c item : quoteLineItems) {
          SBQQ__QuoteLine__c clonedItem = item.clone(false, true, false, false);
          clonedItem.SBQQ__Quote__c = clonedRecord.SBQQ__PrimaryQuote__c;
          clonedItems.add(clonedItem);
        }
        insert clonedItems;

        // Call the future method to calculate the quote after the transaction completes
        calculateQuoteAsync(clonedRecord.SBQQ__PrimaryQuote__c);
      }
    }

    if (existingOCRs.size() > 0) {
      List<OpportunityContactRole> contactRolesToInsert = new List<OpportunityContactRole>();
      for (OpportunityContactRole ocr : existingOCRs) {
        OpportunityContactRole newOcr = ocr.clone(false, true, false, false);
        newOcr.OpportunityId = clonedRecord.Id;
        contactRolesToInsert.add(newOcr);
      }
      insert contactRolesToInsert;
    }

    return clonedRecord.Id;
  }

  /**
   * Asynchronous method to calculate a quote using a direct REST call
   * Uses @future to avoid "uncommitted work pending" errors when called after DML operations
   */
  @future(callout=true)
  public static void calculateQuoteAsync(Id quoteId) {
    try {
      // Use a direct REST callout to calculate the quote
      HttpRequest req = new HttpRequest();
      req.setEndpoint(
        URL.getOrgDomainUrl().toExternalForm() +
        '/services/apexrest/SBQQ/ServiceRouter'
      );
      req.setMethod('POST');
      req.setHeader('Content-Type', 'application/json');
      req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());

      // Build the request payload - simpler direct approach
      Map<String, Object> payload = new Map<String, Object>{
        'quote' => new Map<String, String>{ 'Id' => quoteId },
        'methodName' => 'calculateAndSave'
      };

      req.setBody(JSON.serialize(payload));

      // Execute the callout
      Http http = new Http();
      HttpResponse res = http.send(req);

      // Log the response
      System.debug('CPQ calculate API response status: ' + res.getStatusCode());
      System.debug('CPQ calculate API response body: ' + res.getBody());

      if (res.getStatusCode() != 200) {
        // If REST call fails, fall back to toggle method
        System.debug('REST callout failed, falling back to toggle approach');
        SBQQ__Quote__c quoteToRecalculate = new SBQQ__Quote__c(
          Id = quoteId,
          CPQ_Recalculate__c = true
        );
        update quoteToRecalculate;
      }
    } catch (Exception e) {
      System.debug('Error in CPQ calculation API: ' + e.getMessage());
      System.debug('Error stack trace: ' + e.getStackTraceString());

      // Fallback method - toggle the recalculate field
      try {
        SBQQ__Quote__c quoteToRecalculate = new SBQQ__Quote__c(
          Id = quoteId,
          CPQ_Recalculate__c = true
        );
        update quoteToRecalculate;
      } catch (Exception e2) {
        System.debug('Fallback calculation also failed: ' + e2.getMessage());
      }
    }
  }
  @AuraEnabled(cacheable=true)
  public static List<String> getFieldsToView(
    String fieldSetName,
    String objectName
  ) {
    List<String> fields = new List<String>();
    if (String.isNotBlank(fieldSetName) && String.isNotBlank(ObjectName)) {
      Schema.DescribeSObjectResult describeSObjectResult = Schema.getGlobalDescribe()
        .get(ObjectName)
        .getDescribe();
      Map<String, Schema.SObjectField> objFieldMap = describeSObjectResult.fields.getMap();
      Schema.FieldSet fieldSetObj = describeSObjectResult.FieldSets.getMap()
        .get(fieldSetName);
      if (fieldSetObj != null) {
        for (Schema.FieldSetMember fieldSet : fieldSetObj.getFields()) {
          String fieldApiName = fieldSet.getFieldPath();
          fields.add(fieldApiName);
        }
      }
    }
    return fields;
  }
  @AuraEnabled(cacheable=true)
  public static List<Opportunity> getRelatedOpportunities(Id contactId) {
    return [
      SELECT
        Id,
        Name,
        Amount,
        StageName,
        CloseDate,
        SBQQ__PrimaryQuote__r.Name,
        Division__r.Name,
        toLabel(Lead_Type__c),
        Opportunity_Descriptor__c,
        SBQQ__PrimaryQuote__c
      FROM Opportunity
      WHERE PrimaryContact__c = :contactId
      ORDER BY CreatedDate DESC
    ];
  }
  @AuraEnabled
  public static List<Division__c> getDivisions() {
    return [
      SELECT Name
      FROM Division__c
      WHERE Division_Leader__c = :UserInfo.getUserId()
    ];
  }
  @AuraEnabled(cacheable=true)
  public static List<Pricebook2> getPricebook() {
    return [SELECT Id, Name FROM Pricebook2 WHERE IsActive = TRUE];
  }
  @AuraEnabled(cacheable=true)
  public static string getSfdcURL() {
    return URL.getOrgDomainURL().toExternalForm();
  }
  @AuraEnabled
  public static String getOpportunityName(String serviceType, Id accountId) {
    Account account = [SELECT Name FROM Account WHERE Id = :accountId];
    return OpportunityTriggerHandler.setOppName(serviceType, account.Name);
  }
}
