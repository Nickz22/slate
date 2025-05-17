// This script will execute the Account Primary Contact batch job
// to backfill missing primary contacts on Accounts based on Opportunities

// Execute the batch job
AccountPrimaryContactBatch batchJob = new AccountPrimaryContactBatch();
Id batchJobId = Database.executeBatch(batchJob, 200);
System.debug(
  'Starting Account Primary Contact backfill with job ID: ' + batchJobId
);
