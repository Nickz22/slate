public class LeadConvertController {
    private static Lead toConvert;
    private static Map<String, String> palermoServiceType;
    private static Map<String, String> alignServiceType;
    private static Map<String, String> slateServiceType;
    
    public static void convertLeads(Id leadId)
    {
        List<Lead> qryRslt = (List<Lead>)Database.query(createQuery());
       	toConvert = qryRslt[0];
        
        Opportunity opp = createOpportunity();
        
        List<Account> existingAccs = [SELECT Id, Name FROM Account WHERE Name =: toConvert.company LIMIT 1];
        List<Contact> existingCon = [SELECT Id, Name, Email, AccountId FROM Contact WHERE Email =: toConvert.email LIMIT 1];
        
        Savepoint tisGood = Database.setSavepoint();
        
        try{
            Id existingAcc;
        	Database.LeadConvert lc = new Database.LeadConvert();
        	lc.setLeadId(toConvert.Id);
        	lc.setDoNotCreateOpportunity(true);
            
            if(!existingAccs.isEmpty())
            {
                existingAcc = existingAccs[0].Id;
                lc.setAccountId(existingAcc);
            }
            
            if(!existingCon.isEmpty() && existingAcc != null)
            {
                if(existingCon[0].AccountId == existingAcc)
                	lc.setContactId(existingCon[0].Id);
            }
            
            LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
			lc.setConvertedStatus(convertStatus.MasterLabel);
            
            Database.LeadConvertResult lcr = Database.convertLead(lc);

            if(!lcr.isSuccess())
            	throw new leadConvertException(lcr.getErrors()[0].getMessage());
			else
            {
                opp.AccountId = lcr.getAccountId();
                opp.PrimaryContact__c = lcr.getContactId();
                insert opp;
            }
        }catch(Exception e){
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
            Database.rollback(tisGood);
        }
        
    }
    
    private static Opportunity createOpportunity()
    {
        createServiceTypeMapping();
        
        Opportunity opp = new Opportunity();
        opp.Name = toConvert.Company;
        opp.Project_Budget__c =  toConvert.Project_Budget__c;
        opp.Service_of_Interest__c = toConvert.Service_of_Interest__c;
        opp.Services_of_Interest__c = toConvert.Services_of_Interest__c;
        opp.Additional_Info__c = toConvert.Project_Brief__c;
        opp.Project_Start_Date__c = toConvert.Project_Start_Date__c;
        opp.Project_Deadline__c = toConvert.Project_Deadline__c;
        opp.Project_Budget__c = toConvert.Project_Budget__c;
        opp.CloseDate = toConvert.Project_Start_Date__c != null ? toConvert.Project_Start_Date__c.addMonths(1).toStartofMonth().addDays(-1) : System.today().addMonths(1).toStartofMonth().addDays(-1);
        opp.Image_Count__c = toConvert.Image_Count__c;
        opp.Images_Monthly__c = toConvert.Image_Count_Monthly__c;
        opp.Before_After_Link__c = toConvert.Before_After_Link__c;
        opp.Post_Production_Method__c = toConvert.Post_Production_Method__c;
        Opp.Pain_Points__c = toConvert.Pain_Points__c;
        opp.LeadSource = String.isNotEmpty(toConvert.LeadSource) && toConvert.LeadSource.containsIgnoreCase('Mailing List') ? 'Email - Newsletter' : toConvert.LeadSource;
        opp.StageName = (!String.isBlank(toConvert.Services_of_Interest__c) && toConvert.Services_of_Interest__c.containsIgnoreCase('General Inquiry')) ? 'Qualification - General Inquiry' : 'Qualification - Specific Project';
        opp.Lead_Type__c = getLeadType(opp.Service_of_Interest__c);
        
        if(toConvert.Inquiry_For__c == 'Palermo')
        	opp.Opportunity_Descriptor__c = 'Palermo - ' + opp.Service_of_Interest__c;
        if(toConvert.Inquiry_For__c == 'Align')
        {
            if(opp.Image_Count__c != null)
                opp.Opportunity_Descriptor__c = 'Align - ' + String.valueOf((Integer)opp.Image_Count__c) + 'x Images - TBD';
            else
                opp.Opportunity_Descriptor__c = 'Align - TBD';
        }
        if(toConvert.Inquiry_For__c == 'Slate')
            opp.Opportunity_Descriptor__c = 'Slate - ' + opp.Service_of_Interest__c;
        
        
        
        return opp;
    }
    
    private static String createQuery()
    {
        String query = 'SELECT Id, ';
        
        List<Schema.FieldSetMember> flds = SObjectType.Lead.FieldSets.Typeform_Lead_Convert.getFields();
        
        for(Schema.FieldSetMember fld:flds)
        {
            query += fld.getFieldPath() + ', ';
        }
        
        query = query.removeEnd(', ');
        query += ' FROM Lead WHERE Id =: leadId';
		system.debug(query);        
        return query;
    }
    
    private static String getLeadType(String selectedService)
    {
        //Start Service Type logic
        String LeadType;
        
        if(toConvert.Inquiry_For__c == 'Palermo')
            LeadType = palermoServiceType.get(selectedService);
        else if(toConvert.Inquiry_For__c == 'Align')
            LeadType = alignServiceType.get(selectedService);
        else if(toConvert.Inquiry_For__c == 'Slate')
            LeadType = slateServiceType.get(selectedService);
        
        return LeadType;
    }
    
    private static void createServiceTypeMapping()
    {
        palermoServiceType = new Map<String,String>();
        palermoServiceType.put('Art Direction & Strategy','Palermo - Branding');
        palermoServiceType.put('Branding & Identity','Palermo - Video Production');
        palermoServiceType.put('Content Production','Palermo - E-Commerce Content Production');
        palermoServiceType.put('Digital/UX','Palermo - Digital/UX');
        palermoServiceType.put('CGI','Palermo - CGI');
        
        alignServiceType = new Map<String,String>();
        alignServiceType.put('CGI','Align - CGI');
        alignServiceType.put('Retouching','Retouching - Align');
        alignServiceType.put('Video Editing','Align - Video Editing');
        alignServiceType.put('VFX/Animation','Align - VFX/Animation');
        
        slateServiceType = new Map<String,String>();
        slateServiceType.put('Brand Content Production','Brand Content');
        slateServiceType.put('CGI Content Production', 'Slate - CGI');
        slateServiceType.put('E-Commerce Content Production', 'E-Commerce');
        slateServiceType.put('Motion Content Production', 'Motion');
        slateServiceType.put('Retouching', 'Retouching');
        slateServiceType.put('Studio & Equipment Rental', 'Studio Rental');
    }
    
    public class leadConvertException extends Exception{}
}