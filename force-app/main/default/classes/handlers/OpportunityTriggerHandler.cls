public class OpportunityTriggerHandler {
  public static Boolean ToCreateCalendarRecord = true;
  public static Boolean ToDeleteCalendarRecordOnHoldRecords = true;
  public static Map<Id, Account> accounts = new Map<Id, Account>();
  public static Boolean autoGenerateQuote = true;

  public static void onBeforeInsert(List<Opportunity> newOpps) {
    Set<Id> divisionIds = new Set<Id>();

    for (Opportunity opp : newOpps) {
      divisionIds.add(opp.Division__c);
    }

    Map<Id, Division__c> divisionById = new Map<Id, Division__c>(
      [SELECT Name FROM Division__c WHERE Id IN :divisionIds]
    );
    for (Opportunity opp : newOpps) {
      if (opp.Division__c == null) {
        opp.addError('Division is required');
        continue;
      }
      opp.Division_Name__c = divisionById.get(opp.Division__c).Name;
    }

    setRequiredDepositDefaults(newOpps, divisionById);
  }

  public static void onAfterInsert(Map<Id, Opportunity> newMap) {
    if (autoGenerateQuote) {
      AutoQuoteGeneration.autoQuote(newMap.values()[0].Id);
    }

    updateAccountPrimaryContact(newMap.values());
  }

  public static void onBeforeUpdate(
    Map<Id, Opportunity> oldMap,
    List<Opportunity> newRecords
  ) {
    Set<Id> accIds = new Set<Id>();
    List<Opportunity> closedWonOpportunities = new List<Opportunity>();
    Set<Id> divisionIds = new Set<Id>();

    for (Opportunity opp : newRecords) {
      divisionIds.add(opp.Division__c);

      if (
        opp.StageName.contains('Won') &&
        opp.StageName != oldMap.get(opp.Id).StageName
      ) {
        accIds.add(opp.AccountId);
        closedWonOpportunities.add(opp);
      }
    }

    Map<Id, Division__c> divisionById = new Map<Id, Division__c>(
      [SELECT Name FROM Division__c WHERE Id IN :divisionIds]
    );

    setRequiredDepositDefaults(newRecords, divisionById);

    Map<Id, Account> accountMap = new Map<Id, Account>(
      [SELECT Id, Payment_Terms__c FROM Account WHERE Id IN :accIds]
    );

    for (Opportunity opp : closedWonOpportunities) {
      Date dueDate = opp.CloseDate;
      Account acc = accountMap.get(opp.AccountId);

      if (acc.Payment_Terms__c == null) {
        opp.Invoice_Due_Date__c = opp.CloseDate;
        continue;
      }

      switch on acc.Payment_Terms__c {
        when 'Net 15' {
          dueDate = dueDate.addDays(15);
        }
        when 'Net 30' {
          dueDate = dueDate.addDays(30);
        }
        when 'Net 45' {
          dueDate = dueDate.addDays(45);
        }
        when 'Net 60' {
          dueDate = dueDate.addDays(60);
        }
      }

      opp.Invoice_Due_Date__c = dueDate;
    }
  }

  public static void onAfterUpdate(
    Map<Id, Opportunity> oldMap,
    List<Opportunity> newRecords
  ) {
    Set<Id> accIds = new Set<Id>();
    List<Opportunity> closedWonOpportunities = new List<Opportunity>();
    for (Opportunity opp : newRecords) {
      if (
        opp.Invoice_Due_Date_Override__c !=
        oldMap.get(opp.Id).Invoice_Due_Date_Override__c
      ) {
        CreateUpdateInvoiceFuture(opp.Id);
      }
    }

    List<Opportunity> oppsNeedingCCFeeUpdate = new List<Opportunity>();
    List<Opportunity> oppsNeedingPrimaryContactUpdate = new List<Opportunity>();
    for (Opportunity opp : newRecords) {
      Opportunity oldOpp = oldMap.get(opp.Id);
      if (
        opp.CC_Payment__c != oldOpp.CC_Payment__c ||
        (opp.CC_Payment__c && opp.Amount != oldOpp.Amount)
      ) {
        oppsNeedingCCFeeUpdate.add(opp);
      }

      if (opp.PrimaryContact__c != oldOpp.PrimaryContact__c) {
        oppsNeedingPrimaryContactUpdate.add(opp);
      }
    }

    if (!oppsNeedingCCFeeUpdate.isEmpty()) {
      handleCCFeeQuoteLineItems(oppsNeedingCCFeeUpdate, oldMap);
    }

    if (!oppsNeedingPrimaryContactUpdate.isEmpty()) {
      updateAccountPrimaryContact(oppsNeedingPrimaryContactUpdate);
    }
  }

  private static void updateAccountPrimaryContact(
    List<Opportunity> opportunities
  ) {
    Set<Id> accountIds = new Set<Id>();
    Map<Id, Id> primaryContactIdByAccountId = new Map<Id, Id>();

    for (Opportunity opp : opportunities) {
      if (opp.PrimaryContact__c != null && opp.AccountId != null) {
        accountIds.add(opp.AccountId);
        primaryContactIdByAccountId.put(opp.AccountId, opp.PrimaryContact__c);
      }
    }

    if (accountIds.isEmpty()) {
      return;
    }

    List<Account> accountsToUpdate = new List<Account>();
    for (Account acc : [
      SELECT Id, Contact__c
      FROM Account
      WHERE Id IN :accountIds
    ]) {
      acc.Contact__c = primaryContactIdByAccountId.get(acc.Id);
      accountsToUpdate.add(acc);
    }

    if (!accountsToUpdate.isEmpty()) {
      update accountsToUpdate;
    }
  }

  public static void handleCCFeeQuoteLineItems(
    List<Opportunity> opportunities,
    Map<Id, Opportunity> oldMap
  ) {
    Set<Id> oppIds = new Set<Id>();

    for (Opportunity opp : opportunities) {
      oppIds.add(opp.Id);
    }

    Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
      [
        SELECT
          Id,
          CC_Payment__c,
          Amount,
          Division__r.Name,
          (
            SELECT Id
            FROM SBQQ__Quotes2__r
            WHERE SBQQ__Primary__c = TRUE
            LIMIT 1
          )
        FROM Opportunity
        WHERE Id IN :oppIds
      ]
    );

    Product2 ccFeeProduct = [
      SELECT Id, Name, ProductCode
      FROM Product2
      WHERE Name = 'CC Processing Fee' AND IsActive = TRUE
      LIMIT 1
    ];

    Map<Id, SBQQ__Quote__c> quoteByOppId = new Map<Id, SBQQ__Quote__c>();
    for (Opportunity opp : oppMap.values()) {
      if (!opp.SBQQ__Quotes2__r.isEmpty()) {
        quoteByOppId.put(opp.Id, opp.SBQQ__Quotes2__r[0]);
      }
    }

    Map<Id, List<SBQQ__QuoteLine__c>> quoteLinesByQuoteId = new Map<Id, List<SBQQ__QuoteLine__c>>();
    for (SBQQ__QuoteLine__c line : [
      SELECT
        Id,
        SBQQ__Quote__c,
        SBQQ__Product__c,
        SBQQ__Product__r.Name,
        SBQQ__CustomerPrice__c
      FROM SBQQ__QuoteLine__c
      WHERE
        SBQQ__Quote__c IN :quoteByOppId.values()
        AND SBQQ__Product__r.Name = 'CC Processing Fee'
    ]) {
      if (!quoteLinesByQuoteId.containsKey(line.SBQQ__Quote__c)) {
        quoteLinesByQuoteId.put(
          line.SBQQ__Quote__c,
          new List<SBQQ__QuoteLine__c>()
        );
      }
      quoteLinesByQuoteId.get(line.SBQQ__Quote__c).add(line);
    }

    List<SBQQ__QuoteLine__c> linesToInsert = new List<SBQQ__QuoteLine__c>();
    List<SBQQ__QuoteLine__c> linesToUpdate = new List<SBQQ__QuoteLine__c>();
    List<SBQQ__QuoteLine__c> linesToDelete = new List<SBQQ__QuoteLine__c>();

    for (Opportunity opp : opportunities) {
      SBQQ__Quote__c quote = quoteByOppId.get(opp.Id);

      if (quote == null || ccFeeProduct == null)
        continue;

      List<SBQQ__QuoteLine__c> existingCCLines = quoteLinesByQuoteId.containsKey(
          quote.Id
        )
        ? quoteLinesByQuoteId.get(quote.Id)
        : new List<SBQQ__QuoteLine__c>();

      if (opp.CC_Payment__c) {
        Decimal ccFeeAmount = opp.Amount * 0.045;
        Decimal ccFeeCost = opp.Amount * 0.03;

        if (existingCCLines.isEmpty()) {
          SBQQ__QuoteLine__c newLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = ccFeeProduct.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__ListPrice__c = ccFeeAmount,
            SBQQ__CustomerPrice__c = ccFeeAmount,
            SBQQ__UnitCost__c = ccFeeCost,
            SBQQ__Description__c = 'Credit Card Processing Fee'
          );
          linesToInsert.add(newLine);
        } else {
          SBQQ__QuoteLine__c lineToUpdate = existingCCLines[0];
          if (lineToUpdate.SBQQ__CustomerPrice__c != ccFeeAmount) {
            lineToUpdate.SBQQ__ListPrice__c = ccFeeAmount;
            lineToUpdate.SBQQ__CustomerPrice__c = ccFeeAmount;
            lineToUpdate.SBQQ__UnitCost__c = ccFeeCost;
            linesToUpdate.add(lineToUpdate);
          }
        }
      } else if (!opp.CC_Payment__c && !existingCCLines.isEmpty()) {
        linesToDelete.addAll(existingCCLines);
      }
    }

    if (!linesToInsert.isEmpty()) {
      insert linesToInsert;
    }

    if (!linesToUpdate.isEmpty()) {
      update linesToUpdate;
    }

    if (!linesToDelete.isEmpty()) {
      delete linesToDelete;
    }
  }

  public static void setRequiredDepositDefaults(
    List<Opportunity> opps,
    Map<Id, Division__c> divisionById
  ) {
    Map<String, Decimal> depositByDivision = new Map<String, Decimal>();

    for (Required_Deposit_Default__mdt depositDefault : [
      SELECT Division_Name__c, Default_Required_Deposit__c
      FROM Required_Deposit_Default__mdt
    ]) {
      depositByDivision.put(
        depositDefault.Division_Name__c,
        depositDefault.Default_Required_Deposit__c
      );
    }

    for (Opportunity opp : opps) {
      if (opp.Required_Deposit__c == null && opp.Division__c != null) {
        String divisionName = divisionById.get(opp.Division__c).Name;
        if (depositByDivision.containsKey(divisionName)) {
          opp.Required_Deposit__c = depositByDivision.get(divisionName);
        }
      }
    }
  }

  public static String setOppName(String LeadType, String accountName) {
    String datePart = System.now().format('YYMMdd') + '_';

    String accPart = accountName.replaceAll(' ', '');
    accPart = accPart.toUpperCase() + '_';

    String leadTypePart = 'EC';

    switch on (LeadType) {
      when 'Brand Content' {
        leadTypePart = 'BC';
      }
      when 'Studio Rental' {
        leadTypePart = 'SR';
      }
      when 'Motion' {
        leadTypePart = 'MT';
      }
      when 'Retouching - Align', 'Retouching' {
        leadTypePart = 'RT';
      }
      when 'Casablanca - Motion Production' {
        leadTypePart = 'CMP';
      }
      when 'Casablanca - Motion Post Production' {
        leadTypePart = 'CMPP';
      }
      when 'Palermo - Branding' {
        leadTypePart = 'BR';
      }
      when 'Palermo - Digital/UX' {
        leadTypePart = 'UX';
      }
      when 'Align - CGI', 'Slate - CGI', 'Palermo - CGI' {
        leadTypePart = 'CG';
      }
      when 'Align - VFX/Animation' {
        leadTypePart = 'VX';
      }
      when 'Palermo - Photo Production' {
        leadTypePart = 'BC';
      }
      when 'Palermo - Video Production' {
        leadTypePart = 'MT';
      }
      when 'Align - Video Editing' {
        leadTypePart = 'VE';
      }
    }

    return datePart + accPart + leadTypePart;
  }
  @future(callout=true)
  private static void CreateUpdateInvoiceFuture(String oppId) {
    CreateUpdateQBInvoiceByUser.CreateUpdateInvoice(oppId);
  }
}
