public without sharing class ApplicationLogger {

    public class FlowInput {
        @InvocableVariable(label='Severity' description='ERROR, WARNING, INFO, DEBUG, CRITICAL' required=true)
        public String severity;

        @InvocableVariable(label='Source Name (Flow Name)' required=true)
        public String sourceName;

        @InvocableVariable(label='Fault Message' required=true)
        public String stacktrace;

        @InvocableVariable(label='Description' required=false)
        public String message;

        @InvocableVariable(label='Record ID' required=false)
        public String recordId;
    }

    /**
     * Method to call from Flow as Action "Publish Application Log"
     */
    @InvocableMethod(label='Publish Application Log' description='Publishes a log event from Flow Fault Path' category='Logging')
    public static void logFromFlow(List<FlowInput> inputs) {
        List<Log_Event__e> eventsToPublish = new List<Log_Event__e>();
        for (FlowInput input : inputs) {
            Log_Event__e evt = new Log_Event__e();
            evt.Severity__c = input.severity;
            evt.Source__c = 'FLOW';
            evt.Source_Name__c = input.sourceName;
            evt.Message__c = input.message;
            evt.Record_Id__c = input.recordId;
            evt.Stack_Trace__c = input.stacktrace; 
                        
            eventsToPublish.add(evt);
        }

        if (!eventsToPublish.isEmpty()) {
            EventBus.publish(eventsToPublish);
        }
    }

    /**
     * Method to call from Apex code (for catched Exception)
     */
    public static void logException(String className, String message, Exception ex, String recordId) {
        Log_Event__e evt = new Log_Event__e();
        evt.Severity__c = 'ERROR';
        evt.Source__c = 'APEX';
        evt.Source_Name__c = className;
        evt.Message__c = message + ' | ' + ex.getMessage();
        evt.Stack_Trace__c = ex.getStackTraceString();
        evt.Exception_Type__c = ex.getTypeName();
        evt.Record_Id__c = recordId;

        EventBus.publish(evt);
    }

    /**
     * Method for regular Apex logging (Info / Debug / Warning) without Exception
     */
    public static void logMessage(String severity, String className, String message, String recordId) {
        Log_Event__e evt = new Log_Event__e();
        evt.Severity__c = severity;
        evt.Source__c = 'APEX';
        evt.Source_Name__c = className;
        evt.Message__c = message;
        evt.Record_Id__c = recordId;

        EventBus.publish(evt);
    }
}