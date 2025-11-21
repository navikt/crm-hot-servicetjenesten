@IsTest
public class PSREventControllerTest {
    // ------------------------------------------------------
    // MOCK FOR BEARER TOKEN CALL OUT
    // ------------------------------------------------------
    private class PuzzelMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals(
                'Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IjUyNzVBQzAyMDNFNDdGODJDQ0Y3RjZDODFCQ0M3MDgzIiwidHlwIjoiYXQrand0In0.eyJpc3MiOiJodHRwczovL2FwcC5wdXp6ZWwuY29tL2lkIiwibmJmIjoxNzYzNzEyNDg5LCJpYXQiOjE3NjM3MTI0ODksImV4cCI6MTc2MzcxMzM4OSwiYXVkIjoidXJuOnB1enplbDpjb250YWN0LWNlbnRyZSIsInNjb3BlIjpbImNvbnRhY3QtY2VudHJlIl0sImNsaWVudF9pZCI6IjQxMTU1LXZpb2xldC01MzUiLCJ1cm46cHV6emVsOmNpZCI6IjQxMTU1IiwidXJuOnB1enplbDpjbmFtZSI6Ik5BViBLb250YWt0c2VudGVyIFB1enplbCIsInVybjpwdXp6ZWw6Y2NhdCI6IkEiLCJ1cm46cHV6emVsOmNjOm1zbGlkIjoiYTZwN1UwMDAwMDAwMGlBUUFRIiwidXJuOnB1enplbDpjYzpzbGlkIjoiNDExNTUwOSIsInVybjpwdXp6ZWw6Y2M6c2xuYW1lIjoiTkFWIFJlc2VydmUgaW5zdGFucyAxIiwidXJuOnB1enplbDpjYzpzbHVpZCI6Ijc5MzMyNyIsImp0aSI6Ijc1OEJCNEU3RDZFMTQwMDhDRTk2M0NGMDkwRkRGOUNDIn0.ubx3sR-6muCGiTi2-oGId1uqQJBvQh2DqfY7WrjYNBDlwXjIeMPSkFOTY6xRMZS4hipF5wgl_0I7H5W-qm5QxvYFZUJpkErU6rzmG84FkG9ig10ITcJib5SW_5Sn-39tlyHzx4cELw-mjB4uubUl8ZPl_9pLabTLMTeolC1eo7BZbBVXXV_h4awhBPnHeKvPU_-BvKLD8a0QUJKyp_3GjolvZdW-ArjXzh1NJDB6eM4O4K_qLk-gdK_mo66JQfu_U3lmCIClKafLVleDsbc-7KQCAFvSg-381vyxO_taE5ScAwRqxSnv4JmZm-9m2IMUz79ebeSw1tCKF4vSli-wYQ',
                req.getHeader('Authorization'),
                'Bearer token should be passed.'
            );

            System.assertEquals('application/json', req.getHeader('Content-Type'));

            // Validate endpoint
            System.assert(
                req.getEndpoint().contains('https://api.puzzel.com/ContactCentre5/4115509/etasks'),
                'Callout endpoint should match the Named Credential.'
            );

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success"}');
            return res;
        }
    }

    // ------------------------------------------------------
    // TEST METHOD
    // ------------------------------------------------------
    @IsTest
    static void PSREventControllerTest() {
        // Register Mock
        Test.setMock(HttpCalloutMock.class, new PuzzelMock());

        // Create a sample incoming PushTopic payload
        String incomingJson =
            '{' +
            '"data": {' +
            '"event": {' +
            '"createdDate": "2025-11-20T13:50:22.873Z",' +
            '"replayId": 1,' +
            '"type": "created"' +
            '},' +
            '"sobject": {' +
            '"ServiceChannelId": "0N92o000000LBi6CAG",' +
            '"CreatedDate": "2025-11-20T13:50:22.000Z",' +
            '"WorkItemId": "570Ve000007Dhr7IAC",' +
            '"Id": "0JRVe00000BkI8TOAV",' +
            '"GroupId": "00GKI000001fGti2AE"' +
            '}' +
            '},' +
            '"channel": "/topic/PSRPushTopic"' +
            '}';

        Test.startTest();
        String result = PSREventController.PSREventController(incomingJson);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Callout response should not be null.');
        system.debug(result);
        System.assert(result.contains('"success"'), 'Mock callout should return success JSON.');
    }
}
