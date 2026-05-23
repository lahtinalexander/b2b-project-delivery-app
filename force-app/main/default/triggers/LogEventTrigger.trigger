trigger LogEventTrigger on Log_Event__e (after insert) {
    List<Application_Log__c> logsToInsert = new List<Application_Log__c>();

    for (Log_Event__e event : Trigger.new) {
        Application_Log__c log = new Application_Log__c();
        log.Severity__c = event.Severity__c;
        log.Source__c = event.Source__c;
        log.Source_Name__c = event.Source_Name__c;
        log.Message__c = event.Message__c;
        log.Stack_trace__c = event.Stack_Trace__c;
        log.Exception_Type__c = event.Exception_Type__c;
        log.Record_Id__c = event.Record_Id__c;
        log.Context_User__c = event.CreatedById; 

        logsToInsert.add(log);
    }

    if (!logsToInsert.isEmpty()) {
        Database.insert(logsToInsert, false); 
    }
}