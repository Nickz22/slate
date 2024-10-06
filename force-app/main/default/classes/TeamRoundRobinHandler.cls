//////////////////////////////////////////////////
//Code by: Smeet Pari
//Description: Used in round-robin email service to read incoming email responses to availability emails that were sent to account team members
//Test Class: RoundRobinTest
/////////////////////////////////////////////////

global class TeamRoundRobinHandler implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope env)
    {
        Messaging.InboundEmailResult res = new Messaging.InboundEmailResult();
        
        String opp = email.subject.substringAfter('Slate Studios: ');
        System.debug(opp);
        String[] subject = opp.split('\\|');
        System.debug(subject);
        String[] emailBody = email.plainTextBody.split('\n');
        Confirmed_Member__c conf;
        
        try
        {
            
            System.debug(subject[2]);
            if(subject[2].trim().containsIgnoreCase('Availability'))
            {
                conf = [SELECT Id, Quote__c, Quote__r.SBQQ__Opportunity2__c,
                        Quote__r.SBQQ__Opportunity2__r.Lead_Producer__c,
                        Quote__r.SBQQ__Opportunity2__r.Lead_Producer_Email__c,
                        Quote__r.SBQQ__Opportunity2__r.Name,
                        Quote__r.SBQQ__Account__r.Name,
                        Quote__r.Days_on_Project__c,
                        Status__c,
                        Start_Date__c,
                        End_Date__c,
                        Email_Response__c,
                        Service_Type__c,
                        Account_Team_Member__r.Service_Type__c, Account_Team_Member__r.Email__c,
                        Account_Team_Member__r.Team_Member__r.FirstName
                        FROM Confirmed_Member__c 
                        WHERE Quote__r.SBQQ__Opportunity2__r.Name =: subject[0].trim() 
                        AND Account_Team_Member__r.Team_Member__r.Email =: email.fromAddress AND Status__c = 'Email Sent' LIMIT 1];
                
                System.debug(conf);
                System.debug(emailBody[0]);
                if(emailBody[0].containsIgnoreCase('Yes'))
                {
                    conf.Status__c = 'Available';
                }
                else if(emailBody[0].containsIgnoreCase('No'))
                {
                    conf.Status__c = 'Rejected';
                    
                    List<Confirmed_Member__c> nextInLine = [SELECT Id FROM Confirmed_Member__c WHERE Status__c = 'Queued' AND Account_Team_Member__r.Service_Type__c =: conf.Account_Team_Member__r.Service_Type__c ORDER BY Account_Team_Member__r.Times_Hired__c];
                    
                    if(!nextInLine.isEmpty())
                    	TeamRoundRobinController.sendNext(nextInLine[0].Id);
                    else
                        notifyProducer(conf);
                }
                else
                {
                    conf.Status__c = 'Manual Review';
                }
                
                conf.Email_Response__c = emailBody[0];
                update conf;
            }
            else if(subject[2].trim().equalsIgnoreCase('Re-Schedule Request'))
            {
                conf = [SELECT Id, Quote__c, Quote__r.SBQQ__Opportunity2__c,
                        Quote__r.SBQQ__Opportunity2__r.Lead_Producer__c,
                        Quote__r.SBQQ__Opportunity2__r.Lead_Producer_Email__c,
                        Quote__r.SBQQ__Opportunity2__r.Name,
                        Quote__r.SBQQ__Account__r.Name,
                        Quote__r.Days_on_Project__c,
                        Status__c,
                        Start_Date__c,
                        End_Date__c,
                        Email_Response__c,
                        Service_Type__c,
                        Account_Team_Member__r.Service_Type__c, Account_Team_Member__r.Email__c,
                        Account_Team_Member__r.Team_Member__r.FirstName
                        FROM Confirmed_Member__c 
                        WHERE Quote__r.SBQQ__Opportunity2__r.Name =: subject[0].trim() 
                        AND Account_Team_Member__r.Team_Member__r.Email =: email.fromAddress AND Status__c = 'Re-Schedule Email Sent' LIMIT 1];
                
                System.debug(conf);
                System.debug(emailBody[0]);
                if(emailBody[0].containsIgnoreCase('Yes'))
                {
                    conf.Status__c = 'Confirmed';
                }
                else if(emailBody[0].containsIgnoreCase('No'))
                {
                    conf.Status__c = 'Re-Schedule Rejected';
                    
                    List<Call_Sheet_Prospect__c> csm = [SELECT Id FROM Call_Sheet_Prospect__c WHERE Confirmed_Member__c =: conf.Id];
                    delete csm;
                    
                    List<Confirmed_Member__c> nextInLine = [SELECT Id, Start_Date__c, End_Date__c FROM Confirmed_Member__c WHERE Status__c = 'Queued' AND Account_Team_Member__r.Service_Type__c =: conf.Account_Team_Member__r.Service_Type__c ORDER BY Account_Team_Member__r.Times_Hired__c];
                    
                    if(!nextInLine.isEmpty())
                    {
                        nextInLine[0].Start_Date__c = conf.Start_Date__c;
                        nextInLine[0].End_Date__c = conf.End_Date__c;
                        update nextInLine[0];
                        TeamRoundRobinController.sendNext(nextInLine[0].Id);
                    }
                    else
                        notifyProducer(conf);
                }
                else
                {
                    conf.Status__c = 'Manual Review';
                }
                
                conf.Email_Response__c = emailBody[0];
                update conf;
            }
            
            res.success = true;
			
            if(conf.Status__c.equalsIgnoreCase('Available'))
                sendThankYou(conf);
        }catch(exception e)
        {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
            res.success = false;
            res.message = 'There was an issue processing the response. Please contact ' + conf.Quote__r.SBQQ__Opportunity2__r.Lead_Producer__c + ' at ' + conf.Quote__r.SBQQ__Opportunity2__r.Lead_Producer_Email__c ;
        }
        
        return res;
    }
    
    global void notifyProducer(Confirmed_Member__c conf)
    {
        Messaging.SingleEmailMessage nomore = new Messaging.SingleEmailMessage();
        nomore.setToAddresses(new List<String>{conf.Quote__r.SBQQ__Opportunity2__r.Lead_Producer_Email__c});
        nomore.setSubject('Round-Robin: ' + conf.Quote__r.SBQQ__Opportunity2__r.Name + ' | ' + conf.Service_Type__c + ' | ' + 'End Of List');
            
        String HTMLBody = 'Hi ' + conf.Quote__r.SBQQ__Opportunity2__r.Lead_Producer__c + ', <br><br>';
        HTMLBody += 'Round-Robin has reached the end of the list for ' + conf.Service_Type__c + '. Please add more to Account Team Member for the same service type to the account.';
        
        nomore.setHtmlBody(HTMLBody);
        
        if(![SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox)
        	nomore.setCcAddresses(new List<String>{'info@slate-nyc.com'});
        
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.Email>{nomore});
    }
    
    global void sendThankYou(Confirmed_Member__c confMbmr)
    {
        Messaging.SingleEmailMessage thankyou = new Messaging.SingleEmailMessage();
        
        String emailBody = 'Hi ' + confMbmr.Account_Team_Member__r.Team_Member__r.FirstName + ',<br><br>';
        
        emailBody += 'Thank you for your response. We have marked you as Available for the below date(s).<br><br>';
        
        emailBody += '<ul>';
        emailBody += '<li>Start Shoot Date: ' + Datetime.newInstance(confMbmr.Start_Date__c.year(),confMbmr.Start_Date__c.month(),confMbmr.Start_Date__c.day()).format('MM/dd/YYYY') + '</li><br>';
        emailBody += '<li>End Shoot Date: ' + Datetime.newInstance(confMbmr.End_Date__c.year(),confMbmr.End_Date__c.month(),confMbmr.End_Date__c.day()).format('MM/dd/YYYY') + '</li><br>';
        emailBody += '<li># Days: ' + confMbmr.Quote__r.Days_on_Project__c + '</li><br>';
        
        emailBody += '</ul><br>Please let us know if there are any changes to your schedule.<br><br>';
        
        //Start Signature//
        emailBody += 'Best,<br>' + confMbmr.Quote__r.SBQQ__Opportunity2__r.Lead_Producer__c ;
        emailBody += '<br><br>';
        emailBody += '<img src="'+Label.Slate_Logo+'" width="96" height="25"><br><br>';
        emailBody += 'Slate Studios<br>5102 21ST ST., 4TH FL<br>LONG ISLAND CITY, NY 11101<br>212 390 0243<br><a href="slate-nyc.com">slate-nyc.com</a><br><a href="https://www.instagram.com/slate__studios/?hl=en">@slate_studios</a><br><br>';
        emailBody += '<span style="font-size:9px">This message (including any attachment) is for the intended recipient and may contain material that is confidential or subject to copyright. If you are not the intended recipient then the dissemination, copying, or distribution of this message (including any attachments) is strictly prohibited. If you have received this message in error, please notify us by replying to this email and deleting it from your computer. Any views or opinion are those the sender and do not necessarily represent those of the company.</span>';
        
        thankyou.setSubject('Slate Studios: ' + confMbmr.Quote__r.SBQQ__Opportunity2__r.Name + ' | ' + 'Availablity Received');
        thankyou.setHtmlBody(emailBody);
        thankyou.setBccAddresses(new List<String>{confMbmr.Quote__r.SBQQ__Opportunity2__r.Lead_Producer_Email__c});
        thankyou.setToAddresses(new List<String>{confMbmr.Account_Team_Member__r.Email__c});
        
        Id owaId = getOrgWideEmail(confMbmr.Quote__r.SBQQ__Opportunity2__r.Lead_Producer_Email__c);
        
        if(owaId != null)
            thankyou.setOrgWideEmailAddressId(owaId);
        
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.Email>{thankyou});
    }
    
    global Id getOrgWideEmail(String email)
    {
        try
        {
            OrgWideEmailAddress owa = [SELECT Id FROM OrgWideEmailAddress WHERE Address =: email LIMIT 1];
            
            return owa.Id;
        }catch(Exception e){
            return null;
        }
    }
}