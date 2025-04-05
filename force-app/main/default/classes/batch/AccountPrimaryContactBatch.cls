global class AccountPrimaryContactBatch implements Database.Batchable<sObject>, Database.Stateful {
  private Integer recordsProcessed = 0;
  private Integer recordsUpdated = 0;

  global Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(
      'SELECT Id, Contact__c FROM Account WHERE Contact__c = NULL'
    );
  }

  global void execute(Database.BatchableContext bc, List<Account> scope) {
    if (scope.isEmpty()) {
      return;
    }

    recordsProcessed += scope.size();
    Map<Id, Account> accountsToUpdate = new Map<Id, Account>();

    // Get account IDs from the scope
    Set<Id> accountIds = new Set<Id>();
    for (Account acc : scope) {
      accountIds.add(acc.Id);
    }

    // Find the most recent Opportunity for each Account with PrimaryContact__c populated
    Map<Id, Id> accountToPrimaryContactMap = new Map<Id, Id>();

    for (Opportunity opp : [
      SELECT Id, AccountId, PrimaryContact__c, CreatedDate
      FROM Opportunity
      WHERE AccountId IN :accountIds AND PrimaryContact__c != NULL
      ORDER BY CreatedDate DESC
    ]) {
      if (!accountToPrimaryContactMap.containsKey(opp.AccountId)) {
        accountToPrimaryContactMap.put(opp.AccountId, opp.PrimaryContact__c);
      }
    }

    // Update accounts with primary contact from opportunities
    List<Account> accountsToUpdateList = new List<Account>();
    for (Account acc : scope) {
      if (accountToPrimaryContactMap.containsKey(acc.Id)) {
        acc.Contact__c = accountToPrimaryContactMap.get(acc.Id);
        accountsToUpdateList.add(acc);
      }
    }

    if (!accountsToUpdateList.isEmpty()) {
      recordsUpdated += accountsToUpdateList.size();
      update accountsToUpdateList;
    }
  }

  global void finish(Database.BatchableContext bc) {
    // Send email notification with results
    AsyncApexJob job = [
      SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems
      FROM AsyncApexJob
      WHERE Id = :bc.getJobId()
    ];

    String emailSubject = 'Account Primary Contact Backfill Job Complete';
    String emailBody = 'The batch job to update Account Primary Contacts has completed.\n\n';
    emailBody += 'Job Status: ' + job.Status + '\n';
    emailBody += 'Total Accounts Processed: ' + recordsProcessed + '\n';
    emailBody += 'Total Accounts Updated: ' + recordsUpdated + '\n';
    emailBody += 'Number of Errors: ' + job.NumberOfErrors;

    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setSubject(emailSubject);
    mail.setPlainTextBody(emailBody);

    // Get the org-wide email address
    OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
    if (!owea.isEmpty()) {
      mail.setOrgWideEmailAddressId(owea[0].Id);
    }

    // Get admin users to send email to
    List<String> adminEmails = new List<String>();
    for (User admin : [
      SELECT Email
      FROM User
      WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE
      LIMIT 5
    ]) {
      adminEmails.add(admin.Email);
    }

    if (!adminEmails.isEmpty()) {
      mail.setToAddresses(adminEmails);
      try {
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
      } catch (Exception e) {
        System.debug('Error sending email: ' + e.getMessage());
      }
    }
  }
}
