//////////////////////////////////////////////////
//Code by: Smeet Pari
//Description: Sends out confirmed emails to all account team members that have responded that they are available for the shoot.
//Test Class: RoundRobinTest
/////////////////////////////////////////////////

public class TeamRoundRobinConfirmations {
    
    private static Map<String, List<Messaging.EmailFileAttachment>> attach;
    
	@InvocableMethod(label='Send Confirmation Emails' description='Send confirmation emails to all "Available" confirmed members for a quote.')
    public static void sendConfirmation(List<String> quoteId)
    {
        try
        {
            List<Confirmed_Member__c> sendConfirm = [SELECT Id, Quote__r.SBQQ__Account__r.Name,
                                                     Quote__c, Quote__r.Days_on_Project__c, Quote__r.SBQQ__Opportunity2__r.Name,
                                                     Quote__r.SBQQ__Opportunity2__c, Quote__r.SBQQ__Opportunity2__r.Lead_Producer__c,
                                                     Quote__r.SBQQ__Opportunity2__r.Lead_Producer_Email__c, Quote__r.SBQQ__Opportunity2__r.Lead_Type__c,
                                                     Quote__r.SBQQ__Opportunity2__r.Account.Production_Guidelines_1__c,Status__c, 
                                                     Account_Team_Member__r.Team_Member__r.Email, Account_Team_Member__r.Service_Type__c,
                                                     Account_Team_Member__r.Team_Member__r.Name, Account_Team_Member__r.Team_Member__r.FirstName, Start_Date__c, End_Date__c, Confirmed_Rate__c
                                                     FROM Confirmed_Member__c WHERE Quote__c =: quoteId[0] AND Status__c = 'Available'];
            
            getEmailAttachments(sendConfirm[0].Quote__r.SBQQ__Opportunity2__c);
            
            List<CallSheet__c> callSheets = [SELECT Id FROM CallSheet__c WHERE Opportunity__c =: sendConfirm[0].Quote__r.SBQQ__Opportunity2__c];
            
            if(callSheets.isEmpty())
            {
                CallSheet__c callSheet = new CallSheet__c();
                callSheet.Name = sendConfirm[0].Quote__r.SBQQ__Opportunity2__r.Name;
                callSheet.Opportunity__c = sendConfirm[0].Quote__r.SBQQ__Opportunity2__c;
                insert callSheet;
                
                callSheets.add(callSheet);
            }
            
            List<Messaging.SingleEmailMessage> toSend = new List<Messaging.SingleEmailMessage>();
            List<Call_Sheet_Prospect__c> callSheetMbmrs = new List<Call_Sheet_Prospect__c>();
            
            for(Confirmed_Member__c conf:sendConfirm)
            {
                Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
                msg.setToAddresses(new List<String>{conf.Account_Team_Member__r.Team_Member__r.Email});
                msg.setCcAddresses(new List<String>{conf.Quote__r.SBQQ__Opportunity2__r.Lead_Producer_Email__c});
                msg.setSubject('Slate Studios: ' + conf.Quote__r.SBQQ__Opportunity2__r.Name + ' | ' + conf.Account_Team_Member__r.Service_Type__c + ' | ' + 'Confirmation');
                msg.setReplyTo(conf.Quote__r.SBQQ__Opportunity2__r.Lead_Producer_Email__c);
                msg.setHtmlBody(createConfirmationEmail(conf));
                
                //Set Attachments
                List<Messaging.EmailFileAttachment> toAttach = new List<Messaging.EmailFileAttachment>();
                
                if(attach.containsKey('All'))
                    toAttach.addAll(attach.get('All'));
                if(attach.containsKey(conf.Account_Team_Member__r.Service_Type__c))
                    toAttach.addAll(attach.get(conf.Account_Team_Member__r.Service_Type__c));
                
                msg.setFileAttachments(toAttach);
                
                toSend.add(msg);
                
                conf.Status__c = 'Confirmed';

                Call_Sheet_Prospect__c callMbmr = new Call_Sheet_Prospect__c();
                callMbmr.Contact__c = conf.Account_Team_Member__r.Team_Member__c;
                callMbmr.Confirmed_Member__c = conf.Id;
                callMbmr.Call_Sheet__c = callSheets[0].Id;
                callSheetMbmrs.add(callMbmr);  
            }
            
            if(!toSend.isEmpty())
                Messaging.SendEmailResult[] results = Messaging.sendEmail(toSend);
            
            update sendConfirm;
            insert callSheetMbmrs;
        }Catch(Exception e)
        {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
    }
    
    private static String createConfirmationEmail(Confirmed_Member__c teamMbmr)
    {
        String emailBody = 'Hi ' + teamMbmr.Account_Team_Member__r.Team_Member__r.FirstName + ',<br><br>';
        
        emailBody += 'Please note that you have been confirmed for the following project.<br><br>';
        
        emailBody += '<ul>';
        emailBody += '<li>Client: ' + teamMbmr.Quote__r.SBQQ__Account__r.Name + '</li><br>';
        emailBody += '<li>Job Type: ' + teamMbmr.Quote__r.SBQQ__Opportunity2__r.Lead_Type__c + '</li><br>';
        emailBody += '<li>Rate: $' + teamMbmr.Confirmed_Rate__c + '</li><br>';
        emailBody += '<li>Start Shoot Date: ' + Datetime.newInstance(teamMbmr.Start_Date__c.year(),teamMbmr.Start_Date__c.month(),teamMbmr.Start_Date__c.day()).format('MM/dd/YYYY') + '</li><br>';
        emailBody += '<li>End Shoot Date: ' + Datetime.newInstance(teamMbmr.End_Date__c.year(),teamMbmr.End_Date__c.month(),teamMbmr.End_Date__c.day()).format('MM/dd/YYYY') + '</li><br>';
        emailBody += '<li># Days: ' + teamMbmr.Quote__r.Days_on_Project__c + '</li><br>';
        
        if(!String.isBlank(teamMbmr.Quote__r.SBQQ__Opportunity2__r.Account.Production_Guidelines_1__c))
        {
            string prodGuide = teamMbmr.Quote__r.SBQQ__Opportunity2__r.Account.Production_Guidelines_1__c.removeStart('<p>');
            prodGuide = prodGuide.remove('</p>');
            
            emailBody += '<li>' + prodGuide + '</li><br>';
        }
        
        emailBody += '</ul><br>If you would like further information and/or have other hold(s), please let us know.<br><br>';
        emailBody += 'Please note that this is a confirmation. You will receive a call sheet email prior to project start date.<br><br>';
        emailBody += 'Best,<br>' + teamMbmr.Quote__r.SBQQ__Opportunity2__r.Lead_Producer__c ;
        
        //Start Signature//
        emailBody += '<br><br>';
        emailBody += '<img src="'+Label.Slate_Logo+'" width="96" height="25"><br><br>';
        emailBody += 'Slate Studios<br>5102 21ST ST., 4TH FL<br>LONG ISLAND CITY, NY 11101<br>212 390 0243<br><a href="slate-nyc.com">slate-nyc.com</a><br><a href="https://www.instagram.com/slate__studios/?hl=en">@slate_studios</a><br><br>';
        emailBody += '<span style="font-size:9px">This message (including any attachment) is for the intended recipient and may contain material that is confidential or subject to copyright. If you are not the intended recipient then the dissemination, copying, or distribution of this message (including any attachments) is strictly prohibited. If you have received this message in error, please notify us by replying to this email and deleting it from your computer. Any views or opinion are those the sender and do not necessarily represent those of the company.</span>';
        
        
        return emailBody;
    }
    
    private static void getEmailAttachments(Id oppId)
    {
        Map<Id, Project_Files__c> prjFiles = new Map<Id,Project_Files__c>([SELECT Id, Service_Type__c FROM Project_Files__c WHERE RecordType.Name = 'Shared' AND Opportunity__c =: oppId]);
        
        if(!prjFiles.keySet().isEmpty())
        {
            List<ContentDocumentLink> docs = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :prjFiles.keySet()];
            
            Map<Id,Id> docLinks = new Map<Id,Id>();
            
            for(ContentDocumentLink link:docs)
            {
                docLinks.put(link.ContentDocumentId,link.LinkedEntityId);
            }
            
            List<ContentVersion> files = [SELECT ContentDocumentId, Title, FileType,VersionData FROM ContentVersion WHERE ContentDocumentId IN: docLinks.keySet()];
            
            attach = new Map<String, List<Messaging.EmailFileAttachment>>();
            
            for(ContentVersion file:files)
            {
                //get project file object Id this file is related to in order to figure out what service type this file needs to be attached for
                Id prjFileId = docLinks.get(file.ContentDocumentId);
                String serviceType = prjFiles.get(prjFileId).Service_Type__c;
                
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                
                if(attach.containsKey(serviceType))
                {
                    efa.setFileName(file.Title+'.'+file.FileType);
                    efa.setBody(file.VersionData);
                    attach.get(serviceType).add(efa);
                }
                else
                {
                    List<Messaging.EmailFileAttachment> srvFiles = new List<Messaging.EmailFileAttachment>();
                    efa.setFileName(file.Title+'.'+file.FileType);
                    efa.setBody(file.VersionData);
                    srvFiles.add(efa);
                    
                    attach.put(serviceType,srvFiles);
                }
            }
        }
    }
}