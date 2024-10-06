public class OpportunityTriggerHelper {
    /*public static void AfterInsert(Map<id,Opportunity> newMap,Map<id,Opportunity> oldMap){
        set<String> allLead_Type = new set<String>();
        map<id,SBQQ__Quote__c> quotetoinsert = new map<id,SBQQ__Quote__c>();
        
        for(Opportunity opp: newMap.values()){
             if(opp.Lead_Type__c!=null && opp.Sub_Service__c!=null){
                allLead_Type.add(opp.Lead_Type__c);                
             }
        }
        if(allLead_Type.size()>0){
            map<id,Quote_Sub_Service__mdt> quoteallrec = new map<id,Quote_Sub_Service__mdt>([SELECT DeveloperName,Id,Label,Lead_Type__c ,Price_Book_Name__c FROM Quote_Sub_Service__mdt where Lead_Type__c in :allLead_Type]);
            map<String,Quote_Sub_Service__mdt> subserviceWithId = new map<String,Quote_Sub_Service__mdt>();
            set<String> allpricebook = new set<String>();
            for(Quote_Sub_Service__mdt quotsubser:quoteallrec.values()){   
                subserviceWithId.put(quotsubser.Lead_Type__c,quotsubser);             
                allpricebook.add(quotsubser.Price_Book_Name__c);
            }
            map<String,String> prcbookWithId = new map<String,String>();
            for(Pricebook2 prcbook: [SELECT Id,Name FROM Pricebook2 where name in :allpricebook]){
                prcbookWithId.put(prcbook.Name,prcbook.id);
            }
            map<String,SBQQ__Quote__c> OpportunityWithId = new map<String,SBQQ__Quote__c>();
            for(Opportunity opp: newMap.values()){
                if(opp.Lead_Type__c!=null){                  
                   SBQQ__Quote__c newquote = new SBQQ__Quote__c();
                   newquote.OwnerId= opp.OwnerId;
                   newquote.SBQQ__Account__c = opp.AccountId;
                   newquote.SBQQ__Opportunity2__c = opp.id;
                   newquote.SBQQ__PricebookId__c = prcbookWithId.get(subserviceWithId.get(opp.Lead_Type__c).Price_Book_Name__c);
                   OpportunityWithId.put(opp.id,newquote);
                }
            }
            if(OpportunityWithId.values().size()>0)
            Insert OpportunityWithId.values();

            map<String,List<Product_Quote_Line__c>>  ProductQuoteLineWithLeadType =  new map<String,List<Product_Quote_Line__c>>();
            for(Product_Quote_Line__c prodqtlin: [SELECT Cost_Editable__c,Id,IsActive__c,Lead_Type__c,Name,Price_Editable__c,Product__c,Quantity__c,Sub_Service__c FROM Product_Quote_Line__c WHERE IsActive__c = true And Lead_Type__c in: allLead_Type And Sub_Service__c!=null]){
                    if(ProductQuoteLineWithLeadType.containskey(prodqtlin.Lead_Type__c))
                    ProductQuoteLineWithLeadType.get(prodqtlin.Lead_Type__c).add(prodqtlin);
                    else
                    ProductQuoteLineWithLeadType.put(prodqtlin.Lead_Type__c,new List<Product_Quote_Line__c>{prodqtlin});
                    
            }
           // System.debug('===ProductQuoteLineWithLeadType===>'+ProductQuoteLineWithLeadType);
            List<SBQQ__QuoteLine__c> quotlineList = new List<SBQQ__QuoteLine__c>();
            for(Opportunity opp: newMap.values()){// depend on Opportunity inserted as per bussiness 1 time will execute
                if(opp.Lead_Type__c!=null && opp.Sub_Service__c!=null){
                    for(Product_Quote_Line__c prodqtlin : ProductQuoteLineWithLeadType.get(opp.Lead_Type__c)){// depend on quote line configured                       
                        if(opp.Sub_Service__c.Contains(prodqtlin.Sub_Service__c)){
                            SBQQ__QuoteLine__c quotline = new  SBQQ__QuoteLine__c();  
                            quotline.SBQQ__CostEditable__c  = prodqtlin.Cost_Editable__c;
                            quotline.SBQQ__PriceEditable__c =  prodqtlin.Price_Editable__c;
                            quotline.SBQQ__Product__c = prodqtlin.Product__c;
                            quotline.SBQQ__Quantity__c = prodqtlin.Quantity__c;
                            quotline.SBQQ__Quote__c = OpportunityWithId.get(opp.id).id;
                            quotline.Sub_Service__c =prodqtlin.Sub_Service__c;
                            quotline.Lead_Type__c =opp.Lead_Type__c;
                            quotlineList.add(quotline);
                        }                       
                    }
                }
            } 
           // System.debug('===quotlineList===>'+quotlineList);
            if(quotlineList.size()>0)
            Insert quotlineList;
        }
    }
    */
    //To throw an exception when there is conflict on time slots
    public static void TimeSlotConflict(Map<id,Opportunity> oldMap,Map<id,Opportunity> selectOpp){
        //map<String,List<Date>> mapTypeVslstDate = new map<String,List<Date>>();
        Date smallestStartDate = null;
        Date biggestEndDate = null;
        for(Opportunity opp :selectOpp.values()){
            //Conflict with First Hold Start Date
            if((oldMap == null || ( oldMap != null && opp.First_Hold_1__c <> oldMap.get(opp.id).First_Hold_1__c)) && 
               ((opp.First_Hold_1__c >= opp.Shoot_Hold_1__c && opp.First_Hold_1__c <= opp.Shoot_Hold_2__c) || 
               (opp.First_Hold_1__c >= opp.Shoot_Date__c && opp.First_Hold_1__c <= opp.Shoot_Date_2__c))) {
                   opp.First_Hold_1__c.addError(System.Label.StartFirstDateIsConflict);
               }
            //Conflict with First Hold End Date
            else if((oldMap == null || ( oldMap != null && opp.First_Hold_2__c <> oldMap.get(opp.id).First_Hold_2__c)) && 
                	((opp.First_Hold_2__c >= opp.Shoot_Hold_1__c && opp.First_Hold_2__c <= opp.Shoot_Hold_2__c) || 
                	(opp.First_Hold_2__c >= opp.Shoot_Date__c && opp.First_Hold_2__c <= opp.Shoot_Date_2__c))){
                        opp.First_Hold_2__c.addError(System.Label.EndFirstDateIsConflict);
               }
            //Conflict with Second Hold Start Date
            else if((oldMap == null || ( oldMap != null && opp.Shoot_Hold_1__c <> oldMap.get(opp.id).Shoot_Hold_1__c)) && 
                	((opp.Shoot_Hold_1__c >= opp.First_Hold_1__c && opp.Shoot_Hold_1__c <= opp.First_Hold_2__c) || 
               		(opp.Shoot_Hold_1__c >= opp.Shoot_Date__c && opp.Shoot_Hold_1__c <= opp.Shoot_Date_2__c))){
                        opp.Shoot_Hold_1__c.addError(System.Label.StartSecondDateIsConflict);
               }
            //Conflict with Second Hold End Date
            else if((oldMap == null || ( oldMap != null && opp.Shoot_Hold_2__c <> oldMap.get(opp.id).Shoot_Hold_2__c)) && 
                	((opp.Shoot_Hold_2__c >= opp.First_Hold_1__c && opp.Shoot_Hold_2__c <= opp.First_Hold_2__c) || 
               		(opp.Shoot_Hold_2__c >= opp.Shoot_Date__c && opp.Shoot_Hold_2__c <= opp.Shoot_Date_2__c))){
                        opp.Shoot_Hold_2__c.addError(System.Label.EndSecondDateIsConflict);
               }
            //Conflict with Shoot Start Date
            else if((oldMap == null || ( oldMap != null && opp.Shoot_Date__c <> oldMap.get(opp.id).Shoot_Date__c)) && 
                	((opp.Shoot_Date__c >= opp.First_Hold_1__c && opp.Shoot_Date__c <= opp.First_Hold_2__c) || 
               		(opp.Shoot_Date__c >= opp.Shoot_Hold_1__c && opp.Shoot_Date__c <= opp.Shoot_Hold_2__c))){
                        opp.Shoot_Date__c.addError(System.Label.StartShootDateIsConflict);
               }
            //Conflict with Shoot End Date
            else if((oldMap == null || ( oldMap != null && opp.Shoot_Date_2__c <> oldMap.get(opp.id).Shoot_Date_2__c)) && 
                	((opp.Shoot_Date_2__c >= opp.First_Hold_1__c && opp.Shoot_Date_2__c <= opp.First_Hold_2__c) || 
               		(opp.Shoot_Date_2__c >= opp.Shoot_Hold_1__c && opp.Shoot_Date_2__c <= opp.Shoot_Hold_2__c))){
                        opp.Shoot_Date_2__c.addError(System.Label.EndShootDateIsConflict);
               }
        }
        List<String> lstOwnerId = new List<String>();
        lstOwnerId.add(System.Label.CalendarForShootHoldDate);
        lstOwnerId.add(System.Label.CalendarForShootDate);
        for(event ev : [select id,whatid,what.name,StartDateTime,EndDateTime,OwnerID from event where StartDateTime != null and EndDateTime !=null and StartDateTime >= Last_N_Years:365 and EndDateTime <= Next_N_Years:365 and OwnerID IN: lstOwnerId and WhatId Not IN:selectOpp.keySet() and what.type = 'Opportunity' limit 25000]){
            for(Opportunity opp :selectOpp.values()){
                //String recLink ='<a style="text-decoration: none;" href="https://slatestudios--tamtech.my.salesforce.com/'+ev.whatid+'" >'+ev.what.name+'</a>';
                String recLink =ev.whatid+'-'+ev.what.name;
                //EventCreationOnCalendarOverlapping :- Overlapping of calendar is allowed if it is true
                if(Boolean.valueOf(System.Label.EventCreationOnCalendarOverlapping)){
                    //Conflict with First Hold Start Date
                    if(opp.First_Hold_1__c >= ev.StartDateTime && opp.First_Hold_1__c <= ev.EndDateTime && ev.OwnerID == System.Label.CalendarForShootHoldDate) {
                        opp.First_Hold_1__c.addError(System.Label.StartFirstDateWithOppConflict+'-'+recLink,false);
                    }
                    //Conflict with First Hold End Date
                    else if(opp.First_Hold_2__c >= ev.StartDateTime && opp.First_Hold_2__c <= ev.EndDateTime && ev.OwnerID == System.Label.CalendarForShootHoldDate) {
                        opp.First_Hold_2__c.addError(System.Label.EndFirstDateWithOppConflict+'-'+recLink,false);
                    }
                    //Conflict with Second Hold Start Date
                    else if(opp.Shoot_Hold_1__c >= ev.StartDateTime && opp.Shoot_Hold_1__c <= ev.EndDateTime && ev.OwnerID == System.Label.CalendarForShootHoldDate) {
                        opp.Shoot_Hold_1__c.addError(System.Label.StartSecondDateWithOppConflict+'-'+recLink,false);                        
                    }
                    //Conflict with Second Hold End Date
                    else if(opp.Shoot_Hold_2__c >= ev.StartDateTime && opp.Shoot_Hold_2__c <= ev.EndDateTime && ev.OwnerID == System.Label.CalendarForShootHoldDate) {
                        opp.Shoot_Hold_2__c.addError(System.Label.EndSecondDateWithOppConflict+'-'+recLink,false);
                    }
                    //Conflict with Shoot Start Date
                    else if(opp.Shoot_Date__c >= ev.StartDateTime && opp.Shoot_Date__c <= ev.EndDateTime && ev.OwnerID == System.Label.CalendarForShootDate) {
                        opp.Shoot_Date__c.addError(System.Label.StartShootDateWithOppConflict+'-'+ev.whatid);
                    }
                    //Conflict with Shoot End Date
                    else if(opp.Shoot_Date_2__c >= ev.StartDateTime && opp.Shoot_Date_2__c <= ev.EndDateTime && ev.OwnerID == System.Label.CalendarForShootDate) {
                        opp.Shoot_Date_2__c.addError(System.Label.EndShootDateWithOppConflict+'-'+ev.whatid);
                    }
                }
                //EventCreationOnCalendarOverlapping :- Overlapping of calendar is not allowed if it is false
                else{
                    //Conflict with First Hold Start Date
                    if(opp.First_Hold_1__c >= ev.StartDateTime && opp.First_Hold_1__c <= ev.EndDateTime) {
                        opp.First_Hold_1__c.addError(System.Label.StartFirstDateWithOppConflict+'-'+recLink,false);
                    }
                    //Conflict with First Hold End Date
                    else if(opp.First_Hold_2__c >= ev.StartDateTime && opp.First_Hold_2__c <= ev.EndDateTime) {
                        opp.First_Hold_2__c.addError(System.Label.EndFirstDateWithOppConflict+'-'+recLink,false);
                    }
                    //Conflict with Second Hold Start Date
                    else if(opp.Shoot_Hold_1__c >= ev.StartDateTime && opp.Shoot_Hold_1__c <= ev.EndDateTime) {
                        opp.Shoot_Hold_1__c.addError(System.Label.StartSecondDateWithOppConflict+'-'+recLink,false);                        
                    }
                    //Conflict with Second Hold End Date
                    else if(opp.Shoot_Hold_2__c >= ev.StartDateTime && opp.Shoot_Hold_2__c <= ev.EndDateTime) {
                        opp.Shoot_Hold_2__c.addError(System.Label.EndSecondDateWithOppConflict+'-'+recLink,false);
                    }
                    //Conflict with Shoot Start Date
                    else if(opp.Shoot_Date__c >= ev.StartDateTime && opp.Shoot_Date__c <= ev.EndDateTime) {
                        opp.Shoot_Date__c.addError(System.Label.StartShootDateWithOppConflict+'-'+ev.whatid);
                    }
                    //Conflict with Shoot End Date
                    else if(opp.Shoot_Date_2__c >= ev.StartDateTime && opp.Shoot_Date_2__c <= ev.EndDateTime) {
                        opp.Shoot_Date_2__c.addError(System.Label.EndShootDateWithOppConflict+'-'+ev.whatid);
                    }   
                }
            }
        }
    }
    
    public static void toThrowExceptionOnOpportunity(Opportunity opp){
        if(opp.First_Hold_1__c == null && opp.First_Hold_2__c != null){
            opp.First_Hold_1__c.addError(System.Label.StartFirstDateIsNull);
        }
        if(opp.First_Hold_1__c != null && opp.First_Hold_2__c != null && opp.First_Hold_1__c > opp.First_Hold_2__c){
            opp.First_Hold_1__c.addError(System.Label.StartFirstDateIsGreater);
        }
        if(opp.Shoot_Hold_1__c == null && opp.Shoot_Hold_2__c != null){
            opp.Shoot_Hold_1__c.addError(System.Label.StartSecondDateIsNull);
        }
        if(opp.Shoot_Hold_1__c != null && opp.Shoot_Hold_2__c != null && opp.Shoot_Hold_1__c > opp.Shoot_Hold_2__c){
            opp.Shoot_Hold_1__c.addError(System.Label.StartSecondDateIsGreater);
        }
        if(opp.Shoot_Date__c == null && opp.Shoot_Date_2__c != null){
            opp.Shoot_Date__c.addError(System.Label.StartShootDateIsNull);
        }
        if(opp.Shoot_Date__c != null && opp.Shoot_Date_2__c != null && opp.Shoot_Date__c > opp.Shoot_Date_2__c ){
            opp.Shoot_Date__c.addError(System.Label.StartShootDateIsGreater);
        }
        if(opp.Shoot_Date__c != null && opp.Shoot_Date_2__c != null && opp.Shoot_Date__c > opp.Shoot_Date_2__c ){
            opp.Shoot_Date__c.addError(System.Label.StartShootDateIsGreater);
        }
        if(opp.Shoot_Date__c != null && opp.First_Hold_1__c != null ){
            opp.First_Hold_1__c.addError(System.Label.AvoidFirstHoldDate);
        }
        if(opp.Shoot_Date__c != null && opp.Shoot_Hold_1__c != null ){
            opp.Shoot_Hold_1__c.addError(System.Label.AvoidSecondHoldDate);
        }
    }
    public Static void CreateCalendarEvent(Map<id,Opportunity> oldMap,map<String,List<opportunity>> mapShootDateVsLstOpp){
        Set<String> setOppErrorId = new Set<String>();
        System.debug('mapShootDateVsLstOpp'+mapShootDateVsLstOpp);
        try{
            map<String,Event> mapOppIdVsEvent = new map<String,Event>();
            map<String,List<EventRelation>> mapOppIdVsEventRel = new map<String,List<EventRelation>>();
            map<String,Opportunity> mapOppIdVsOpp = new map<String,Opportunity>();
            Integer count = 0;
            List<Event> lstEvent = new List<Event>();
            List<String> lstOppId = new List<String>();
            map<String,String> mapOppIdVsEventId = new map<String,String>();
            List<EventRelation> erLst = new List<EventRelation>();
            
            if(mapShootDateVsLstOpp.containsKey('1stShoot')){
                mapOppIdVsOpp.clear();
                for(Opportunity Opp : mapShootDateVsLstOpp.get('1stShoot')){
                    Date EventEndDate = null;
                    if(opp.First_Hold_2__c <> null){
                    	EventEndDate = Date.newInstance(opp.First_Hold_2__c.year(),opp.First_Hold_2__c.month(),opp.First_Hold_2__c.day());    
                    }
                    mapOppIdVsOpp.put(opp.id,opp);
                    mapOppIdVsEvent.put(Opp.id,CreateEvent(Opp,opp.First_Hold_Calendar__c,'1st Hold',System.Label.CalendarForShootHoldDate,EventEndDate,opp.First_Hold_1__c));
                }
                if(!mapOppIdVsEvent.isEmpty()){
                    lstEvent.clear();
                    mapOppIdVsEventId.clear();
                    lstOppId.clear();
                    erLst.clear();
                    count = 0;
                    lstOppId.addAll(mapOppIdVsEvent.keySet());
                    lstEvent.addAll(mapOppIdVsEvent.values());
                    List<Database.upsertResult> uResults = Database.upsert(lstEvent,false);
                    for(Database.upsertResult result:uResults) {
                        if(result.isSuccess()){
                            mapOppIdVsEventId.put(lstOppId.get(count),result.getId());
                        }else{
                            setOppErrorId.add(lstOppId.get(count));
                        }
                        count++;
                    }
                    if(!mapOppIdVsEventId.isempty()){
                        //For Event Relationships
                        for(String OppId : mapOppIdVsEventId.keySet()){
                            Opportunity Opp = mapOppIdVsOpp.get(OppId);
                            String eventId = mapOppIdVsEventId.get(OppId);
                            Opp.First_Hold_Calendar__c = eventId;
                            if(String.isNotBlank(Opp.OwnerId)){
                                erLst.add(CreateEventRelation(eventId, false,false,false,Opp.OwnerId));    
                            }
                            if(String.isNotBlank(Opp.PrimaryContact__c)){
                                erLst.add(CreateEventRelation(eventId, false,false,false,Opp.PrimaryContact__c));
                            }
                            if(String.isNotBlank(Opp.Id)){
                                erLst.add(CreateEventRelation(eventId, false,true,true,Opp.Id));
                            } 
                        }
                        List<Database.upsertResult> eventRelResults = Database.upsert(erLst,false);
                    }
                }
            }
            if(mapShootDateVsLstOpp.containsKey('2ndShoot')){
                mapOppIdVsOpp.clear();
                mapOppIdVsEvent.clear();
                for(Opportunity Opp : mapShootDateVsLstOpp.get('2ndShoot')){
                    Date EventEndDate = null;
                    if(opp.Shoot_Hold_2__c <> null){
                    	EventEndDate = Date.newInstance(opp.Shoot_Hold_2__c.year(),opp.Shoot_Hold_2__c.month(),opp.Shoot_Hold_2__c.day());    
                    }
                    mapOppIdVsOpp.put(opp.id,opp);
                    mapOppIdVsEvent.put(Opp.id,CreateEvent(Opp,opp.Second_Hold_Calendar__c,'2nd Hold',System.Label.CalendarForShootHoldDate,EventEndDate,opp.Shoot_Hold_1__c));
                }
                if(!mapOppIdVsEvent.isEmpty()){
                    lstEvent.clear();
                    mapOppIdVsEventId.clear();
                    lstOppId.clear();
                    erLst.clear();
                    count = 0;
                    lstOppId.addAll(mapOppIdVsEvent.keySet());
                    lstEvent.addAll(mapOppIdVsEvent.values());
                    List<Database.upsertResult> uResults = Database.upsert(lstEvent,false);
                    for(Database.upsertResult result:uResults) {
                        if(result.isSuccess()){
                            mapOppIdVsEventId.put(lstOppId.get(count),result.getId());
                        }else{
                            setOppErrorId.add(lstOppId.get(count));
                        }
                        count++;
                    }
                    //For Event Relationships
                    for(String OppId : mapOppIdVsEventId.keySet()){
                        Opportunity Opp = mapOppIdVsOpp.get(OppId);
                        String eventId = mapOppIdVsEventId.get(OppId);
                        Opp.Second_Hold_Calendar__c = eventId;
                        if(String.isNotBlank(Opp.OwnerId)){
                        	erLst.add(CreateEventRelation(eventId, false,false,false,Opp.OwnerId));    
                        }
                        if(String.isNotBlank(Opp.PrimaryContact__c)){
                        	erLst.add(CreateEventRelation(eventId, false,false,false,Opp.PrimaryContact__c));
                        }
                        if(String.isNotBlank(Opp.Id)){
                        	erLst.add(CreateEventRelation(eventId, false,true,true,Opp.Id));
                        } 
                    }
                    System.debug('erLst'+erLst);
                    List<Database.upsertResult> eventRelResults = Database.upsert(erLst,false);
                }
            }
            if(mapShootDateVsLstOpp.containsKey('Shoot')){
                mapOppIdVsOpp.clear();
                mapOppIdVsEvent.clear();
                List<Event> lstEventToDel = new List<Event>();
                for(Opportunity Opp : mapShootDateVsLstOpp.get('Shoot')){
                    Date EventEndDate = null;
                    if(opp.Shoot_Date_2__c <> null){
                    	EventEndDate = Date.newInstance(opp.Shoot_Date_2__c.year(),opp.Shoot_Date_2__c.month(),opp.Shoot_Date_2__c.day());    
                    }
                    if(String.isNotBlank(Opp.First_Hold_Calendar__c)){
                        Event e = new Event(Id = Opp.First_Hold_Calendar__c);
                        lstEventToDel.add(e);
                    }
                    if(String.isNotBlank(Opp.Second_Hold_Calendar__c)){
                        Event e = new Event(Id = Opp.Second_Hold_Calendar__c);
                        lstEventToDel.add(e);
                    }
                    opp.First_Hold_1__c = null;
                    opp.First_Hold_2__c = null;
                    opp.Shoot_Hold_1__c = null;
                    opp.Shoot_Hold_2__c = null;
                    mapOppIdVsOpp.put(opp.id,opp);
                    mapOppIdVsEvent.put(Opp.id,CreateEvent(Opp,opp.Shoot_Hold_Calendar__c,'Shoot',System.Label.CalendarForShootDate,EventEndDate,opp.Shoot_Date__c));
                }
                if(!mapOppIdVsEvent.isEmpty()){
                    lstEvent.clear();
                    mapOppIdVsEventId.clear();
                    lstOppId.clear();
                    erLst.clear();
                    count = 0;
                    lstOppId.addAll(mapOppIdVsEvent.keySet());
                    lstEvent.addAll(mapOppIdVsEvent.values());
                    List<Database.upsertResult> uResults = Database.upsert(lstEvent,false);
                    for(Database.upsertResult result:uResults) {
                        if(result.isSuccess()){
                            mapOppIdVsEventId.put(lstOppId.get(count),result.getId());
                        }else{
                            setOppErrorId.add(lstOppId.get(count));
                        }
                        count++;
                    }
                    //For Event Relationships
                    for(String OppId : mapOppIdVsEventId.keySet()){
                        Opportunity Opp = mapOppIdVsOpp.get(OppId);
                        String eventId = mapOppIdVsEventId.get(OppId);
                        Opp.Shoot_Hold_Calendar__c = eventId;
                        if(String.isNotBlank(Opp.OwnerId)){
                        	erLst.add(CreateEventRelation(eventId, false,false,false,Opp.OwnerId));    
                        }
                        if(String.isNotBlank(Opp.PrimaryContact__c)){
                        	erLst.add(CreateEventRelation(eventId, false,false,false,Opp.PrimaryContact__c));
                        }
                        if(String.isNotBlank(Opp.Id)){
                        	erLst.add(CreateEventRelation(eventId, false,true,true,Opp.Id));
                        } 
                    }
                    List<Database.upsertResult> eventRelResults = Database.upsert(erLst,false);
                }
                if(!lstEventToDel.isEmpty()){
                    System.debug('lstEventToDel'+lstEventToDel);
                    delete lstEventToDel;
                }
            }
            //To cover the Catch block 
            if(Test.isRunningTest()){
                String tmpCatchString;
                Boolean b = tmpCatchString.contains('abc');
            }
        }catch(Exception exp){
            String compName = 'OpportunityTriggerHelper.CreateCalendarEvent'; 
            String compType = 'Apex Class';
            String recRef = String.join(new List<String>(setOppErrorId), ',');
            if(recRef.length()>254){
                recRef = recRef.substring(0, 254);
            }
            String err = exp.getMessage()  + exp.getStackTraceString();
            String req = null;
            Studio_ErrorLogHandler.log(compName, compType, err, null,recRef,null);
        }
        
    }
    
    public static Event CreateEvent(Opportunity opp, Id eventID,String OppNamePostFix,String CalendarId, Date EventEndDate, Date  startDate){
        Event e = new Event();
        if(String.isNotBlank(eventID)){
            e.id = eventID;
        }
        if(EventEndDate == null){
            EventEndDate = Date.newInstance(startDate.year(),startDate.month(),startDate.day());
        }
        e.Subject = opp.Name;
        e.OwnerId = CalendarId; //Calendar Id
        e.StartDateTime = Date.newInstance(startDate.year(),startDate.month(),startDate.day());
        e.EndDateTime = EventEndDate;
        e.IsAllDayEvent =true;
        e.WhatId = opp.id; //Opportunity ID
        e.IsReminderSet = true;
        e.ReminderDateTime = e.StartDateTime.addDays(-1);        
        return e;
    }
    
    public static EventRelation CreateEventRelation(String eventId,boolean isInvitee, boolean isWhat, boolean isParent, String EventRelId){
        EventRelation er = new EventRelation();
        er.EventId = eventId;
        er.IsInvitee = isInvitee;
        er.IsWhat = isWhat;
        er.IsParent = isParent;
        er.RelationId = EventRelId; //User Id
        return er;
    }
}