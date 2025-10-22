@IsTest
private class HOT_OEBSIntegrationControllerTest {
    @TestSetup
    static void makeData() {
        Person__c person = (Person__c) HOT_ST_TestDataFactory.createRecord(new Person__c(Name = '01048800153'));
        Account acc = [SELECT id FROM Account LIMIT 1];
        Case casy = (Case) HOT_ST_TestDataFactory.createRecord(new Case(AccountId = acc.id));
        Account acc2 = (Account) HOT_ST_TestDataFactory.createRecord(new Account(Name = 'test'));
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
                '    \"fnrStatus\": \"Aktiv\",' +
                '    \"fnr\": \"08067038062\",' +
                '    \"brukerStatus\": \"Aktiv\",' +
                '    \"brukerNummer\": \"1261265\"' +
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
                '[' +
                '   {' +
                '       \"orgId\": \"202\",' +
                '       \"ordreNummer\": \"8508312\",' +
                '       \"fnr\": \"11075636603\",' +
                '       \"brukerNummer\": \"1824356\",' +
                '       \"ordreDato\": \"24-APR-23\",' +
                '       \"status\": \"Klargjort\",' +
                '       \"ordreLinjer\": [' +
                '           {' +
                '               \"ordreLinjeNummer\": \"2\",' +
                '               \"artikkel\": \"214808\",' +
                '               \"artikkelBeskrivelse\": \"Rullator 4hjul Gemino 60 b64 h76-95 sh62 sml hjul massiv\",' +
                '               \"antall\": \"1\",' +
                '               \"ordreLinjeDato\": \"24-APR-23\",' +
                '               \"lovetDato\": \"24-APR-23\",' +
                '               \"planlagtSkipningsDato\": \"12-APR-23\",' +
                '               \"statusOrdreLinje\": \"Venter på retur\",' +
                '               \"anmodningsNummer\": \"1234\",' +
                '               \"bestillingsNummer\": \"1234\",' +
                '               \"leveringsadresse\": \"SOLHEIMSLIEN 64\",' +
                '               \"city\": \"BERGEN\",' +
                '               \"postNummer\": \"5056\",' +
                '               \"kommune\": \"4601\",' +
                '               \"bydel\": \"Klepp\"' +
                '           }' +
                '       ]' +
                '   }' +
                ']';

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
                '[' +
                '    {' +
                '       \"orgId\": \"202\",' +
                '       \"ordreNummer\": \"8508312\",' +
                '       \"fnr\": \"11075636603\",' +
                '       \"brukerNummer\": \"1824356\",' +
                '       \"ordreDato\": \"24-APR-23\",' +
                '       \"status\": \"Klargjort\",' +
                '       \"ordreLinjer\": [' +
                '           {' +
                '              \"ordreLinjeNummer\": \"1\",' +
                '              \"artikkel\": \"214808\",' +
                '              \"artikkelBeskrivelse\": \"Rullator 4hjul Gemino 60 b64 h76-95 sh62 sml hjul massiv\",' +
                '              \"antall\": \"1\",' +
                '              \"ordreLinjeDato\": \"24-APR-23\",' +
                '              \"lovetDato\": \"24-APR-23\",' +
                '              \"planlagtSkipningsDato\": \"12-APR-23\",' +
                '              \"statusOrdreLinje\": \"Venter på retur\",' +
                '              \"anmodningsNummer\": \"1234\",' +
                '              \"bestillingsNummer\": \"1234\",' +
                '              \"leveringsadresse\": \"SOLHEIMSLIEN 64\",' +
                '              \"city\": \"BERGEN\",' +
                '              \"postNummer\": \"5056\",' +
                '              \"kommune\": \"4601\",' +
                '              \"bydel\": \"Klepp\"' +
                '           },' +
                '           {' +
                '              \"ordreLinjeNummer\": \"2\",' +
                '              \"artikkel\": \"414808\",' +
                '              \"artikkelBeskrivelse\": \"Test Rullator 4hjul Gemino 60 b64 h76-95 sh62 sml hjul massiv\",' +
                '              \"antall\": \"1\",' +
                '              \"ordreLinjeDato\": \"24-APR-23\",' +
                '              \"lovetDato\": \"24-APR-23\",' +
                '              \"planlagtSkipningsDato\": \"12-APR-23\",' +
                '              \"statusOrdreLinje\": \"Venter på retur\",' +
                '              \"anmodningsNummer\": \"1234\",' +
                '              \"bestillingsNummer\": \"1234\",' +
                '              \"leveringsadresse\": \"SOLHEIMSLIEN 64\",' +
                '              \"city\": \"BERGEN\",' +
                '              \"postNummer\": \"5056\",' +
                '              \"kommune\": \"4601\",' +
                '              \"bydel\": \"Klepp\"' +
                '           }' +
                '       ]' +
                '    },' +
                '    {' +
                '       \"orgId\": \"202\",' +
                '       \"ordreNummer\": \"9508312\",' +
                '       \"fnr\": \"11075636603\",' +
                '       \"brukerNummer\": \"1824356\",' +
                '       \"ordreDato\": \"24-APR-23\",' +
                '       \"status\": \"Klargjort\",' +
                '       \"ordreLinjer\": [' +
                '           {' +
                '              \"ordreLinjeNummer\": \"1\",' +
                '              \"artikkel\": \"214808\",' +
                '              \"artikkelBeskrivelse\": \"Ordre 2 Rullator 4hjul Gemino 60 b64 h76-95 sh62 sml hjul massiv\",' +
                '              \"antall\": \"1\",' +
                '              \"ordreLinjeDato\": \"24-APR-23\",' +
                '              \"lovetDato\": \"24-APR-23\",' +
                '              \"planlagtSkipningsDato\": \"12-APR-23\",' +
                '              \"statusOrdreLinje\": \"Venter på retur\",' +
                '              \"anmodningsNummer\": \"1234\",' +
                '              \"bestillingsNummer\": \"1234\",' +
                '              \"leveringsadresse\": \"SOLHEIMSLIEN 64\",' +
                '              \"city\": \"BERGEN\",' +
                '              \"postNummer\": \"5056\",' +
                '              \"kommune\": \"4601\",' +
                '              \"bydel\": \"Klepp\"' +
                '           }' +
                '       ]' +
                '    }' +
                ']';

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
                '[' +
                '    {' +
                '        \"serviceOrdreNummer\": \"22008018\",' +
                '        \"serviceType\": \"Standard*\",' +
                '        \"sfNummer\": \"25519635\",' +
                '        \"opprettelsesDato\": \"2025-05-19T09:28:07\",' +
                '        \"artikkel\": \"250044\",' +
                '        \"artikkelBeskrivelse\": \"Ers styrel X850 Corpus sb42-57 sd37-57 rygg vreg el seteløft el 9,9km/t\",' +
                '        \"serviceOrdreStatus\": \"Åpen\",' +
                '        \"fnr\": \"22106635513\",' +
                '        \"brukernr\": \"3426735\"' +
                '    }' +
                ']';

            HttpResponse res = new HttpResponse();
            res.setBody(mockResponse);
            res.setStatusCode(200);
            return res;
        }
    }

    // Simulerer et vanlig, gyldig svar for Service Ordre.
    private class oebsMultipleSOMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String mockResponse =
                '[' +
                '    {' +
                '        \"serviceOrdreNummer\": \"22008018\",' +
                '        \"serviceType\": \"Standard*\",' +
                '        \"sfNummer\": \"25519635\",' +
                '        \"opprettelsesDato\": \"2025-05-19T09:28:07\",' +
                '        \"artikkel\": \"250044\",' +
                '        \"artikkelBeskrivelse\": \"Ers styrel X850 Corpus sb42-57 sd37-57 rygg vreg el seteløft el 9,9km/t\",' +
                '        \"serviceOrdreStatus\": \"Åpen\",' +
                '        \"fnr\": \"22106635513\",' +
                '        \"brukernr\": \"3426735\"' +
                '    },' +
                '    {' +
                '        \"serviceOrdreNummer\": \"22008019\",' +
                '        \"serviceType\": \"Standard*\",' +
                '        \"sfNummer\": \"35519635\",' +
                '        \"opprettelsesDato\": \"2025-05-19T09:28:07\",' +
                '        \"artikkel\": \"250044\",' +
                '        \"artikkelBeskrivelse\": \"Ers styrel X999",' +
                '        \"serviceOrdreStatus\": \"Åpen\",' +
                '        \"fnr\": \"22106635513\",' +
                '        \"brukernr\": \"3426735\"' +
                '    }' +
                ']';

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
                '[' +
                '    {' +
                '        \"orgId\": \"202\",' +
                '        \"sfNummer\": \"25232647\",' +
                '        \"sfType\": \"Behov\",' +
                '        \"problemSammendrag\": \"STØP F3 Corpus + X850 Corpus M Jr\",' +
                '        \"losningSammendrag\": \"Avv. STØP MRS. Vida Stepanov.\",' +
                '        \"fnr\": \"04120396973\",' +
                '        \"brukerNummer\": \"1981188\",' +
                '        \"sfOpprettetDato\": \"17-JAN-25\",' +
                '        \"status\": \"I arbeid\",' +
                '        \"sfNotater\": [' +
                '            {' +
                '                \"notat\": \"09-10-2019 250028 743883 F3 Corpus 17-06-2019 250043 732646 X850 Corpus M Jr Mercedes-Benz Sprinter \",' +
                '                \"opprettetDato\": \"17-01-2025 10:35:11\",' +
                '                \"opprettetAvNavn\": \"Kasper Iversen\",' +
                '                \"opprettetAvIdent\": \"KIA4701\"' +
                '            },' +
                '            {' +
                '                \"notat\": \"tralala\",' +
                '                \"opprettetDato\": \"18-01-2025 10:35:11\",' +
                '                \"opprettetAvNavn\": \"Kasper Iversen\",' +
                '                \"opprettetAvIdent\": \"KIA4701\"' +
                '            }' +
                '        ]' +
                '    }' +
                ']';

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
                '[' +
                '    {' +
                '        \"orgId\": \"202\",' +
                '        \"sfNummer\": \"25232647\",' +
                '        \"sfType\": \"Behov\",' +
                '        \"problemSammendrag\": \"STØP F3 Corpus + X850 Corpus M Jr\",' +
                '        \"losningSammendrag\": \"Test sammendragnummer 1! her tester vi spesielle karakterer og litt lengde\",' +
                '        \"fnr\": \"04120396973\",' +
                '        \"brukerNummer\": \"1981188\",' +
                '        \"sfOpprettetDato\": \"17-JAN-25\",' +
                '        \"status\": \"I arbeid\",' +
                '        \"sfNotater\": [' +
                '            {' +
                '                \"notat\": \"tittentei\",' +
                '                \"opprettetDato\": \"17-01-2025 10:35:11\",' +
                '                \"opprettetAvNavn\": \"Kasper Iversen\",' +
                '                \"opprettetAvIdent\": \"KIA4701\"' +
                '            },' +
                '            {' +
                '                \"notat\": \"tralala\",' +
                '                \"opprettetDato\": \"18-01-2025 10:35:11\",' +
                '                \"opprettetAvNavn\": \"Kasper Iversen\",' +
                '                \"opprettetAvIdent\": \"KIA4701\"' +
                '            }' +
                '        ]' +
                '    },' +
                '    {' +
                '        \"orgId\": \"202\",' +
                '        \"sfNummer\": \"35232647\",' +
                '        \"sfType\": \"Behov\",' +
                '        \"problemSammendrag\": \"STØP F3 Corpus + X850 Corpus M Jr\",' +
                '        \"losningSammendrag\": \"Test sammendrag nummer 2 for å teste dekningsgrad\",' +
                '        \"fnr\": \"04120396973\",' +
                '        \"brukerNummer\": \"1981188\",' +
                '        \"sfOpprettetDato\": \"17-JAN-25\",' +
                '        \"status\": \"I arbeid\",' +
                '        \"sfNotater\": [' +
                '            {' +
                '                \"notat\": \"tralala\",' +
                '                \"opprettetDato\": \"17-01-2025 10:35:11\",' +
                '                \"opprettetAvNavn\": \"Kasper Iversen\",' +
                '                \"opprettetAvIdent\": \"KIA4701\"' +
                '            }' +
                '        ]' +
                '    }' +
                ']';

            HttpResponse res = new HttpResponse();
            res.setBody(mockResponse);
            res.setStatusCode(200);
            return res;
        }
    }

    // Returnerer en JSON-respons uten 'data'-nøkkelen.
    private class badDataMock implements HttpCalloutMock {
        public HttpResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String mockResponse = '{' + '    \"p_account_number\": \"11075636603\"' + '}';
            res.setStatusCode(200);
            res.setBody(mockResponse);
            return res;
        }
    }

    // Returnerer en JSON-respons med feilmelding.
    private class badStatusMock implements HttpCalloutMock {
        public HttpResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String mockResponse = '{' + 'Unauthorized' + '}';
            res.setStatusCode(401);
            res.setBody(mockResponse);
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
        Account acc = [SELECT id FROM Account LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new oebsBrukernrMock());

        Test.startTest();
        HOT_OEBSIntegrationController.oebsWrapper result = HOT_OEBSIntegrationController.HOT_OEBS_Integration(
            acc.Id,
            'Account',
            'GET_OEBS_Brukernr'
        );
        Test.stopTest();
        System.debug('Result: ' + result);
        System.assertNotEquals(null, result, 'Result list should not be null');
        System.assertEquals('1261265', result.brukerNr.brukerNummer, 'Expected another brukernummer');
    }

    @IsTest
    static void HOT_OEBSIntegrationControllerBrukerPassTest() {
        Account acc = [SELECT id FROM Account LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new oebsBrukerPassMock());

        Test.startTest();
        HOT_OEBSIntegrationController.oebsWrapper result = HOT_OEBSIntegrationController.HOT_OEBS_Integration(
            acc.Id,
            'Account',
            'GET_OEBS_Brukerpass'
        );
        Test.stopTest();
        System.debug('Result: ' + result);
        System.assertNotEquals(null, result, 'Result list should not be null');
        System.assertEquals('SIGNED', result.brukerPass.status, 'Expected brukerpass to be SIGNED');
    }

    @IsTest
    static void HOT_OEBSIntegrationControllerOrderTest() {
        Account acc = [SELECT id FROM Account LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new oebsOrderMock());

        Test.startTest();
        HOT_OEBSIntegrationController.oebsWrapper result = HOT_OEBSIntegrationController.HOT_OEBS_Integration(
            acc.Id,
            'Account',
            'GET_OEBS_Ordre'
        );
        Test.stopTest();
        System.debug('Result: ' + result);
        System.assertNotEquals(null, result, 'Result list should not be null');
        System.assertEquals(1, result.orderList.size(), 'Expected 1 Order Line');
    }

    @IsTest
    static void HOT_OEBSIntegrationControllerMultipleOrderTest() {
        Account acc = [SELECT id FROM Account LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new oebsOrderLinesMock());

        Test.startTest();
        HOT_OEBSIntegrationController.oebsWrapper result = HOT_OEBSIntegrationController.HOT_OEBS_Integration(
            acc.Id,
            'Account',
            'GET_OEBS_Ordre'
        );
        Test.stopTest();
        System.debug('Result: ' + result);
        System.assertNotEquals(null, result, 'Result list should not be null');
        System.assertEquals(2, result.orderList.size(), 'Expected 2 Order');
        System.assertEquals(2, result.orderList[0].ordreLinjer.size(), 'Expected 2 Order Line');
        System.assertEquals(1, result.orderList[1].ordreLinjer.size(), 'Expected 1 Order Line');
    }

    @IsTest
    static void HOT_OEBSIntegrationControllerServiceRequestTest() {
        Account acc = [SELECT id FROM Account LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new oebsSFMock());

        Test.startTest();
        HOT_OEBSIntegrationController.oebsWrapper result = HOT_OEBSIntegrationController.HOT_OEBS_Integration(
            acc.Id,
            'Account',
            'GET_OEBS_SF'
        );
        Test.stopTest();
        System.debug('Result: ' + result);
        System.assertNotEquals(null, result, 'Result list should not be null');
        System.assertEquals(1, result.serviceRequestList.size(), 'Expected 1 Service Request Line');
    }

    @IsTest
    static void HOT_OEBSIntegrationControllerMultipleServiceRequestTest() {
        Account acc = [SELECT id FROM Account LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new oebsMultipleSFMock());

        Test.startTest();
        HOT_OEBSIntegrationController.oebsWrapper result = HOT_OEBSIntegrationController.HOT_OEBS_Integration(
            acc.Id,
            'Account',
            'GET_OEBS_SF'
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result list should not be null');
        System.assertEquals(2, result.serviceRequestList.size(), 'Expected 2 Service Request');
        System.assertEquals(2, result.serviceRequestList[0].sfNotater.size(), 'Expected 2 Service Request Line');
        System.assertEquals(1, result.serviceRequestList[1].sfNotater.size(), 'Expected 1 Service Request Line');
    }

    @IsTest
    static void HOT_OEBSIntegrationControllerSOTest() {
        Account acc = [SELECT id FROM Account LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new oebsSOMock());

        Test.startTest();
        HOT_OEBSIntegrationController.oebsWrapper result = HOT_OEBSIntegrationController.HOT_OEBS_Integration(
            acc.Id,
            'Account',
            'GET_OEBS_SO'
        );
        Test.stopTest();
        System.debug('Result: ' + result);
        System.assertNotEquals(null, result, 'Result list should not be null');
        System.assertEquals(1, result.serviceOrderList.size(), 'Expected 1 Service Order');
    }

    @IsTest
    static void HOT_OEBSIntegrationControllerMultipleSOTest() {
        Account acc = [SELECT id FROM Account LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new oebsMultipleSOMock());

        Test.startTest();
        HOT_OEBSIntegrationController.oebsWrapper result = HOT_OEBSIntegrationController.HOT_OEBS_Integration(
            acc.Id,
            'Account',
            'GET_OEBS_SO'
        );
        Test.stopTest();
        System.debug('Result: ' + result);
        System.assertNotEquals(null, result, 'Result list should not be null');
        System.assertEquals(2, result.serviceOrderList.size(), 'Expected 2 Service Order');
    }

    @IsTest
    static void HOT_OEBSIntegrationControllerErrTest() {
        Account acc = [SELECT id, crm_person__c FROM Account LIMIT 1];
        Person__c pers = [SELECT id, INT_fnr__c FROM Person__c LIMIT 1];
        Case cas = [SELECT id, AccountId FROM Case LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new NoDataMock());

        Test.startTest();
        HOT_OEBSIntegrationController.oebsWrapper result = HOT_OEBSIntegrationController.HOT_OEBS_Integration(
            pers.Id,
            'Person__c',
            'GET_OEBS_Brukernr'
        );
        HOT_OEBSIntegrationController.oebsWrapper result2 = HOT_OEBSIntegrationController.HOT_OEBS_Integration(
            cas.Id,
            'Case',
            'GET_OEBS_Brukernr'
        );
        Test.stopTest();
    }

    @IsTest
    static void HOT_OEBSIntegrationControllerErrRespTest() {
        Account acc = [SELECT id FROM Account LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new BadDataMock());

        Test.startTest();
        HOT_OEBSIntegrationController.oebsWrapper result = HOT_OEBSIntegrationController.HOT_OEBS_Integration(
            acc.Id,
            'Account',
            'GET_OEBS_Brukernr'
        );
        HOT_OEBSIntegrationController.oebsWrapper result2 = HOT_OEBSIntegrationController.HOT_OEBS_Integration(
            acc.Id,
            'Account',
            'GET_OEBS_BrukerPass'
        );
        HOT_OEBSIntegrationController.oebsWrapper result3 = HOT_OEBSIntegrationController.HOT_OEBS_Integration(
            acc.Id,
            'Account',
            'GET_OEBS_Ordre'
        );
        HOT_OEBSIntegrationController.oebsWrapper result4 = HOT_OEBSIntegrationController.HOT_OEBS_Integration(
            acc.Id,
            'Account',
            'GET_OEBS_SO'
        );
        HOT_OEBSIntegrationController.oebsWrapper result5 = HOT_OEBSIntegrationController.HOT_OEBS_Integration(
            acc.Id,
            'Account',
            'GET_OEBS_SF'
        );
        Test.stopTest();
    }
    @IsTest
    static void HOT_OEBSIntegrationControllerBlankFnrTest() {
        Account acc = [SELECT id FROM Account WHERE name = 'Test' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new BadDataMock());

        Test.startTest();
        HOT_OEBSIntegrationController.oebsWrapper result = HOT_OEBSIntegrationController.HOT_OEBS_Integration(
            acc.id,
            'Account',
            'GET_OEBS_Brukernr'
        );
        Test.stopTest();
    }

    @IsTest
    static void HOT_OEBSIntegrationControllerBadResponseStatusTest() {
        Account acc = [SELECT id FROM Account LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new badStatusMock());

        Test.startTest();
        HOT_OEBSIntegrationController.oebsWrapper result = HOT_OEBSIntegrationController.HOT_OEBS_Integration(
            acc.Id,
            'Account',
            'GET_OEBS_Brukernr'
        );
        Test.stopTest();
    }

    @IsTest
    static void HOT_OEBSIntegrationControllerConstructorNullParamsTest() {
        // Test passing null lists to parameterized constructor
        HOT_OEBSIntegrationController.oebsWrapper oebs = new HOT_OEBSIntegrationController.oebsWrapper(
            null,
            null,
            null,
            null,
            null
        );

        HOT_OEBSIntegrationController.brukerNrWrapper brukernr = new HOT_OEBSIntegrationController.brukerNrWrapper(
            null,
            null,
            null,
            null
        );

        HOT_OEBSIntegrationController.brukerPassWrapper brukerpass = new HOT_OEBSIntegrationController.brukerPassWrapper(
            null,
            null,
            null,
            null,
            null,
            null,
            null
        );

        HOT_OEBSIntegrationController.orderWrapper order = new HOT_OEBSIntegrationController.orderWrapper(
            null,
            null,
            null,
            null,
            null,
            null,
            null
        );

        HOT_OEBSIntegrationController.orderLineWrapper orderLine = new HOT_OEBSIntegrationController.orderLineWrapper(
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null
        );

        HOT_OEBSIntegrationController.SFWrapper sf = new HOT_OEBSIntegrationController.SFWrapper(
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null
        );

        HOT_OEBSIntegrationController.notatWrapper sfnote = new HOT_OEBSIntegrationController.notatWrapper(
            null,
            null,
            null,
            null
        );

        HOT_OEBSIntegrationController.SOWrapper so = new HOT_OEBSIntegrationController.SOWrapper(
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null
        );

        // Assert fallback initialization
        System.assertNotEquals(null, oebs.orderList, 'orderList should be initialized even when null passed');
        System.assertNotEquals(
            null,
            oebs.serviceRequestList,
            'serviceRequestList should be initialized even when null passed'
        );
        System.assertNotEquals(
            null,
            oebs.serviceOrderList,
            'serviceOrderList should be initialized even when null passed'
        );
    }
}
