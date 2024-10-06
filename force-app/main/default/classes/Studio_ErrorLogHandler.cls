global class Studio_ErrorLogHandler {
    global static void log(String compName,String compType,String e,String errorCode,String recRef,String req){
        Error_Log__c errorlog = new Error_Log__c();
        errorlog.Component_Name__c=compName;
        errorlog.Component_Type__c=compType;
        errorlog.Record_Reference__c=recRef;
        errorlog.Error_Type__c=errorCode;
        errorlog.Error_Message__c=e;
        errorlog.Response_Request__c = req;
        Insert errorlog;
    }
}