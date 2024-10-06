//////////////////////////////////////////////////
//Code by: Smeet Pari
//Description: Send out w/ attachments, availibility emails to account team members matching quote line item products. Also handles sending to next member if any member declines.
//Test Class: RoundRobinTest
/////////////////////////////////////////////////

public class TeamRoundRobinController {
    
    private static SBQQ__Quote__c quote;
    private static Date startDate;
    private static Date endDate;
    private static Map<String, List<Messaging.EmailFileAttachment>> attach;
    private static Set<String> prodGuidelines = new Set<String>();
    private static String replyToEmail = Round_Robin_Email__c.getOrgDefaults().Response_Email__c;
    public static List<Id> preselectedTeam;
    
    
    @InvocableMethod(label='Start Round-Robin' description='Starts sending availability emails to Account team members based on quote line items.')
    public static void startRoundRobin(List<Id> quoteId)
    {
        try
        {
            //Get the quote and quote line items that need to be included in the round robin.
            quote = [SELECT Id, Name, SBQQ__Account__c, SBQQ__Account__r.Name, Round_Robin_Started__c,
                     SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Shoot_Date__c, SBQQ__Opportunity2__r.Shoot_Date_2__c,
                     SBQQ__Opportunity2__r.Continuous__c, SBQQ__Opportunity2__r.Name, Days_on_Project__c,
                     SBQQ__Opportunity2__r.Lead_Producer__c, SBQQ__Opportunity2__r.Lead_Producer_Email__c, SBQQ__Opportunity2__r.Lead_Type__c,
                     SBQQ__Opportunity2__r.Account.Production_Guidelines_1__c,
                     (SELECT Id, SBQQ__Product__c, SBQQ__ProductName__c, SBQQ__Quantity__c, SBQQ__UnitCost__c 
                      FROM SBQQ__LineItems__r WHERE In_Round_Robin__c = true)
                     From SBQQ__Quote__c WHERE Id =: quoteId[0]];
            
            if(!String.isBlank(quote.SBQQ__Opportunity2__r.Account.Production_Guidelines_1__c))
                prodGuidelines.addAll(System.Label.Include_Production_Guidelines.split(','));
            
            Map<String,Integer> serviceTypes = new Map<String,Integer>();
            Map<String, SBQQ__QuoteLine__c> lineItems = new Map<String, SBQQ__QuoteLine__c>();
            
            startDate = quote.SBQQ__Opportunity2__r.Shoot_Date__c;
            endDate = quote.SBQQ__Opportunity2__r.Shoot_Date_2__c;
            getEmailAttachments();
            
            for(SBQQ__QuoteLine__c line:quote.SBQQ__LineItems__r)
            {
                ///Add support for Half-Day
                serviceTypes.put(line.SBQQ__ProductName__c.toLowerCase(), Integer.valueOf(line.SBQQ__Quantity__c));
                lineItems.put(line.SBQQ__ProductName__c.toLowerCase(),line);
            }
            
            List<Account_Team__c> team;
            
            if(preselectedTeam == null)
            	team = [SELECT Id, Name, Account__c, Team_Member__c, Team_Member__r.Name, Team_Member__r.FirstName, Team_Member__r.Email, Service_Type__c, Day_Rate__c, Half_Day_Rate__c 
                        FROM Account_Team__c WHERE Account__c =: quote.SBQQ__Account__c AND Active__c = true AND Service_Type__c IN: serviceTypes.keySet() ORDER BY Times_Hired__c ASC];
            else
                team = [SELECT Id, Name, Account__c, Team_Member__c, Team_Member__r.Name, Team_Member__r.FirstName, Team_Member__r.Email, Service_Type__c, Day_Rate__c, Half_Day_Rate__c 
                        FROM Account_Team__c WHERE Id IN: preselectedTeam ORDER BY Times_Hired__c ASC];
            
            System.debug(team.size());
            
            Map<String, List<Messaging.SingleEmailMessage>> perTypeEmail = new Map<String, List<Messaging.SingleEmailMessage>>();
            Map<String, Confirmed_Member__c> confMembers = new Map<String, Confirmed_Member__c>();
            //Create emails
            for(Account_Team__c member:team)
            {
                System.debug(member);
                if(serviceTypes.keySet().contains(member.Service_Type__c.toLowerCase()))
                {
                    if(!perTypeEmail.keySet().contains(member.Service_Type__c.toLowerCase()))
                    {
                        System.debug(member.Service_Type__c.toLowerCase() + ' First');
                        List<Messaging.SingleEmailMessage> msg = new List<Messaging.SingleEmailMessage>();
                        
                        Messaging.SingleEmailMessage toSend = new Messaging.SingleEmailMessage();
                        toSend.setToAddresses(new List<String>{member.Team_Member__r.Email});
                        toSend.setCcAddresses(new List<String>{quote.SBQQ__Opportunity2__r.Lead_Producer_Email__c});
                        toSend.setSubject('Slate Studios: ' + quote.SBQQ__Opportunity2__r.Name + ' | ' + member.Service_Type__c + ' | ' + 'Availability');
                        toSend.setReplyTo(replyToEmail);
                        
                        Decimal rate = Math.min(lineItems.get(member.Service_Type__c.toLowerCase()).SBQQ__UnitCost__c,member.Day_Rate__c);
                        toSend.setHtmlBody(createEmailBody(member, rate));
                        
                        //Set Attachments
                        List<Messaging.EmailFileAttachment> toAttach = new List<Messaging.EmailFileAttachment>();
                        
                        if(!attach.isEmpty())
                        {
                            if(attach.containsKey('All'))
                                toAttach.addAll(attach.get('All'));
                            if(attach.containsKey(member.Service_Type__c))
                                toAttach.addAll(attach.get(member.Service_Type__c));
                            
                            toSend.setFileAttachments(toAttach);
                        }
                        ///////////////////
                        
                        msg.add(toSend);
                        perTypeEmail.put(member.Service_Type__c.toLowerCase(), msg);
                        
                        Confirmed_Member__c newMember = new Confirmed_Member__c();
                        newMember.Name = member.Team_Member__r.Name;
                        newMember.Quote__c = quoteId[0];
                        newMember.Status__c = 'Email Sent';
                        newMember.Account_Team_Member__c = member.Id;
                        newMember.Quote_Line__c = lineItems.get(member.Service_Type__c.toLowerCase()).Id;
                        newMember.Start_Date__c = startDate;
                        newMember.End_Date__c = endDate;
                        newMember.Confirmed_Rate__c = rate;
                        newMember.Availability_Email_Sent__c = system.now();
                        system.debug(newMember);
                        confMembers.put(member.Name, newMember);
                    }
                    else if(perTypeEmail.keySet().contains(member.Service_Type__c.toLowerCase()))
                    {
                        if(perTypeEmail.get(member.Service_Type__c.toLowerCase()).size() < serviceTypes.get(member.Service_Type__c.toLowerCase()))
                        {   
                            System.debug(member.Service_Type__c.toLowerCase() + ' Second');
                            
                            Messaging.SingleEmailMessage toSend = new Messaging.SingleEmailMessage();
                            toSend.setToAddresses(new List<String>{member.Team_Member__r.Email});
                            toSend.setCcAddresses(new List<String>{quote.SBQQ__Opportunity2__r.Lead_Producer_Email__c});
                            toSend.setSubject('Slate Studios: ' + quote.SBQQ__Opportunity2__r.Name + ' | ' + member.Service_Type__c + ' | ' + 'Availability');
                            toSend.setReplyTo(replyToEmail);
                            
                            Decimal rate = Math.min(lineItems.get(member.Service_Type__c.toLowerCase()).SBQQ__UnitCost__c,member.Day_Rate__c);
                            toSend.setHtmlBody(createEmailBody(member, rate));
                            
                            //Set Attachments
                            List<Messaging.EmailFileAttachment> toAttach = new List<Messaging.EmailFileAttachment>();
                            
                            if(!attach.isEmpty())
                            {
                                if(attach.containsKey('All'))
                                    toAttach.addAll(attach.get('All'));
                                if(attach.containsKey(member.Service_Type__c))
                                    toAttach.addAll(attach.get(member.Service_Type__c));
                                
                                toSend.setFileAttachments(toAttach);
                            }
                            ///////////////////
                            
                            perTypeEmail.get(member.Service_Type__c.toLowerCase()).add(toSend);
                            
                            Confirmed_Member__c newMember = new Confirmed_Member__c();
                            newMember.Name = member.Team_Member__r.Name;
                            newMember.Quote__c = quoteId[0];
                            newMember.Status__c = 'Email Sent';
                            newMember.Account_Team_Member__c = member.Id;
                            newMember.Quote_Line__c = lineItems.get(member.Service_Type__c.toLowerCase()).Id;
                            newMember.Start_Date__c = startDate;
                            newMember.End_Date__c = endDate;
                            newMember.Confirmed_Rate__c = rate;
                            newmember.Availability_Email_Sent__c = system.now();
                            confMembers.put(member.Name, newMember);
                            System.debug(newMember);
                        }
                        else
                        {
                            Confirmed_Member__c queued = new Confirmed_Member__c();
                            queued.Name = member.Team_Member__r.Name;
                            queued.Quote__c = quoteId[0];
                            queued.Status__c = 'Queued';
                            queued.Account_Team_Member__c = member.Id;
                            queued.Quote_Line__c = lineItems.get(member.Service_Type__c.toLowerCase()).Id;
                            queued.Start_Date__c = startDate;
                            queued.End_Date__c = endDate;
                            Decimal rate = Math.min(lineItems.get(member.Service_Type__c.toLowerCase()).SBQQ__UnitCost__c,member.Day_Rate__c);
                            queued.Confirmed_Rate__c = rate;
                            
                            confMembers.put(member.Name, queued);
                        }
                    }
                }
            }
            
            List<Messaging.SingleEmailMessage> allRREmails = new List<Messaging.SingleEmailMessage>();
            
            for(String serviceType:perTypeEmail.keySet())
            {
                allRREmails.addAll(perTypeEmail.get(serviceType));
            }
            
            Messaging.SendEmailResult[] results = Messaging.sendEmail(allRREmails);
            System.debug(results);
            insert confMembers.values();
            
            quote.Round_Robin_Started__c = true;
            update quote;
            
           	Set<Id> schedReminder = new Set<Id>();
            for(Confirmed_Member__c confm:confMembers.values())
            {
                if(confm.Status__c == 'Email Sent')
                	schedReminder.add(confm.Id);
            }
            
            if(!schedReminder.isEmpty() || Test.isRunningTest())
            {
                String hour = String.valueOf(Datetime.now().hour() + 4);
                String minute = String.valueOf(Datetime.now().minute());
                String seconds = String.valueOf(Datetime.now().second());
                String nextFire = seconds + ' ' + minute + ' ' + hour + ' * * ?';
                System.schedule('RoundRobinReminder ' + String.valueOf(Datetime.now()), nextFire, new RoundRobinReminderSched(schedReminder));
            }
        }catch(Exception e)
        {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
    }
    /*
    private static void getEndDate()
    {
        Date startDate = quote.SBQQ__Opportunity2__r.Shoot_Date__c;
        System.debug(startDate);
        //Use days on project - 1 to figure out how many days to add to the start date
        //to get the end date.
        Integer addDays = Integer.valueOf(quote.Days_on_Project__c - 1);
        
        //addDays will only be <= 0 if Days On Project is 1 in which case start and end date are same
        //otherwise addDays needs to be added to startDate to get end date
        if(addDays <= 0)
        {
            endDate = startDate; 
        }
        else
        {
            endDate = startDate.addDays(addDays);
            
            //Convert to datetime and format('E') which returns abbreviated day name
            //use the dayOfWeek to check if the endDate falls on a weekend. Weekends are only allowed if days are continuous
            //otherwise add to endDate to get to closest weekday.
            Datetime checkDay = (Datetime)endDate;
            String dayOfWeek = checkDay.format('E');
            
            if((dayOfWeek.equalsIgnoreCase('Sat') || dayOfWeek.equalsIgnoreCase('Sun')) && !quote.SBQQ__Opportunity2__r.Continuous__c)
            {
                if(dayOfWeek.equalsIgnoreCase('Sat'))
                    endDate = endDate.addDays(2);
                else if(dayOfWeek.equalsIgnoreCase('Sun'))
                    endDate = endDate.addDays(1);
            }
            
            System.debug(endDate);
        }
    }
    */
    private static String createEmailBody(Account_Team__c teamMbmr, Decimal rate)
    {   
        String emailBody = 'Hi ' + teamMbmr.Team_Member__r.FirstName + ',<br><br>';
        
        emailBody += 'Wanted to check in on your availability for the following project.<br><br>';
        
        emailBody += '<ul>';
        emailBody += '<li>Client: ' + quote.SBQQ__Account__r.Name + '</li><br>';
        emailBody += '<li>Job Type: ' + quote.SBQQ__Opportunity2__r.Lead_Type__c + '</li><br>';
        emailBody += '<li>Rate: $' + rate + '</li><br>';
        emailBody += '<li>Start Shoot Date: ' + getDateString(quote.SBQQ__Opportunity2__r.Shoot_Date__c) + '</li><br>';
        emailBody += '<li>End Shoot Date: ' + getDateString(endDate) + '</li><br>';
        emailBody += '<li># Days: ' + quote.Days_on_Project__c + '</li><br>';
        
        if(prodGuidelines.contains(teamMbmr.Service_Type__c))
        {
            string prodGuide = quote.SBQQ__Opportunity2__r.Account.Production_Guidelines_1__c.removeStart('<p>');
            prodGuide = prodGuide.remove('</p>');
            
            emailBody += '<li>' + prodGuide + '</li><br>';
        }
        
        emailBody += '</ul><br>If available, please respond "Yes"<br>';
        emailBody += 'If not available, please respond "No"<br>';
        emailBody += 'If you would like further information and/or have other hold(s), please let us know.<br><br>';
        emailBody += 'Best,<br>' + quote.SBQQ__Opportunity2__r.Lead_Producer__c;
        
        //Start Signature//
        emailBody += '<br><br>';
        emailBody += '<img src="'+Label.Slate_Logo+'" width="96" height="25"><br><br>';
        emailBody += 'Slate Studios<br>5102 21ST ST., 4TH FL<br>LONG ISLAND CITY, NY 11101<br>212 390 0243<br><a href="slate-nyc.com">slate-nyc.com</a><br><a href="https://www.instagram.com/slate__studios/?hl=en">@slate_studios</a><br><br>';
        emailBody += '<span style="font-size:9px">This message (including any attachment) is for the intended recipient and may contain material that is confidential or subject to copyright. If you are not the intended recipient then the dissemination, copying, or distribution of this message (including any attachments) is strictly prohibited. If you have received this message in error, please notify us by replying to this email and deleting it from your computer. Any views or opinion are those the sender and do not necessarily represent those of the company.</span>';
        
        return emailBody;
    }
    
    private static String getDateString(Date toConvert)
    {
        String dateString;
        
        dateString = toConvert.month() + '/' + toConvert.day() + '/' + toConvert.year();
        
        return dateString;
    }
    
    private static void getEmailAttachments()
    {
        Map<Id, Project_Files__c> prjFiles = new Map<Id,Project_Files__c>([SELECT Id, Service_Type__c FROM Project_Files__c WHERE RecordType.Name = 'Shared' AND Opportunity__c =: quote.SBQQ__Opportunity2__c]);
        
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
    
    @Future
    public static void sendNext(Id nextMember)
    {
        Confirmed_Member__c next = [SELECT Id, Quote__c, Status__c, Account_Team_Member__c, Confirmed_Rate__c, Start_Date__c, End_Date__c,
                                    Availability_Email_Sent__c,
                                    Account_Team_Member__r.Team_Member__r.Email, Account_Team_Member__r.Service_Type__c,
                                    Account_Team_Member__r.Team_Member__r.Name,Account_Team_Member__r.Day_Rate__c
                                    FROM Confirmed_Member__c WHERE Id =: nextMember LIMIT 1];
        
        quote = [SELECT Id, Name, SBQQ__Account__c, SBQQ__Account__r.Name,
                     SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Shoot_Date__c, SBQQ__Opportunity2__r.Shoot_Date_2__c,
                     SBQQ__Opportunity2__r.Continuous__c, SBQQ__Opportunity2__r.Name, Days_on_Project__c,
                     SBQQ__Opportunity2__r.Lead_Producer__c, SBQQ__Opportunity2__r.Lead_Producer_Email__c,
                 	 SBQQ__Opportunity2__r.Lead_Type__c,
                     SBQQ__Opportunity2__r.Account.Production_Guidelines_1__c
                     From SBQQ__Quote__c WHERE Id =: next.Quote__c];
        
        startDate = next.Start_Date__c;
        endDate = next.End_Date__c;
        getEmailAttachments();
        
        Messaging.SingleEmailMessage toSend = new Messaging.SingleEmailMessage();
        toSend.setToAddresses(new List<String>{next.Account_Team_Member__r.Team_Member__r.Email});
        toSend.setCcAddresses(new List<String>{quote.SBQQ__Opportunity2__r.Lead_Producer_Email__c});
        toSend.setSubject('Slate Studios: ' + quote.SBQQ__Opportunity2__r.Name + ' | ' + next.Account_Team_Member__r.Service_Type__c + ' | ' + 'Availability');
        toSend.setReplyTo(replyToEmail);
        toSend.setHtmlBody(createEmailBody([SELECT Id, Name, Account__c, Team_Member__c, Team_Member__r.Name, Team_Member__r.FirstName, Team_Member__r.Email, Service_Type__c, Day_Rate__c, Half_Day_Rate__c 
                                          FROM Account_Team__c WHERE Id =: next.Account_Team_Member__c LIMIT 1], next.Confirmed_Rate__c));
        
        //Set Attachments
        List<Messaging.EmailFileAttachment> toAttach = new List<Messaging.EmailFileAttachment>();
        
        if(attach.containsKey('All'))
            toAttach.addAll(attach.get('All'));
        if(attach.containsKey(next.Account_Team_Member__r.Service_Type__c))
            toAttach.addAll(attach.get(next.Account_Team_Member__r.Service_Type__c));
        
        toSend.setFileAttachments(toAttach);
        ///////////////////
        
        Messaging.SendEmailResult[] res = Messaging.sendEmail(new List<Messaging.Email>{toSend});
        
        next.Status__c = 'Email Sent';
        next.Availability_Email_Sent__c = system.now();
        update next;
        
        String hour = String.valueOf(Datetime.now().hour() + 4);
        String minute = String.valueOf(Datetime.now().minute());
        String seconds = String.valueOf(Datetime.now().second());
        String nextFire = seconds + ' ' + minute + ' ' + hour + ' * * ?';
        System.schedule('RoundRobinReminder ' + String.valueOf(Datetime.now()), nextFire, new RoundRobinReminderSched(new Set<Id>{next.Id}));
    }
}