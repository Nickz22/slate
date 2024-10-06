public class RoundRobinReminderSched implements Schedulable {
    
    private List<Confirmed_Member__c> mbmr;
    private String replyToEmail = Round_Robin_Email__c.getOrgDefaults().Response_Email__c;
    
    public RoundRobinReminderSched(Set<Id> confMbmr){
        mbmr = [SELECT Id, Service_Type__c, Confirmed_Rate__c, Start_Date__c, End_Date__c,
                Reminder_Email_Sent__c,
                Account_Team_Member__r.Team_Member__r.FirstName,
                Account_Team_Member__r.Email__c,
                Quote__r.Days_on_Project__c,
                Quote__r.SBQQ__Account__r.Name,
                Quote__r.SBQQ__Opportunity2__r.Lead_Type__c,
                Quote__r.SBQQ__Opportunity2__r.Name, Quote__r.SBQQ__Opportunity2__r.Lead_Producer__c,
                Quote__r.SBQQ__Opportunity2__r.Lead_Producer_Email__c,
                Quote__r.SBQQ__Opportunity2__r.Account.Production_Guidelines_1__c
                FROM Confirmed_Member__c WHERE Id =: confMbmr AND Status__c = 'Email Sent'];
    }
    
    public void execute(SchedulableContext sc){
        if(!mbmr.isEmpty())
        {
            List<Messaging.SingleEmailMessage> reminders = new List<Messaging.SingleEmailMessage>();
            
            for(Confirmed_Member__c toSend:mbmr)
            {
                String body = 'Hi ' + toSend.Account_Team_Member__r.Team_Member__r.FirstName + ', </br></br>';
                body += 'We have previously sent you an email regarding your availability for an upcoming shoot. Please respond to the availability email within 24 hours.';
                
                String subject = 'Slate Studios: ' + toSend.Quote__r.SBQQ__Opportunity2__r.Name + ' | ' + toSend.Service_Type__c + ' | ' + 'Availability Reminder';
                
                Messaging.SingleEmailMessage reminder = new Messaging.SingleEmailMessage();
                reminder.setToAddresses(new List<String> {toSend.Account_Team_Member__r.Email__c});
                reminder.setHtmlBody(createEmailBody(toSend));
                reminder.setBccAddresses(new List<String>{toSend.Quote__r.SBQQ__Opportunity2__r.Lead_Producer_email__c});
                reminder.setReplyTo(replyToEmail);
                
                toSend.Reminder_Email_Sent__c = system.now();
                reminders.add(reminder);
            }
            
            if(!reminders.isEmpty())
            	Messaging.SendEmailResult[] results = Messaging.sendEmail(reminders);
        }  
    }
    
    private String createEmailBody(Confirmed_Member__c confMbmr)
    {
        String emailBody = 'Hi ' + confMbmr.Account_Team_Member__r.Team_Member__r.FirstName + ',<br><br>';
        
        emailBody += 'Wanted to check in on your availability for the following project.<br><br>';
        
        emailBody += '<ul>';
        emailBody += '<li>Client: ' + confMbmr.Quote__r.SBQQ__Account__r.Name + '</li><br>';
        emailBody += '<li>Job Type: ' + confMbmr.Quote__r.SBQQ__Opportunity2__r.Lead_Type__c + '</li><br>';
        emailBody += '<li>Rate: $' + confMbmr.Confirmed_Rate__c + '</li><br>';
        emailBody += '<li>Start Shoot Date: ' + confMbmr.Start_Date__c + '</li><br>';
        emailBody += '<li>End Shoot Date: ' + confMbmr.End_Date__c + '</li><br>';
        emailBody += '<li># Days: ' + confMbmr.quote__r.Days_on_Project__c + '</li><br>';
        
        emailBody += '</ul><br>If available, please respond "Yes"<br>';
        emailBody += 'If not available, please respond "No"<br>';
        emailBody += 'If you would like further information and/or have other hold(s), please let us know.<br><br>';
        emailBody += 'Best,<br>' + confMbmr.Quote__r.SBQQ__Opportunity2__r.Lead_Producer__c;
        
        //Start Signature//
        emailBody += '<br><br>';
        emailBody += '<img src="'+Label.Slate_Logo+'" width="96" height="25"><br><br>';
        emailBody += 'Slate Studios<br>5102 21ST ST., 4TH FL<br>LONG ISLAND CITY, NY 11101<br>212 390 0243<br><a href="slate-nyc.com">slate-nyc.com</a><br><a href="https://www.instagram.com/slate__studios/?hl=en">@slate_studios</a><br><br>';
        emailBody += '<span style="font-size:9px">This message (including any attachment) is for the intended recipient and may contain material that is confidential or subject to copyright. If you are not the intended recipient then the dissemination, copying, or distribution of this message (including any attachments) is strictly prohibited. If you have received this message in error, please notify us by replying to this email and deleting it from your computer. Any views or opinion are those the sender and do not necessarily represent those of the company.</span>';
        
        return emailBody;
    }
}