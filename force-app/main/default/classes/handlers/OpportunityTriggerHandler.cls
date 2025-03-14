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
      opp.Division_Name__c = divisionById.get(opp.Division__c).Name;
    }
  }

  public static void onAfterInsert(Map<Id, Opportunity> newMap) {
      if(autoGenerateQuote){
          AutoQuoteGeneration.autoQuote(newMap.values()[0].Id);
      }
  }
  
    public static void onBeforeUpdate(Map<Id, Opportunity> oldMap,List<Opportunity> newRecords) {
        Set<Id> accIds = new Set<Id>();
        List<Opportunity> closedWonOpportunities = new List<Opportunity>();
        for(Opportunity opp : newRecords){
            if((opp.StageName.equalsIgnoreCase('Won - Production Complete') || opp.StageName.equalsIgnoreCase('Closed Won')) && opp.StageName != oldMap.get(opp.Id).StageName){
				accIds.add(opp.AccountId);
				closedWonOpportunities.add(opp);                
            }
        }
        Map<Id,Account> accountMap = new Map<Id,Account>([Select Id,Payment_Terms__c from Account where Id IN :accIds]);
        
        for(Opportunity opp : closedWonOpportunities){
            Date dueDate = opp.CloseDate;
            switch on accountMap.get(opp.AccountId).Payment_Terms__c{
                when 'Net 15'{
                    dueDate = dueDate.addDays(15);
                }
                when 'Net 30'{
                    dueDate = dueDate.addDays(30);
                }
                when 'Net 45'{
                    dueDate = dueDate.addDays(45);
                }
                when 'Net 60'{
                    dueDate = dueDate.addDays(60);
                }
            }
            
            opp.Invoice_Due_Date__c = dueDate;
        }
    }
    
    public static void onAfterUpdate(Map<Id, Opportunity> oldMap,List<Opportunity> newRecords) {
        Set<Id> accIds = new Set<Id>();
        List<Opportunity> closedWonOpportunities = new List<Opportunity>();
        for(Opportunity opp : newRecords){
            if(opp.Invoice_Due_Date_Override__c  != oldMap.get(opp.Id).Invoice_Due_Date_Override__c){
                CreateUpdateInvoiceFuture(opp.Id);          
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
    private static void CreateUpdateInvoiceFuture(String oppId){
        CreateUpdateQBInvoiceByUser.CreateUpdateInvoice(oppId);
    }
}