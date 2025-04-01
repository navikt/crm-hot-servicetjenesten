@isTest
public class HOT_CallFlowControllerTest {
    public static final String TEST_SESSION_ID = '1234TEST';
    public static final String TEST_CALLER = '12345678';

    public static final String MOCK_ENQUIRY_LOG =
        '[{"puzzel__SessionId__c":"' +
        TEST_SESSION_ID +
        '", "puzzel__Caller__c": "' +
        TEST_CALLER +
        '"}]';

    @isTest
    static void testGetCallerInfo() {
        Test.startTest();
        List<HOT_CallFlowController.CallerResponse> resp = HOT_CallFlowController.getCallerInfo(
            new List<String>{ TEST_SESSION_ID }
        );
        Test.stopTest();

        System.assertEquals(resp[0].callerNumber, TEST_CALLER);
    }
}
