public with sharing class CallsheetMappingSelector {
    
    public CallsheetMappingSelector() {
  }

  public List<Callsheet_Section_Mapping__mdt> selectAllMappings() {
      return [
          SELECT Id, Callsheet_Section_Header__r.Label, Value__c, Field_Name__c, Operator__c 
          FROM Callsheet_Section_Mapping__mdt
      ];
  }

}