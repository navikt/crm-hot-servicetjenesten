@isTest
public class HOT_CallFlowControllerTest {
    public static final String TEST_SESSION_ID = '1234TEST';
    public static final String TEST_CALLER = '12345678';

    @isTest
    static void testGetCallerInfo_MatchFound() {
        // Inject mock data directly into the controller
        HOT_CallFlowController.mockEnquiryLogs = new List<Map<String, Object>>{
            new Map<String, Object>{
                'puzzel__SessionId__c' => TEST_SESSION_ID,
                'puzzel__Caller__c' => TEST_CALLER
            }
        };

        Test.startTest();
        List<HOT_CallFlowController.CallerResponse> resp = HOT_CallFlowController.getCallerInfo(
            new List<String>{ TEST_SESSION_ID }
        );
        Test.stopTest();

        System.assertEquals(1, resp.size(), 'Should return 1 response');
        System.assertEquals(TEST_CALLER, resp[0].callerNumber, 'Should match the mock caller');
    }

    @isTest
    static void testGetCallerInfo_NoMatchAndBulk() {
        // Inject mock data directly into the controller
        HOT_CallFlowController.mockEnquiryLogs = new List<Map<String, Object>>{
            new Map<String, Object>{
                'puzzel__SessionId__c' => TEST_SESSION_ID,
                'puzzel__Caller__c' => TEST_CALLER
            }
        };

        List<String> inputIds = new List<String>{ TEST_SESSION_ID, 'INVALID_SESSION_ID' };

        Test.startTest();
        List<HOT_CallFlowController.CallerResponse> resp = HOT_CallFlowController.getCallerInfo(inputIds);
        Test.stopTest();

        System.assertEquals(2, resp.size(), 'Should return exactly 2 responses matching input size');
        System.assertEquals(TEST_CALLER, resp[0].callerNumber, 'First ID should match mock data');
        System.assertEquals('', resp[1].callerNumber, 'Second ID should return empty string (no match)');
    }

    @isTest
    static void testGetCallerInfo_EmptyInput() {
        Test.startTest();
        // Passing an empty list
        List<HOT_CallFlowController.CallerResponse> resp = HOT_CallFlowController.getCallerInfo(
            new List<String>()
        );
        Test.stopTest();

        System.assertEquals(0, resp.size(), 'Should return an empty list when input is empty');
    }

    @isTest
    static void testGetCallerInfo_NullCallerInLog() {
        // Inject mock data where the caller number is null
        HOT_CallFlowController.mockEnquiryLogs = new List<Map<String, Object>>{
            new Map<String, Object>{
                'puzzel__SessionId__c' => TEST_SESSION_ID,
                'puzzel__Caller__c' => null
            }
        };

        Test.startTest();
        List<HOT_CallFlowController.CallerResponse> resp = HOT_CallFlowController.getCallerInfo(
            new List<String>{ TEST_SESSION_ID }
        );
        Test.stopTest();

        System.assertEquals(1, resp.size(), 'Should return 1 response');
        System.assertEquals('', resp[0].callerNumber, 'Should return empty string since caller is null in the log');
    }

    @isTest
    static void testGetCallerInfo_NullSessionIdInLog() {
        // Inject mock data where the Session ID is null on the record
        HOT_CallFlowController.mockEnquiryLogs = new List<Map<String, Object>>{
            new Map<String, Object>{
                'puzzel__SessionId__c' => null,
                'puzzel__Caller__c' => TEST_CALLER
            }
        };

        Test.startTest();
        List<HOT_CallFlowController.CallerResponse> resp = HOT_CallFlowController.getCallerInfo(
            new List<String>{ TEST_SESSION_ID }
        );
        Test.stopTest();

        System.assertEquals(1, resp.size(), 'Should return 1 response');
        System.assertEquals('', resp[0].callerNumber, 'Should return empty string because no valid session ID matched');
    }

    @isTest
    static void testGetCallerInfo_NoMockData() {
        // Explicitly clear mock data to test the fallback/query behavior
        HOT_CallFlowController.mockEnquiryLogs = null;

        Test.startTest();
        List<HOT_CallFlowController.CallerResponse> resp = HOT_CallFlowController.getCallerInfo(
            new List<String>{ 'SOME_RANDOM_ID' }
        );
        Test.stopTest();

        System.assertEquals(1, resp.size(), 'Should return 1 response corresponding to the input');
        System.assertEquals('', resp[0].callerNumber, 'Should be empty since no records actually exist/match');
    }
}