public class L4GController {
    @AuraEnabled(cacheable=true)
	public static List<FieldWrapper> getFieldSet(String fieldSetName, String objectName) {
        List<FieldWrapper> lstfieldWrapper = new List<FieldWrapper>();
        if (String.isNotBlank(fieldSetName) && String.isNotBlank(ObjectName)) {
            Schema.DescribeSObjectResult describeSObjectResult = Schema.getGlobalDescribe().get(ObjectName).getDescribe();
            Map<String,Schema.SObjectField> objFieldMap = describeSObjectResult.fields.getMap();
            Schema.FieldSet fieldSetObj = describeSObjectResult.FieldSets.getMap().get(fieldSetName);
            if (fieldSetObj != null) {
                for(Schema.FieldSetMember fieldSet : fieldSetObj.getFields() ) {
                    String fieldApiName = fieldSet.getFieldPath();
                    Schema.DescribeFieldResult fieldResult = objFieldMap.get(fieldApiName).getDescribe();
                    Boolean isReference = false;
                    String referencedObjName;
                    if (fieldResult.getType() == Schema.DisplayType.Reference) {
                        isReference = true;
                        referencedObjName =  fieldResult.getReferenceTo().get(0).getDescribe().getName();
                    }
                    lstfieldWrapper.add( new FieldWrapper(
                        String.ValueOf(fieldSet.getLabel()),
                        String.ValueOf(fieldSet.getFieldPath()), 
                        (fieldSet.getDBRequired() || fieldSet.getRequired()),
                        isReference,
                        referencedObjName
                    ));
                }
            }
        }
        return lstfieldWrapper; 
    }
    public class FieldWrapper {
        @AuraEnabled public String fieldName {get;set;}
        @AuraEnabled public String fieldLabel {get;set;}
        @AuraEnabled public Boolean isRequired {get;set;}
        @AuraEnabled public Boolean isReference {get;set;}
        @AuraEnabled public String referencedObjectName {get;set;}
        public FieldWrapper(String fieldLabel,String fieldName,Boolean isRequired, Boolean isReference, String referencedObjectName) {
            this.fieldLabel  = fieldLabel;
            this.fieldName   = fieldName;
            this.isRequired  = isRequired;
            this.isReference = isReference;
            this.referencedObjectName = referencedObjectName;
        }
    }
    @AuraEnabled(cacheable=true)
    public static list<sObject> fetchLookupData(string searchKey , string sObjectApiName) {    
        List < sObject > returnList = new List < sObject > ();
        string sWildCardText = '%' + searchKey + '%';
        string sQuery = 'Select Id,Name From ' + sObjectApiName + ' Where Name Like : sWildCardText order by createdDate DESC LIMIT 5';
        for (sObject obj: database.query(sQuery)) {
            returnList.add(obj);
        }
        return returnList;
    }
     @AuraEnabled
    public static Id getAccountId(String domain) {
        List<Account> acc= [Select Id from Account where Name = :domain];
        if(acc.size()>0){
            return acc[0].Id;
        }
        return null;
    }
    @AuraEnabled
    public static Map<String,String> checkIfContactExists(List<String> emailIds) {
        Map<String,String> conEmailToIds = new Map<String,String>();
        List<Contact> contacts= [Select Id, Email from Contact where Email = :emailIds];
        if(contacts.size()>0){
            for(Contact con:contacts){
                conEmailToIds.put(con.Email,con.Id);
            }
            return conEmailToIds;
        }
        return null;
    }
    // Method to fetch lookup default value 
    @AuraEnabled
    public static sObject fetchDefaultRecord(string recordId , string sObjectApiName) {
        string sRecId = recordId;    
        string sQuery = 'Select Id,Name From ' + sObjectApiName + ' Where Id = : sRecId LIMIT 1';
        for (sObject obj: database.query(sQuery)) {
            return obj;
        }
        return null;
    }
    @AuraEnabled
    public static Id cloneRecord(Id recordId) {
        Opportunity originalRecord = [SELECT Id, Name, Amount, ContactId, StageName, CloseDate FROM Opportunity WHERE Id = :recordId LIMIT 1];
        Opportunity clonedRecord = originalRecord.clone(false, true, false, false);
        insert clonedRecord;
        return clonedRecord.Id;
    }
    @AuraEnabled(cacheable=true)
	public static List<String> getFieldsToView(String fieldSetName, String objectName) {
    List<String> fields = new List<String>();
        if (String.isNotBlank(fieldSetName) && String.isNotBlank(ObjectName)) {
            Schema.DescribeSObjectResult describeSObjectResult = Schema.getGlobalDescribe().get(ObjectName).getDescribe();
            Map<String,Schema.SObjectField> objFieldMap = describeSObjectResult.fields.getMap();
            Schema.FieldSet fieldSetObj = describeSObjectResult.FieldSets.getMap().get(fieldSetName);
            if (fieldSetObj != null) {
                for(Schema.FieldSetMember fieldSet : fieldSetObj.getFields() ) {
                    String fieldApiName = fieldSet.getFieldPath();
                    fields.add(fieldApiName);
                }
            }
        }
        return fields; 
    }
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getRelatedOpportunities(Id contactId){
        return [SELECT Id, Name, Amount, StageName, CloseDate FROM Opportunity WHERE ContactId = :contactId];
    }
}