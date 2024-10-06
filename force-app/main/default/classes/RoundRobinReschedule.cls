public class RoundRobinReschedule {
    
    private static String replyToEmail = Round_Robin_Email__c.getOrgDefaults().Response_Email__c;
    public static Map<Id,Opportunity> reschedule;
    public static Map<Id,SBQQ__Quote__c> quotes;
    public static Map<Id,Id> confQuotesToOpp;
    public static List<Confirmed_Member__c> sendReschedMbmrs;
    
    @Future
    public static void dateChange(Set<Id> changedOpps)
    {
        try{
            reschedule = new Map<Id, Opportunity>([SELECT Id, Name, Continuous__c, Lead_Producer__c, Lead_Producer_Email__c, Shoot_Date__c, Shoot_Date_2__c, Days__c, (SELECT Id, Days_On_Project__c FROM SBQQ__Quotes2__r WHERE SBQQ__Primary__c = true) FROM Opportunity WHERE Id IN: changedOpps]);
            
            Set<Id> quoteIds = new Set<Id>();
            
            for(Opportunity opp:reschedule.values())
            {
                if(!opp.SBQQ__Quotes2__r.isEmpty())
                    quoteIds.add(opp.SBQQ__Quotes2__r[0].Id);
            }
            
            quotes = new Map<Id,SBQQ__Quote__c>([SELECT Id, Name, SBQQ__Opportunity2__c, (SELECT Id FROM Confirmed_Members__r WHERE Status__c = 'Confirmed') FROM SBQQ__Quote__c WHERE Id IN: quoteIds]);
            System.debug('Conf ' + quotes.values());
            //Map<OppId,QuoteId>
            confQuotesToOpp = new Map<Id,Id>();
            
            for(SBQQ__Quote__c quote:quotes.values())
            {
                if(!quote.Confirmed_Members__r.isEmpty())
                    confQuotesToOpp.put(quote.SBQQ__Opportunity2__c,quote.Id);
            }
            
            getConfirmedMembers();
            sendRescheduleEmails();
        }catch(Exception e)
        {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
    }
    
    public static void getConfirmedMembers()
    {
        Set<Id> confMbmrs = new Set<Id>();
        
        for(Id oppId:confQuotesToOpp.keySet())
        {
            SBQQ__Quote__c q = quotes.get(confQuotesToOpp.get(oppId));
            
            for(Confirmed_Member__c cm:q.Confirmed_Members__r)
            {
                confMbmrs.add(cm.Id);
            }
        }
        
        sendReschedMbmrs = [SELECT Id, Name, Service_Type__c, Start_Date__c, End_Date__c, Status__c, Confirmed_Rate__c,
                           Account_Team_Member__r.Team_Member__r.FirstName, Account_Team_Member__r.Email__c,
                           Quote__r.SBQQ__Opportunity2__c, Quote__c,
                           Quote__r.SBQQ__Opportunity2__r.Lead_Producer_Email__c,
                           Quote__r.SBQQ__Opportunity2__r.Lead_Producer__c,
                           Quote__r.Days_on_Project__c,
                           Quote__r.SBQQ__Opportunity2__r.Name,
                           Quote__r.SBQQ__Account__r.Name,
                           Quote__r.SBQQ__Opportunity2__r.Lead_Type__c
                           FROM Confirmed_Member__c WHERE Id IN: confMbmrs];
        
        updateConfMbmrsDates();
    }
    
    public static void updateConfMbmrsDates()
    {
        for(Confirmed_Member__c cf:sendReschedMbmrs)
        {
            cf.Start_Date__c = reschedule.get(cf.Quote__r.SBQQ__Opportunity2__c).Shoot_Date__c;
            cf.End_Date__c = reschedule.get(cf.Quote__r.SBQQ__Opportunity2__c).Shoot_Date_2__c;
            cf.Status__c = 'Re-Schedule Email Sent';
        }
    }
    
    public static void sendRescheduleEmails()
    {
        List<Messaging.SingleEmailMessage> reschedEmails = new List<Messaging.SingleEmailMessage>();
        
        for(Confirmed_Member__c cm:sendReschedMbmrs)
        {
            reschedEmails.add(createEmail(cm));
        }
        
        update sendReschedMbmrs;
        
        if(!reschedEmails.isEmpty())
            Messaging.SendEmailResult[] results = Messaging.sendEmail(reschedEmails);
    }
    
    
    public static Messaging.SingleEmailMessage createEmail(Confirmed_Member__c confMbmr)
    {   
        Messaging.SingleEmailMessage resched = new Messaging.SingleEmailMessage();
        
        String emailBody = 'Hi ' + confMbmr.Account_Team_Member__r.Team_Member__r.FirstName + ',<br><br>';
        
        emailBody += 'The shoot you had previously confirmed for has been rescheduled.<br><br>';
        
        emailBody += '<ul>';
        emailBody += '<li>Client: ' + confMbmr.Quote__r.SBQQ__Account__r.Name + '</li><br>';
        emailBody += '<li>Job Type: ' + confMbmr.Quote__r.SBQQ__Opportunity2__r.Lead_Type__c + '</li><br>';
        emailBody += '<li>Rate: $' + confMbmr.Confirmed_Rate__c + '</li><br>';
        emailBody += '<li>Start Shoot Date: ' + Datetime.newInstance(confMbmr.Start_Date__c.year(),confMbmr.Start_Date__c.month(),confMbmr.Start_Date__c.day()).format('MM/dd/YYYY') + '</li><br>';
        emailBody += '<li>End Shoot Date: ' + Datetime.newInstance(confMbmr.End_Date__c.year(),confMbmr.End_Date__c.month(),confMbmr.End_Date__c.day()).format('MM/dd/YYYY') + '</li><br>';
        emailBody += '<li># Days: ' + confMbmr.Quote__r.Days_on_Project__c + '</li><br>';
        
        emailBody += '</ul><br>If available, please respond "Yes".<br>';
        emailBody += 'If not available, please respond "No"<br><br>';
        
        //Start Signature//
        emailBody += 'Best,<br>' + confMbmr.Quote__r.SBQQ__Opportunity2__r.Lead_Producer__c ;
        emailBody += '<br><br>';
        emailBody += '<img src="'+Label.Slate_Logo+'" width="96" height="25"><br><br>';
        emailBody += 'Slate Studios<br>5102 21ST ST., 4TH FL<br>LONG ISLAND CITY, NY 11101<br>212 390 0243<br><a href="slate-nyc.com">slate-nyc.com</a><br><a href="https://www.instagram.com/slate__studios/?hl=en">@slate_studios</a><br><br>';
        emailBody += '<span style="font-size:9px">This message (including any attachment) is for the intended recipient and may contain material that is confidential or subject to copyright. If you are not the intended recipient then the dissemination, copying, or distribution of this message (including any attachments) is strictly prohibited. If you have received this message in error, please notify us by replying to this email and deleting it from your computer. Any views or opinion are those the sender and do not necessarily represent those of the company.</span>';
        
        resched.setSubject('Slate Studios: ' + confMbmr.Quote__r.SBQQ__Opportunity2__r.Name + ' | ' + confMbmr.Service_Type__c + ' | ' + 'Re-Schedule Request');
        resched.setHtmlBody(emailBody);
        resched.setBccAddresses(new List<String>{confMbmr.Quote__r.SBQQ__Opportunity2__r.Lead_Producer_Email__c});
        resched.setToAddresses(new List<String>{confMbmr.Account_Team_Member__r.Email__c});
        resched.setReplyTo(replyToEmail);
        
        return resched;
    }
}