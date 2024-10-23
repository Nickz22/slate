public class OpportunityTriggerHandler {
  public static Boolean ToCreateCalendarRecord = true;
  public static Boolean ToDeleteCalendarRecordOnHoldRecords = true;
  public static Map<Id, Account> accounts = new Map<Id, Account>();

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
    AutoQuoteGeneration.autoQuote(newMap.values()[0].Id);
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
}