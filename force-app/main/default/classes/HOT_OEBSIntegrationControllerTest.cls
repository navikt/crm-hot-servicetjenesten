@IsTest
private class HOT_OEBSIntegrationControllerTest {
    @TestSetup
    static void makeData() {
        HOT_ST_TestDataFactory.createRecord(new Person__c(Name = '01048800153'));
    }

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

    // Simulerer et vanlig, gyldig svar for Brukerpass.
    private class oebsBrukerPassMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String mockResponse =
                '{' +
                '    \"fnr\": \"22106635513\",' +
                '    \"brukerNummer\": \"1261265\",' +
                '    \"kontrakt_nummer\": \"21322\",' +
                '    \"sjekk_navn\": \"Brukerpass\",' +
                '    \"start_date\": \"2006-10-06T00:00:00\",' +
                '    \"end_date\": \"null\",' +
                '    \"status\": \"SIGNED\"' +
                '}';

            HttpResponse res = new HttpResponse();
            res.setBody(mockResponse);
            res.setStatusCode(200);
            return res;
        }
    }

    // Simulerer et vanlig, gyldig svar for Brukernr.
    private class oebsBrukerNrMock implements HttpCalloutMock {
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

    // Simulerer et vanlig, gyldig svar for Ordre.
    private class oebsOrderMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String mockResponse =
                '{' +
                '    \"p_account_number\": \"11075636603\",' +
                '    \"p_Ordreinfojson\": [' +
                '        {' +
                '            \"orgId\": \"202\",' +
                '            \"ordreNummer\": \"8508312\",' +
                '            \"fnr\": \"11075636603\",' +
                '            \"brukerNummer\": \"1824356\",' +
                '            \"ordreDato\": \"24-APR-23\",' +
                '            \"status\": \"Klargjort\",' +
                '            \"ordreLinjer\": [' +
                '                {' +
                '                    \"ordreLinjeNummer\": \"2\",' +
                '                    \"artikkel\": \"214808\",' +
                '                    \"artikkelBeskrivelse\": \"Rullator 4hjul Gemino 60 b64 h76-95 sh62 sml hjul massiv\",' +
                '                    \"antall\": \"1\",' +
                '                    \"ordreLinjeDato\": \"24-APR-23\",' +
                '                    \"lovetDato\": \"24-APR-23\",' +
                '                    \"planlagtSkipningsDato\": \"12-APR-23\",' +
                '                    \"statusOrdreLinje\": \"Venter på retur\",' +
                '                    \"anmodningsNummer\": \"1234\",' +
                '                    \"bestillingsNummer\": \"1234\",' +
                '                    \"leveringsadresse\": \"SOLHEIMSLIEN 64\",' +
                '                    \"by\": \"BERGEN\",' +
                '                    \"postNummer\": \"5056\",' +
                '                    \"kommune\": \"4601\",' +
                '                    \"bydel\": \"Klepp\"' +
                '                }' +
                '            ]' +
                '        }' +
                '    ]' +
                '}';

            HttpResponse res = new HttpResponse();
            res.setBody(mockResponse);
            res.setStatusCode(200);
            return res;
        }
    }

    // Simulerer et vanlig, gyldig svar for Ordre med flere ordre or linjer.
    private class oebsOrderLinesMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String mockResponse =
                '{' +
                '    \"p_account_number\": \"11075636603\",' +
                '    \"p_Ordreinfojson\": [' +
                '        {' +
                '            \"orgId\": \"202\",' +
                '            \"ordreNummer\": \"8508312\",' +
                '            \"fnr\": \"11075636603\",' +
                '            \"brukerNummer\": \"1824356\",' +
                '            \"ordreDato\": \"24-APR-23\",' +
                '            \"status\": \"Klargjort\",' +
                '            \"ordreLinjer\": [' +
                '                {' +
                '                    \"ordreLinjeNummer\": \"1\",' +
                '                    \"artikkel\": \"214808\",' +
                '                    \"artikkelBeskrivelse\": \"Rullator 4hjul Gemino 60 b64 h76-95 sh62 sml hjul massiv\",' +
                '                    \"antall\": \"1\",' +
                '                    \"ordreLinjeDato\": \"24-APR-23\",' +
                '                    \"lovetDato\": \"24-APR-23\",' +
                '                    \"planlagtSkipningsDato\": \"12-APR-23\",' +
                '                    \"statusOrdreLinje\": \"Venter på retur\",' +
                '                    \"anmodningsNummer\": \"1234\",' +
                '                    \"bestillingsNummer\": \"1234\",' +
                '                    \"leveringsadresse\": \"SOLHEIMSLIEN 64\",' +
                '                    \"by\": \"BERGEN\",' +
                '                    \"postNummer\": \"5056\",' +
                '                    \"kommune\": \"4601\",' +
                '                    \"bydel\": \"Klepp\"' +
                '                },' +
                '                {' +
                '                    \"ordreLinjeNummer\": \"2\",' +
                '                    \"artikkel\": \"414808\",' +
                '                    \"artikkelBeskrivelse\": \"Test Rullator 4hjul Gemino 60 b64 h76-95 sh62 sml hjul massiv\",' +
                '                    \"antall\": \"1\",' +
                '                    \"ordreLinjeDato\": \"24-APR-23\",' +
                '                    \"lovetDato\": \"24-APR-23\",' +
                '                    \"planlagtSkipningsDato\": \"12-APR-23\",' +
                '                    \"statusOrdreLinje\": \"Venter på retur\",' +
                '                    \"anmodningsNummer\": \"1234\",' +
                '                    \"bestillingsNummer\": \"1234\",' +
                '                    \"leveringsadresse\": \"SOLHEIMSLIEN 64\",' +
                '                    \"by\": \"BERGEN\",' +
                '                    \"postNummer\": \"5056\",' +
                '                    \"kommune\": \"4601\",' +
                '                    \"bydel\": \"Klepp\"' +
                '                }' +
                '            ]' +
                '        },' +
                '        {' +
                '            \"orgId\": \"202\",' +
                '            \"ordreNummer\": \"9508312\",' +
                '            \"fnr\": \"11075636603\",' +
                '            \"brukerNummer\": \"1824356\",' +
                '            \"ordreDato\": \"24-APR-23\",' +
                '            \"status\": \"Klargjort\",' +
                '            \"ordreLinjer\": [' +
                '                {' +
                '                    \"ordreLinjeNummer\": \"1\",' +
                '                    \"artikkel\": \"214808\",' +
                '                    \"artikkelBeskrivelse\": \"Ordre 2 Rullator 4hjul Gemino 60 b64 h76-95 sh62 sml hjul massiv\",' +
                '                    \"antall\": \"1\",' +
                '                    \"ordreLinjeDato\": \"24-APR-23\",' +
                '                    \"lovetDato\": \"24-APR-23\",' +
                '                    \"planlagtSkipningsDato\": \"12-APR-23\",' +
                '                    \"statusOrdreLinje\": \"Venter på retur\",' +
                '                    \"anmodningsNummer\": \"1234\",' +
                '                    \"bestillingsNummer\": \"1234\",' +
                '                    \"leveringsadresse\": \"SOLHEIMSLIEN 64\",' +
                '                    \"by\": \"BERGEN\",' +
                '                    \"postNummer\": \"5056\",' +
                '                    \"kommune\": \"4601\",' +
                '                    \"bydel\": \"Klepp\"' +
                '                }' +
                '            ]' +
                '        }' +
                '    ]' +
                '}';

            HttpResponse res = new HttpResponse();
            res.setBody(mockResponse);
            res.setStatusCode(200);
            return res;
        }
    }

    // Simulerer et vanlig, gyldig svar for Service Ordre.
    private class oebsSOMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String mockResponse =
                '{' +
                '    \"p_fodsels_nummer\": \"22106635513\",' +
                '    \"p_ServiceOrdrejson\": [' +
                '        {' +
                '            \"serviceOrdreNummer\": \"22008018\",' +
                '            \"serviceType\": \"Standard*\",' +
                '            \"sfNummer\": \"25519635\",' +
                '            \"opprettelsesDato\": \"2025-05-19T09:28:07\",' +
                '            \"artikkel\": \"250044\",' +
                '            \"artikkelBeskrivelse\": \"Ers styrel X850 Corpus sb42-57 sd37-57 rygg vreg el seteløft el 9,9km/t\",' +
                '            \"serviceOrdreStatus\": \"Åpen\",' +
                '            \"fnr\": \"22106635513\",' +
                '            \"brukernr\": \"3426735\"' +
                '        }' +
                '    ]' +
                '}';

            HttpResponse res = new HttpResponse();
            res.setBody(mockResponse);
            res.setStatusCode(200);
            return res;
        }
    }

    // Simulerer et vanlig, gyldig svar for Service forespørsel.
    private class oebsSFMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String mockResponse =
                '{' +
                '    \"p_account_number\": \"11075636603\",' +
                '    \"p_SFinfojson\": [' +
                '        {' +
                '            \"orgId\": \"202\",' +
                '            \"sfNummer\": \"25232647\",' +
                '            \"sfType\": \"Behov\",' +
                '            \"problemSammendrag\": \"STØP F3 Corpus + X850 Corpus M Jr\",' +
                '            \"løsningSammendrag\": \"Avv. STØP MRS. Vida Stepanov.\",' +
                '            \"fnr\": \"04120396973\",' +
                '            \"brukerNummer\": \"1981188\",' +
                '            \"sfOpprettetDato\": \"17-JAN-25\",' +
                '            \"status\": \"I arbeid\",' +
                '            \"sfNotater\": [' +
                '                {' +
                //'                    \"notat\": \"09-10-2019 250028 743883 F3 Corpus \n17-06-2019 250043 732646 X850 Corpus M Jr \nMercedes-Benz Sprinter \n\",' +
                '                    \"opprettetDato\": \"17-01-2025 10:35:11\",' +
                '                    \"opprettetAvNavn\": \"Kasper Iversen\",' +
                '                    \"opprettetAvIdent\": \"KIA4701\"' +
                '                },' +
                '                {' +
                '                    \"notat\": \"tralala\",' +
                '                    \"opprettetDato\": \"18-01-2025 10:35:11\",' +
                '                    \"opprettetAvNavn\": \"Kasper Iversen\",' +
                '                    \"opprettetAvIdent\": \"KIA4701\"' +
                '                }' +
                '            ]' +
                '        }' +
                '    ]' +
                '}';

            HttpResponse res = new HttpResponse();
            res.setBody(mockResponse);
            res.setStatusCode(200);
            return res;
        }
    }

    // Simulerer et vanlig, gyldig svar for Service forespørsel.
    private class oebsMultipleSFMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String mockResponse =
                '{' +
                '    \"p_account_number\": \"11075636603\",' +
                '    \"p_SFinfojson\": [' +
                '        {' +
                '            \"orgId\": \"202\",' +
                '            \"sfNummer\": \"25232647\",' +
                '            \"sfType\": \"Behov\",' +
                '            \"problemSammendrag\": \"STØP F3 Corpus + X850 Corpus M Jr\",' +
                '            \"løsningSammendrag\": \"Avv. STØP MRS. Vida Stepanov.\",' +
                '            \"fnr\": \"04120396973\",' +
                '            \"brukerNummer\": \"1981188\",' +
                '            \"sfOpprettetDato\": \"17-JAN-25\",' +
                '            \"status\": \"I arbeid\",' +
                '            \"sfNotater\": [' +
                '                {' +
                '                    \"notat\": \"tittentei\",' +
                '                    \"opprettetDato\": \"17-01-2025 10:35:11\",' +
                '                    \"opprettetAvNavn\": \"Kasper Iversen\",' +
                '                    \"opprettetAvIdent\": \"KIA4701\"' +
                '                },' +
                '                {' +
                '                    \"notat\": \"tralala\",' +
                '                    \"opprettetDato\": \"18-01-2025 10:35:11\",' +
                '                    \"opprettetAvNavn\": \"Kasper Iversen\",' +
                '                    \"opprettetAvIdent\": \"KIA4701\"' +
                '                }' +
                '            ]' +
                '        },' +
                '        {' +
                '            \"orgId\": \"202\",' +
                '            \"sfNummer\": \"35232647\",' +
                '            \"sfType\": \"Behov\",' +
                '            \"problemSammendrag\": \"STØP F3 Corpus + X850 Corpus M Jr\",' +
                '            \"løsningSammendrag\": \"Avv. STØP MRS. Vida Stepanov.\",' +
                '            \"fnr\": \"04120396973\",' +
                '            \"brukerNummer\": \"1981188\",' +
                '            \"sfOpprettetDato\": \"17-JAN-25\",' +
                '            \"status\": \"I arbeid\",' +
                '            \"sfNotater\": [' +
                '                {' +
                '                    \"notat\": \"tralala\",' +
                '                    \"opprettetDato\": \"17-01-2025 10:35:11\",' +
                '                    \"opprettetAvNavn\": \"Kasper Iversen\",' +
                '                    \"opprettetAvIdent\": \"KIA4701\"' +
                '                }' +
                '            ]' +
                '        }' +
                '    ]' +
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
    static void HOT_OEBSIntegrationControllerBrukerNrTest() {
        Account acc = createTestAccountWithFnr('08067038062');
        Test.setMock(HttpCalloutMock.class, new oebsBrukernrMock());

        Test.startTest();
        List<HOT_OEBSIntegrationController.oebsWrapper> result = HOT_OEBSIntegrationController.HOT_OEBS_Integration(
            acc.Id,
            'Account',
            'GET_OEBS_Brukernr'
        );
        Test.stopTest();

        system.debug('Result: ' + result);

        System.assertNotEquals(null, result, 'Result list should not be null');
        System.assertEquals(1, result.size(), 'Expected 1 brukernummer');
        System.assertEquals('1261265', result[0].brukerNr.brukerNummer, 'Expected another brukernummer');
    }

    @IsTest
    static void HOT_OEBSIntegrationControllerBrukerPassTest() {
        Account acc = createTestAccountWithFnr('22106635513');
        Test.setMock(HttpCalloutMock.class, new oebsBrukerPassMock());

        Test.startTest();
        List<HOT_OEBSIntegrationController.oebsWrapper> result = HOT_OEBSIntegrationController.HOT_OEBS_Integration(
            acc.Id,
            'Account',
            'GET_OEBS_Brukerpass'
        );
        Test.stopTest();

        system.debug('Result: ' + result);

        System.assertNotEquals(null, result, 'Result list should not be null');
        System.assertEquals(1, result.size(), 'Expected 1 brukernummer');
        System.assertEquals('SIGNED', result[0].brukerPass.status, 'Expected brukerpass to be SIGNED');
    }

    @IsTest
    static void HOT_OEBSIntegrationControllerOrderTest() {
        Account acc = createTestAccountWithFnr('22106635513');
        Test.setMock(HttpCalloutMock.class, new oebsOrderMock());

        Test.startTest();
        List<HOT_OEBSIntegrationController.oebsWrapper> result = HOT_OEBSIntegrationController.HOT_OEBS_Integration(
            acc.Id,
            'Account',
            'GET_OEBS_Ordre'
        );
        Test.stopTest();

        system.debug('Result orderList: ' + result[0].orderList);

        System.assertNotEquals(null, result, 'Result list should not be null');
        System.assertEquals(1, result.size(), 'Expected 1 Order');
        System.assertEquals(1, result[0].orderList.size(), 'Expected 1 Order Line');
    }

    @IsTest
    static void HOT_OEBSIntegrationControllerMultipleOrderTest() {
        Account acc = createTestAccountWithFnr('22106635513');
        Test.setMock(HttpCalloutMock.class, new oebsOrderLinesMock());

        Test.startTest();
        List<HOT_OEBSIntegrationController.oebsWrapper> result = HOT_OEBSIntegrationController.HOT_OEBS_Integration(
            acc.Id,
            'Account',
            'GET_OEBS_Ordre'
        );
        Test.stopTest();

        system.debug('Result list size: ' + result.size());
        system.debug('Result list order size: ' + result[0].orderList.size());
        system.debug('Result list orderline size: ' + result[0].orderList[0].orderLineList.size());
        System.assertNotEquals(null, result, 'Result list should not be null');
        System.assertEquals(2, result[0].orderList.size(), 'Expected 2 Order');
        System.assertEquals(2, result[0].orderList[0].orderLineList.size(), 'Expected 2 Order Line');
        System.assertEquals(1, result[0].orderList[1].orderLineList.size(), 'Expected 1 Order Line');
    }

    @IsTest
    static void HOT_OEBSIntegrationControllerServiceRequestTest() {
        Account acc = createTestAccountWithFnr('22106635513');
        Test.setMock(HttpCalloutMock.class, new oebsSFMock());

        Test.startTest();
        List<HOT_OEBSIntegrationController.oebsWrapper> result = HOT_OEBSIntegrationController.HOT_OEBS_Integration(
            acc.Id,
            'Account',
            'GET_OEBS_SF'
        );
        Test.stopTest();

        system.debug('Result serviceRequestList: ' + result[0].serviceRequestList);

        System.assertNotEquals(null, result, 'Result list should not be null');
        System.assertEquals(1, result.size(), 'Expected 1 Service forespørsel');
        System.assertEquals(1, result[0].serviceRequestList.size(), 'Expected 1 Service Request Line');
    }

    @IsTest
    static void HOT_OEBSIntegrationControllerMultipleServiceRequestTest() {
        Account acc = createTestAccountWithFnr('22106635513');
        Test.setMock(HttpCalloutMock.class, new oebsMultipleSFMock());

        Test.startTest();
        List<HOT_OEBSIntegrationController.oebsWrapper> result = HOT_OEBSIntegrationController.HOT_OEBS_Integration(
            acc.Id,
            'Account',
            'GET_OEBS_SF'
        );
        Test.stopTest();

        system.debug('Result list size: ' + result.size());
        system.debug('Result list order size: ' + result[0].serviceRequestList.size());
        system.debug('Result list orderline size: ' + result[0].serviceRequestList[0].sfNotater.size());
        System.assertNotEquals(null, result, 'Result list should not be null');
        System.assertEquals(2, result[0].serviceRequestList.size(), 'Expected 2 Order');
        System.assertEquals(2, result[0].serviceRequestList[0].sfNotater.size(), 'Expected 2 Order Line');
        System.assertEquals(1, result[0].serviceRequestList[1].sfNotater.size(), 'Expected 1 Order Line');
    }

    @IsTest
    static void HOT_OEBSIntegrationControllerSOTest() {
        Account acc = createTestAccountWithFnr('22106635513');
        Test.setMock(HttpCalloutMock.class, new oebsSOMock());

        Test.startTest();
        List<HOT_OEBSIntegrationController.oebsWrapper> result = HOT_OEBSIntegrationController.HOT_OEBS_Integration(
            acc.Id,
            'Account',
            'GET_OEBS_SO'
        );
        Test.stopTest();

        system.debug('Result list: ' + result[0].serviceOrderList);

        System.assertNotEquals(null, result, 'Result list should not be null');
        System.assertEquals(1, result.size(), 'Expected 1 Service Order');
        System.assertEquals(1, result[0].serviceOrderList.size(), 'Expected 1 Service Order Line');
    }
}
