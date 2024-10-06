public class OpportunityTriggerHandler {
    public static Boolean ToCreateCalendarRecord = true;
    public static Boolean ToDeleteCalendarRecordOnHoldRecords = true;
    public static Map<Id,Account> accounts = new Map<Id,Account>();
    //E-Commerce - EC
    //Brand Content - BC
    //Studio Rental - SR
    //Retouching - RT
    //Motion - MT
    //Palermo - Branding -> BR
    //Palermo - Digital/UX -> UX
    //Casablanca - Motion Production -> CMP
    //Casablanca - Motion Post Production -> CMPP
    //Align - CGI - 'CG'
    //Align - VFX/Animation - 'VX'
    //Palermo - Photo Production - 'BC'
    //Palermo - Video Production - 'MT'
    //Palermo - CGI - 'CG'
    //YEARMODAY_ACCOUNTNAME_LEADTYPE
    public static void onBeforeInsert(List<Opportunity> newOpps)
    {
        Set<Id> accIds = new Set<Id>();
        
        for(Opportunity opp:newOpps)
        {
            String pricebook = System.Label.Default_Pricebook_Name;
            
            opp.Pricebook2Id = Test.isRunningTest() ? Test.getStandardPricebookId() : [SELECT Id FROM Pricebook2 WHERE Name =: pricebook AND IsActive = true LIMIT 1].Id;
            
            accIds.add(opp.AccountId);
        }
        
        accounts = new Map<Id,Account>([SELECT Name FROM Account WHERE Id IN: accIds]);
        
        for(Opportunity opp:newOpps)
        {
            opp.Name = setOppName(opp.Lead_Type__c,accounts.get(opp.AccountId).Name);
        }
    }
    
    public static void onAfterInsert(Map<Id,Opportunity> newMap)
    {
            AutoQuoteGeneration.autoQuote(newMap.values()[0].Id);
    }
    
    public static String setOppName(String LeadType, String accountName)
    {
        
        String datePart = System.now().format('YYMMdd') + '_';
        
        String accPart = accountName.replaceAll(' ', '');
        accPart = accPart.toUpperCase() + '_';
        
        String leadTypePart = 'EC';
        
        SWITCH ON(LeadType)
        {
            WHEN 'Brand Content'{
                leadTypePart = 'BC';
            }
            WHEN 'Studio Rental'{
                leadTypePart = 'SR';
            }
            when 'Motion' {
                leadTypePart = 'MT';
            }
            when 'Retouching - Align','Retouching'{
                leadTypePart = 'RT';
            }
            when 'Casablanca - Motion Production'{
                leadTypePart = 'CMP';
            }
            when 'Casablanca - Motion Post Production'{
                leadTypePart = 'CMPP';
            }
            when 'Palermo - Branding'{
                leadTypePart = 'BR';
            }
            when 'Palermo - Digital/UX'{
                leadTypePart = 'UX';
            }
            when 'Align - CGI','Slate - CGI','Palermo - CGI'{
                leadTypePart = 'CG';
            }
            when 'Align - VFX/Animation'{
                leadTypePart = 'VX';
            }
            when 'Palermo - Photo Production'{
                leadTypePart = 'BC';
            }
            when 'Palermo - Video Production'{
                leadTypePart = 'MT';
            }
            when 'Align - Video Editing'{
                leadTypePart = 'VE';
            }
        }
        
        return datePart+accPart+leadTypePart;
        
    }
    
    public void OnBeforeInsertObj(List<Opportunity> newValues) {
        try{
            //Create Calendar Event when Date filled in on Opportunity
            map<String,List<opportunity>> mapShootDateVsLstOpp = new map<String,List<opportunity>>();
            List<Event> lstEventDel = new List<Event>();
            for(Opportunity opp : newValues){
                //To Delete the event if the Shoot start date is null
                if(String.isNotBlank(opp.First_Hold_Calendar__c) && opp.First_Hold_1__c == null){
                    Event e = new Event(Id = Opp.First_Hold_Calendar__c);
                    lstEventDel.add(e);
                    opp.First_Hold_Calendar__c = null;
                }
                if(String.isNotBlank(opp.Second_Hold_Calendar__c) && opp.Shoot_Hold_1__c == null){
                    Event e = new Event(Id = Opp.Second_Hold_Calendar__c);
                    lstEventDel.add(e);
                    opp.Second_Hold_Calendar__c = null;
                }
                if(String.isNotBlank(opp.Shoot_Hold_Calendar__c) && opp.Shoot_Date__c == null){
                    Event e = new Event(Id = Opp.Shoot_Hold_Calendar__c);
                    lstEventDel.add(e);
                    opp.Shoot_Hold_Calendar__c = null;
                }
                //To Delete the event if the Shoot start date is null
                if(opp.First_Hold_1__c <> null){
                    if(mapShootDateVsLstOpp.containsKey('1stShoot')){
                        mapShootDateVsLstOpp.get('1stShoot').add(opp);
                    }else{
                        mapShootDateVsLstOpp.put('1stShoot',new list<opportunity>{opp});
                    }
                }
                if(opp.Shoot_Hold_1__c <> null){
                    if(mapShootDateVsLstOpp.containsKey('2ndShoot')){
                        mapShootDateVsLstOpp.get('2ndShoot').add(opp);
                    }else{
                        mapShootDateVsLstOpp.put('2ndShoot',new list<opportunity>{opp});
                    }
                }
                if(opp.Shoot_Date__c <> null){
                    if(mapShootDateVsLstOpp.containsKey('Shoot')){
                        mapShootDateVsLstOpp.get('Shoot').add(opp);
                    }else{
                        mapShootDateVsLstOpp.put('Shoot',new list<opportunity>{opp});
                    }
                }
                System.debug('OpportunityTriggerHandler.ToCreateCalendarRecord'+OpportunityTriggerHandler.ToCreateCalendarRecord);
                System.debug('mapShootDateVsLstOpp'+mapShootDateVsLstOpp);
                if(!mapShootDateVsLstOpp.isEmpty() && OpportunityTriggerHandler.ToCreateCalendarRecord){
                    OpportunityTriggerHandler.ToCreateCalendarRecord = false;
                    OpportunityTriggerHelper.CreateCalendarEvent(null,mapShootDateVsLstOpp);
                }
                if(!lstEventDel.isEmpty()){
                    delete lstEventDel;
                }
            }
            /*if(Test.isRunningTest()){
                String tmpCatchString;
                Boolean b = tmpCatchString.contains('abc');
            }*/
        }catch(Exception exp){
            String compName = 'OpportunityTriggerHandler.OnBeforeInsertObj'; 
            String compType = 'Apex Class';
            Set<String> setOfErrorRecId = new Set<String>();
            for(Opportunity Opp : newValues){
                setOfErrorRecId.add(Opp.id);
            }
            String recRef = String.join(new List<String>(setOfErrorRecId), ',');
            if(recRef.length()>254){
                recRef = recRef.substring(0, 254);
            }
            String err = exp.getMessage()  + exp.getStackTraceString();
            String req = null;
            System.debug(err);
            Studio_ErrorLogHandler.log(compName, compType, err, null,recRef,null);
        }
        //Create Calendar Event when Date filled in on Opportunity
    }
    
    public void OnAfterInsertObj(Map<Id,Opportunity> newMapValues){
        //Create Logic that will warn users on conflicts on time slot
        Map<Id,Opportunity> mapOppTimeSlotConflict = new Map<Id,Opportunity>();
        for(Opportunity opp : newMapValues.values()){
            OpportunityTriggerHelper.toThrowExceptionOnOpportunity(opp);
            if(opp.First_Hold_1__c != null || opp.Shoot_Hold_1__c != null || opp.Shoot_Date__c != null){
                mapOppTimeSlotConflict.put(opp.id,opp);
            }
        }
        if(!mapOppTimeSlotConflict.isEmpty()){
            OpportunityTriggerHelper.TimeSlotConflict(null,mapOppTimeSlotConflict);
        }
        //Create Logic that will warn users on conflicts on time slot
    }
    
    public void OnBeforeUpdate(Map<Id,Opportunity> newMapValue,Map<Id,Opportunity> oldMapValues){
        //Create Calendar Event when Date filled in on Opportunity
        try{
            map<String,List<opportunity>> mapShootDateVsLstOpp = new map<String,List<opportunity>>();
            List<Event> lstEventDel = new List<Event>();
            for(Opportunity opp : newMapValue.values()){
                //To Delete the event if the Shoot start date is null
                if(String.isNotBlank(opp.First_Hold_Calendar__c) && opp.First_Hold_1__c == null){
                    Event e = new Event(Id = Opp.First_Hold_Calendar__c);
                    lstEventDel.add(e);
                    opp.First_Hold_Calendar__c = null;
                }
                if(String.isNotBlank(opp.Second_Hold_Calendar__c) && opp.Shoot_Hold_1__c == null){
                    Event e = new Event(Id = Opp.Second_Hold_Calendar__c);
                    lstEventDel.add(e);
                    opp.Second_Hold_Calendar__c = null;
                }
                if(String.isNotBlank(opp.Shoot_Hold_Calendar__c) && opp.Shoot_Date__c == null){
                    Event e = new Event(Id = Opp.Shoot_Hold_Calendar__c);
                    lstEventDel.add(e);
                    opp.Shoot_Hold_Calendar__c = null;
                }
                //To Delete the event if the Shoot start date is null
                if(opp.First_Hold_1__c <> null && (oldMapValues.get(opp.id).First_Hold_1__c <> opp.First_Hold_1__c || oldMapValues.get(opp.id).First_Hold_2__c <> opp.First_Hold_2__c ) ){
                    if(mapShootDateVsLstOpp.containsKey('1stShoot')){
                        mapShootDateVsLstOpp.get('1stShoot').add(opp);
                    }else{
                        mapShootDateVsLstOpp.put('1stShoot',new list<opportunity>{opp});
                    }
                }
                if(opp.Shoot_Hold_1__c <> null && (oldMapValues.get(opp.id).Shoot_Hold_1__c <> opp.Shoot_Hold_1__c || oldMapValues.get(opp.id).Shoot_Hold_2__c <> opp.Shoot_Hold_2__c) ){
                    if(mapShootDateVsLstOpp.containsKey('2ndShoot')){
                        mapShootDateVsLstOpp.get('2ndShoot').add(opp);
                    }else{
                        mapShootDateVsLstOpp.put('2ndShoot',new list<opportunity>{opp});
                    }
                }
                if(opp.Shoot_Date__c <> null && (oldMapValues.get(opp.id).Shoot_Date__c <> opp.Shoot_Date__c || oldMapValues.get(opp.id).Shoot_Date_2__c <> opp.Shoot_Date_2__c) ){
                    if(mapShootDateVsLstOpp.containsKey('Shoot')){
                        mapShootDateVsLstOpp.get('Shoot').add(opp);
                    }else{
                        mapShootDateVsLstOpp.put('Shoot',new list<opportunity>{opp});
                    }
                }
                System.debug('mapShootDateVsLstOpp'+mapShootDateVsLstOpp);
                System.debug('OpportunityTriggerHandler.ToCreateCalendarRecord'+OpportunityTriggerHandler.ToCreateCalendarRecord);
                if(!mapShootDateVsLstOpp.isEmpty() && OpportunityTriggerHandler.ToCreateCalendarRecord){
                    OpportunityTriggerHandler.ToCreateCalendarRecord = false;
                    OpportunityTriggerHelper.CreateCalendarEvent(oldMapValues,mapShootDateVsLstOpp);
                }
                System.debug('lstEventDel'+lstEventDel);
                if(!lstEventDel.isEmpty()){
                    delete lstEventDel;
                }
            }
            /*if(Test.isRunningTest()){
                String tmpCatchString;
                Boolean b = tmpCatchString.contains('abc');
            }*/
            //Create Calendar Event when Date filled in on Opportunity
        }catch(Exception exp){
            String compName = 'OpportunityTriggerHandler.OnBeforeUpdate'; 
            String compType = 'Apex Class';
            Set<String> setOfErrorRecId = new Set<String>();
            for(String recId : newMapValue.keySet()){
                setOfErrorRecId.add(recId);
            }
            String recRef = String.join(new List<String>(setOfErrorRecId), ',');
            if(recRef.length()>254){
                recRef = recRef.substring(0, 254);
            }
            String err = exp.getMessage()  + exp.getStackTraceString();
            String req = null;
            Studio_ErrorLogHandler.log(compName, compType, err, null,recRef,null);
        }
        
        //Set opp name if Service type has changed
        for(Opportunity opp:newMapValue.values())
        {           
            if(opp.Lead_Type__c != oldMapValues.get(opp.Id).Lead_Type__c)
                setOppName(opp.Lead_Type__c,opp.Account_Name__c);
        }
    }

    public void OnAfterUpdate(Map<Id,Opportunity> newMapValues,Map<Id,Opportunity> oldMapValues){
         //Create Logic that will warn users on conflicts on time slot
        Set<Id> confDatesChanged = new Set<Id>();
        Map<Id,Opportunity> mapOppTimeSlotConflict = new Map<Id,Opportunity>();
        for(Opportunity opp : newMapValues.values()){
            if(opp.CreatedDate.date() > Date.newInstance(2023, 1, 1)){ //Don't warn on opps before 01/01/2023
                OpportunityTriggerHelper.toThrowExceptionOnOpportunity(opp);
                if((oldMapValues.get(opp.id).First_Hold_1__c <> opp.First_Hold_1__c && opp.First_Hold_1__c != null) || 
                   (oldMapValues.get(opp.id).Shoot_Hold_1__c <> opp.Shoot_Hold_1__c && opp.Shoot_Hold_1__c != null) || 
                   (oldMapValues.get(opp.id).Shoot_Date__c <> opp.Shoot_Date__c && opp.Shoot_Date__c != null) ||
                   (oldMapValues.get(opp.id).First_Hold_2__c <> opp.First_Hold_2__c && opp.First_Hold_2__c != null) || 
                   (oldMapValues.get(opp.id).Shoot_Hold_2__c <> opp.Shoot_Hold_2__c && opp.Shoot_Hold_2__c != null) || 
                   (oldMapValues.get(opp.id).Shoot_Date_2__c <> opp.Shoot_Date_2__c && opp.Shoot_Date_2__c != null)              
                  ){
                      mapOppTimeSlotConflict.put(opp.id,opp);
                  }
                
                if(oldMapValues.get(opp.id).Shoot_Date__c <> opp.Shoot_Date__c && opp.Shoot_Date__c != null)
                    confDatesChanged.add(opp.Id);
            }
        }
        if(!mapOppTimeSlotConflict.isEmpty()){
            OpportunityTriggerHelper.TimeSlotConflict(oldMapValues,mapOppTimeSlotConflict);
        }
        if(!confDatesChanged.isEmpty())
            RoundRobinReschedule.dateChange(confDatesChanged);
        //Create Logic that will warn users on conflicts on time slot
    }

    // public static void OnAfterUpdateCreteInvoice(Map<Id,Opportunity> newMapValues, Map<Id,Opportunity> oldMapValues){
    //     LIst<breadwinner_qbo__Invoice__c> relatedInvoicetoupdate = new  LIst<breadwinner_qbo__Invoice__c>();       
    //     for(Opportunity opprec: newMapValues.values()){
    //         if(opprec.Lead_Type__c.contains('Retouching') 
    //             && opprec.StageName != oldMapValues.get(opprec.Id).StageName && opprec.StageName == 'Won - Production Complete'){
    //                 list<breadwinner_qbo__Invoice__c> inv = new list<breadwinner_qbo__Invoice__c>([ SELECT id,breadwinner_qbo__Due_Date__c 
    //                                 FROM breadwinner_qbo__Invoice__c 
    //                                 WHERE breadwinner_qbo__Opportunity__c =:opprec.Id limit 1]);
    //             if(inv.size()>0){
    //                 if(opprec.Payment_terms__c == 'Net 15'){
    //                     inv[0].breadwinner_qbo__Due_Date__c = opprec.CloseDate.addDays(15);
    //                 }else if(opprec.Payment_terms__c == 'Net 30'){
    //                     inv[0].breadwinner_qbo__Due_Date__c = opprec.CloseDate.addDays(30);
    //                 }else if( opprec.Payment_terms__c == 'Net 60'){
    //                     inv[0].breadwinner_qbo__Due_Date__c = opprec.CloseDate.addDays(60);
    //                 }else{
    //                     inv[0].breadwinner_qbo__Due_Date__c = opprec.CloseDate;
    //                 }
    //                 relatedInvoicetoupdate.add(inv[0]);
    //             }  
    //         }
            
    //     }
        
    //     if(!relatedInvoicetoupdate.isEmpty()){
    //         update relatedInvoicetoupdate;
    //     }
        
    // }
    
}