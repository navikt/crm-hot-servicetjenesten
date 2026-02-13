@isTest
public class HOT_CallFlowControllerTest {
    public static final String TEST_SESSION_ID = '1234TEST';
    public static final String TEST_CALLER = '12345678';
    public static final String MOCK_ENQUIRY_LOG = '[' +
        '{' +
        '"attributes": {"type": "puzzel__EnquiryLog__c"},' + 
        '"puzzel__SessionId__c": "' + TEST_SESSION_ID + '",' +
        '"puzzel__Caller__c": "' + TEST_CALLER + '"' +
        '}' +
    ']';

    @isTest
    static void testGetCallerInfo_MatchFound() {
        Test.startTest();
        // Tester et vanlig treff
        List<HOT_CallFlowController.CallerResponse> resp = HOT_CallFlowController.getCallerInfo(
            new List<String>{ TEST_SESSION_ID }
        );
        Test.stopTest();

        System.assertEquals(1, resp.size(), 'Should return 1 response');
        System.assertEquals(TEST_CALLER, resp[0].callerNumber, 'Should match the mock caller');
    }

    @isTest
    static void testGetCallerInfo_NoMatchAndBulk() {
        // Tester "List in, List out" prinsippet.
        // Input: 1 gyldig ID, 1 ugyldig ID.
        // Forventet: 1 nummer, 1 tomt svar.
        List<String> inputIds = new List<String>{ TEST_SESSION_ID, 'INVALID_SESSION_ID' };

        Test.startTest();
        List<HOT_CallFlowController.CallerResponse> resp = HOT_CallFlowController.getCallerInfo(inputIds);
        Test.stopTest();

        System.assertEquals(2, resp.size(), 'Should return exactly 2 responses matching input size');
        System.assertEquals(TEST_CALLER, resp[0].callerNumber, 'First ID should match mock data');
        System.assertEquals('', resp[1].callerNumber, 'Second ID should return empty string (no match)');
    }
}