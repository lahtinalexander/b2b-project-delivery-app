@IsTest
private class ApplicationLoggerTest {

    @IsTest
    static void testLogExceptionFromApex() {
        // 1. Create test error (for example, DmlException)
        DmlException testException;
        try {
            // Intentionally causing a field validation error (account name cannot be empty)
            insert new Account();
        } catch (DmlException ex) {
            testException = ex;
        }

        System.assertNotEquals(null, testException, 'Catch DmlException for the Test');

        // 2. Wrapping an asynchronous event in a start/stop Test
        Test.startTest();
        ApplicationLogger.logException('TestClassName', 'Critical business logic error', testException, null);
        Test.stopTest(); // Salesforce forces the LogEventTrigger to fire.

        // 3. Check if Trigger has completed and created log record
        List<Application_Log__c> insertedLogs = [
            SELECT Id, Severity__c, Source__c, Source_Name__c, Message__c, Stack_Trace__c, Exception_Type__c 
            FROM Application_Log__c
        ];

        System.assertEquals(1, insertedLogs.size(), 'Exactly one log entry must be created.');
        Application_Log__c log = insertedLogs[0];
        System.assertEquals('ERROR', log.Severity__c);
        System.assertEquals('APEX', log.Source__c);
        System.assertEquals('TestClassName', log.Source_Name__c);
        System.assert(log.Message__c.contains('Critical business logic error'), 'Message text must exists');
        System.assertNotEquals(null, log.Stack_Trace__c, 'Stack trace must exists');
        System.assertEquals('System.DmlException', log.Exception_Type__c);
    }

    @IsTest
    static void testLogMessageFromApex() {
        Test.startTest();
        ApplicationLogger.logMessage('INFO', 'IntegrationService', 'SAP integration successfully completed', '001xxxxxxxxxAAA');
        Test.stopTest();

        List<Application_Log__c> insertedLogs = [
            SELECT Id, Severity__c, Source__c, Source_Name__c, Message__c, Record_Id__c 
            FROM Application_Log__c
        ];

        System.assertEquals(1, insertedLogs.size(), 'Info log entry must be created');
        System.assertEquals('INFO', insertedLogs[0].Severity__c);
        System.assertEquals('IntegrationService', insertedLogs[0].Source_Name__c);
        System.assertEquals('001xxxxxxxxxAAA', insertedLogs[0].Record_Id__c);
    }

    @IsTest
    static void testLogFromFlowInvocable() {
        // We emulate the incoming parameters sent by the Action element from Flow
        ApplicationLogger.FlowInput testInput = new ApplicationLogger.FlowInput();
        testInput.severity = 'ERROR';
        testInput.sourceName = 'Opportunity_To_Project_Flow';
        testInput.message = 'Error creating Project: Required field is empty';
        testInput.stacktrace = 'An error occurred when the flow tried to create records. Element: Create_Project...';
        testInput.recordId = '006xxxxxxxxxxxx';

        List<ApplicationLogger.FlowInput> flowInputs = new List<ApplicationLogger.FlowInput>{ testInput };

        Test.startTest();
        // We call our @InvocableMethod directly, just like the Flow engine does.
        ApplicationLogger.logFromFlow(flowInputs);
        Test.stopTest();

        List<Application_Log__c> insertedLogs = [
            SELECT Id, Severity__c, Source__c, Source_Name__c, Message__c, Stack_Trace__c, Record_Id__c 
            FROM Application_Log__c
        ];

        System.assertEquals(1, insertedLogs.size(), 'The log from Flow should be successfully created via event');
        Application_Log__c log = insertedLogs[0];
        System.assertEquals('FLOW', log.Source__c);
        System.assertEquals('Opportunity_To_Project_Flow', log.Source_Name__c);
        System.assertEquals('Error creating Project: Required field is empty', log.Message__c);
        System.assertEquals('An error occurred when the flow tried to create records. Element: Create_Project...', log.Stack_Trace__c);
        System.assertEquals('006xxxxxxxxxxxx', log.Record_Id__c);
    }
}