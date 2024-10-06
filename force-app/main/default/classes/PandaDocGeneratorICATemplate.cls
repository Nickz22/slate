public with sharing class PandaDocGeneratorICATemplate {
    public Static String apiKey = '89384b2c4a6656a6457776748557bde540ed2a71';

    @AuraEnabled
    public static PandadocTemplate getTemplateList() {
        Http h = new Http();

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.pandadoc.com/public/v1/templates');
        req.setMethod('GET');
        req.setHeader('Authorization', 'API-Key ' + apiKey);

        HttpResponse res = h.send(req);
        
        return PandadocTemplate.parse(res.getBody());
    }

    @AuraEnabled
    public static Pandadocs getDocumentList(String documentId) {
        Http h = new Http();

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.pandadoc.com/public/v1/documents?id=' +documentId );
        req.setMethod('GET');
        req.setHeader('Authorization', 'API-Key ' + apiKey);
        req.setHeader('id', documentId);

        HttpResponse res = h.send(req);
        
        return Pandadocs.parse(res.getBody());
    }

    @AuraEnabled
    public static String getContactName(String recordId) {
        return [SELECT Id, Name FROM Contact WHERE Id = :recordId].Name;
    }

    @AuraEnabled
    public static String getOpportunityName(String recordId) {
        return [SELECT Id, Opportunity_Name__c FROM CallSheet__c WHERE Id = :recordId].Opportunity_Name__c;
    }

    @AuraEnabled
    public static String createICAPandaDoc(String recordId) {
        String documentName = '';
        Contact contactRec = [SELECT Id, Name, FirstName, LastName, Email, Service_Type__c FROM Contact WHERE Id = :recordId];
        documentName = String.isNotBlank(documentName)? documentName: 'ICA - ' + contactRec.Name;
        
        String createDocumentJSON = '{"name":"' + documentName + '","template_uuid":"foFf9KenhCtzZFtboMxfJY","recipients":[{"email":"' + contactRec.Email + '","last_name":"' + contactRec.LastName + '","first_name":"' + contactRec.FirstName + '"}]}';

        List<Map<String, Object>> tokenFieldsData = new List<Map<String, Object>>();
        tokenFieldsData.add(new Map<String,Object>{'name' => 'Name', 'value' => contactRec.Name});
        tokenFieldsData.add(new Map<String,Object>{'name' => 'Service_Type__c', 'value' => contactRec.Service_Type__c});

        Map<String,Object> createDocumentData = (Map<String,Object>) JSON.deserializeUntyped(createDocumentJSON);
        createDocumentData.put('tokens', tokenFieldsData);

        String createdDocBody = JSON.serialize(createDocumentData);
        System.debug('createDocumentData:: ' + createdDocBody);

        Http h = new Http();

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.pandadoc.com/public/v1/documents');
        req.setMethod('POST');
        req.setHeader('Authorization', 'API-Key ' + apiKey);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(createdDocBody);

        HttpResponse res = h.send(req);
        
        if(res.getStatusCode() == 201){
            return (String)((Map<String,Object>) JSON.deserializeUntyped(res.getBody())).get('id');
        }
        else {
            return null;
        }
    }

    @AuraEnabled
    public static String createCallSheetDocument(String recordId) {
        String documentName = '';
        CallSheet__c callSheet = [SELECT Id, OwnerId, IsDeleted, Name, Opportunity__c, Opportunity_Name__c, 
            Account_Name__c, Shoot_Date__c, TextDate__c, Shoot_Date_Non_Text__c, Shoot_Dates_Start_End__c, 
            Opportunity_Lead_Type__c, Opportunity_Lead_Type_Uppercase__c FROM CallSheet__c WHERE Id = :recordId];

        documentName = String.isNotBlank(documentName)? documentName: 'ICA - ' + callSheet.Opportunity_Name__c;
        
        String createDocumentJSON = '{"name":"' + documentName + '","template_uuid":"aBiWr7WFnhYAYKFn3xfipV"}';

        List<Call_Sheet_Prospect__c> callSheetProspects = [SELECT Id, OwnerId, Name, Contact__c, Call_Sheet__c, 
        Name__c, Service__c, E_mail__c, Role__c, ContactID__c, Contact_Role__c, Lower_Emails__c, First_Name__c, 
        Last_Name__c, Confirmed_Member__c from Call_Sheet_Prospect__c WHERE Call_Sheet__c = :recordId];

        Map<String, Call_Sheet_Prospect__c> contactInfoMap = new Map<String, Call_Sheet_Prospect__c>();

        List<Map<String, Object>> tokenFieldsData = new List<Map<String, Object>>();
        tokenFieldsData.add(new Map<String,Object>{'name' => 'Job_name__c', 'value' => callSheet.Name});
        tokenFieldsData.add(new Map<String,Object>{'name' => 'Lead_Type__c', 'value' => callSheet.Opportunity_Lead_Type_Uppercase__c});
        tokenFieldsData.add(new Map<String,Object>{'name' => 'Shoot_Date_s__c', 'value' => callSheet.Shoot_Date__c == null? '': String.valueOf(callSheet.Shoot_Date__c)});
        tokenFieldsData.add(new Map<String,Object>{'name' => 'Client_Name__c', 'value' => callSheetProspects[0].Name__c});

        Map<String, Object> pricingTable1 = new Map<String, Object>();
        pricingTable1.put('name', 'Pricing Table 1');
        pricingTable1.put('data_merge', true);

        List<Object> pricingTable1SectionRows = new List<Object>();
        for (Call_Sheet_Prospect__c callSheetProspect : callSheetProspects) {
            contactInfoMap.put(callSheetProspect.E_mail__c, callSheetProspect);
            Map<String, Object> rowInfo = new Map<String, Object>();

            Map<String, Object> rowData = new Map<String, Object>();
            rowData.put('Role__c', callSheetProspect.Role__c);
            rowData.put('Name', callSheetProspect.Name);
            rowData.put('E_mail__c', callSheetProspect.E_mail__c);
            rowData.put('Name__c', callSheetProspect.Name__c);
            rowData.put('Service__c', callSheetProspect.Service__c);
            rowData.put('Price', 0);
            rowData.put('QTY', 1);

            Map<String, Object> optionsData = new Map<String, Object>();
            optionsData.put('optional', false);
            optionsData.put('optional_selected', false);
            optionsData.put('qty_editable', false);

            rowInfo.put('data', rowData);
            rowInfo.put('options', optionsData);
            pricingTable1SectionRows.add(rowInfo);
        }
        List<String> recipients = new List<String>();
        for (Call_Sheet_Prospect__c callSheetProspect : contactInfoMap.values()) {
            recipients.add('{"email":"' + callSheetProspect.E_mail__c + '","last_name":"' + callSheetProspect.Last_Name__c + '","first_name":"' + (String.isBlank(callSheetProspect.First_Name__c)? '': callSheetProspect.First_Name__c) + '"}');
        }
        Map<String, Object> pricingTable1Section = new Map<String, Object>();
        pricingTable1Section.put('title', 'Section');
        pricingTable1Section.put('default', true);
        pricingTable1Section.put('rows', pricingTable1SectionRows);
        pricingTable1.put('sections', new List<Object>{pricingTable1Section});


        Map<String,Object> createDocumentData = (Map<String,Object>) JSON.deserializeUntyped(createDocumentJSON);
        createDocumentData.put('recipients', (List<Object>) JSON.deserializeUntyped('[' + String.join(recipients, ',') + ']'));
        createDocumentData.put('tokens', tokenFieldsData);
        createDocumentData.put('pricing_tables', new List<Object>{pricingTable1});

        String createdDocBody = JSON.serialize(createDocumentData);
        System.debug('createDocumentData:: ' + createdDocBody);

        Http h = new Http();

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.pandadoc.com/public/v1/documents');
        req.setMethod('POST');
        req.setHeader('Authorization', 'API-Key ' + apiKey);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(createdDocBody);

        HttpResponse res = h.send(req);
        
        if(res.getStatusCode() == 201){
            return (String)((Map<String,Object>) JSON.deserializeUntyped(res.getBody())).get('id');
        }
        else {
            return null;
        }
    }

    @AuraEnabled
    public static Boolean sendDocument(String docId) {
        Http h = new Http();

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.pandadoc.com/public/v1/documents/' + docId + '/send');
        req.setMethod('POST');
        req.setHeader('Authorization', 'API-Key ' + apiKey);
        req.setBody('{ "message": "Hello! This document was sent from the PandaDoc API", "subject": "Please check this test API document from PandaDoc", "silent": true }');

        HttpResponse res = h.send(req);
        
        if(res.getStatusCode() == 200){
            return true;
        }
        else {
            return false;
        }
    }
}