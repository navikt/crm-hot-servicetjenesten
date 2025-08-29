@IsTest
private class HOT_OEBSIntegrationControllerTest {
    //Helper method to create a test Person and Account.

    private static Account createTestAccountWithFnr(String fnr) {
        // Create a Person__c record with Name = <fnr>
        Person__c person = new Person__c(Name = fnr);
        insert person;

        // Create an Account referencing that Person__c via CRM_Person__c
        Account acc = new Account(Name = 'Test Account', CRM_Person__c = person.Id);
        insert acc;
        return acc;
    }

    // Simulerer et vanlig, gyldig svar.
    private class oebsMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String mockResponse =
                '{' +
                '    \"p_Brukerinfojson\": {' +
                '        \"fnrStatus\": \"Aktiv\",' +
                '        \"fnr\": \"08067038062\",' +
                '        \"brukerStatus\": \"Aktiv\",' +
                '        \"brukerNummer\": \"1261265\"' +
                '        },' +
                '    \"p_fodsels_nummer\": \"08067038062\"' +
                '}';

            HttpResponse res = new HttpResponse();
            res.setBody(mockResponse);
            res.setStatusCode(200);
            return res;
        }
    }

    // Returnerer en JSON-respons uten 'data'-nøkkelen.
    private class NoDataMock implements HttpCalloutMock {
        public HttpResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            // Body is empty or missing data
            return res;
        }
    }
    @IsTest
    static void HOT_OEBSIntegrationControllerTest() {
        Account acc = createTestAccountWithFnr('08067038062');
        Test.setMock(HttpCalloutMock.class, new oebsMock());

        Test.startTest();
        List<HOT_OEBSIntegrationController.oebsWrapper> result = HOT_OEBSIntegrationController.HOT_OEBS_Brukernummer(
            acc.Id,
            'Account'
        );
        Test.stopTest();

        system.debug('Result: ' + result);

        System.assertNotEquals(null, result, 'Result list should not be null');
        System.assertEquals(1, result.size(), 'Expected 1 brukernummer');
    }
}
