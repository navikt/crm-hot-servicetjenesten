@IsTest
public class Puzzel_PSREventControllerTest {
    // ------------------------------------------------------
    // MOCK FOR BEARER TOKEN CALL OUT
    // ------------------------------------------------------
    private class PuzzelMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);

            /* eTask endpoint mock */
            if (req.getEndpoint().contains('/etasks')) {
                System.assert(
                    req.getEndpoint().contains('callout:PuzzelChat/4115509/etasks'),
                    'Main callout endpoint does not match expected.'
                );
                system.debug('endpoint: ' + req.getEndpoint());
                res.setBody('{"status":"success"}');
            }
            return res;
        }
    }

    // ------------------------------------------------------
    // TEST METHOD
    // ------------------------------------------------------
    @IsTest
    static void PSREventControllerTest() {
        Test.setMock(HttpCalloutMock.class, new PuzzelMock());

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
        String result = Puzzel_PSREventController.PSREventController(incomingJson);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Callout response should not be null.');
        system.debug(result);
        System.assert(result.contains('"success"'), 'Mock callout should return success JSON.');
    }
}
