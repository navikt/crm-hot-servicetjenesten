@isTest
public class HOT_CallFlowControllerTest {
    public static final String TEST_SESSION_ID = '1234TEST';
    public static final String TEST_CALLER     = '12345678';

    // Referenced by HOT_CallFlowController.getEnquiryLogs() when Test.isRunningTest() == true
    public static final String MOCK_ENQUIRY_LOG =
        '[{"puzzel__SessionId__c":"' + TEST_SESSION_ID +
        '", "puzzel__Caller__c":"' + TEST_CALLER + '"}]';

    @isTest
    static void testGetCallerInfo_WithSessionId() {
        Test.startTest();
            List<HOT_CallFlowController.CallerResponse> responses =
                HOT_CallFlowController.getCallerInfo(
                    new List<String>{ TEST_SESSION_ID }
                );
        Test.stopTest();

        // We always get one record back from the mock
        System.assertEquals(1, responses.size(), 'Expected exactly one response');

        HOT_CallFlowController.CallerResponse resp = responses[0];
        System.assertEquals(TEST_CALLER,     resp.callerNumber, 'Caller number should match mock');
        System.assertEquals('PERSON',        resp.themeGroup,   'Default themeGroup');
        System.assertEquals('TEST QUEUE',    resp.callerContext,'Default callerContext');
        System.assertEquals('',              resp.queueName,    'queueName should be empty');
    }

    @isTest
    static void testGetCallerInfo_EmptySessionList() {
        Test.startTest();
            List<HOT_CallFlowController.CallerResponse> responses =
                HOT_CallFlowController.getCallerInfo(
                    new List<String>()
                );
        Test.stopTest();

        // The mock still returns one record, so size==1
        System.assertEquals(1, responses.size(), 'Even with an empty input list, the mock returns one record');

        HOT_CallFlowController.CallerResponse resp = responses[0];
        System.assertEquals(TEST_CALLER,     resp.callerNumber, 'Caller number should match mock');
        System.assertEquals('PERSON',        resp.themeGroup,   'Default themeGroup');
        System.assertEquals('TEST QUEUE',    resp.callerContext,'Default callerContext');
        System.assertEquals('',              resp.queueName,    'queueName should be empty');
    }
}
