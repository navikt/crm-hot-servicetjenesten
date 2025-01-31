@IsTest
private class HOT_HotsakIntegrationControllerTest {
    // Denne mock-klassen simulerer et vanlig, gyldig svar.
    private class HotsakMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String mockResponse =
            '{'+
            '   \"data\": {'+
            '       \"saksoversiktInnbygger\": {'+
            '           \"saker\": ['+
            '               {'+
            '                   \"sakId\": \"123\",'+
            '                   \"saksstatus\": \"Under behandling\",'+
            '                   \"sakstype\": \"Type A\",'+
            '                   \"opprettet\": \"2023-01-01T10:00:00\",'+
            '                   \"endret\": \"2023-01-02T10:00:00\",'+
            '                   \"behovsmelding\": {'+
            '                       \"behovsmeldingId\": \"BM-1\",'+
            '                       \"gjelder\": \"Some info\",'+
            '                       \"mottatt\": \"2023-01-01T09:00:00\"'+
            '                   },'+
            '                   \"hendelser\": ['+
            '                       {'+
            '                           \"sakshendelseId\": \"H-1\",'+
            '                           \"detaljer\": \"details\",'+
            '                           \"hendelse\": \"event\",'+
            '                           \"opprettet\": \"2023-01-01T09:30:00\",'+
            '                           \"saksbehandler\": {'+
            '                               \"epost\": \"test@domain.com\",'+
            '                               \"navn\": \"Tester\",'+
            '                               \"saksbehandlerId\": \"SB-1\"'+
            '                           }'+
            '                       }'+
            '                   ],'+
            '                   \"oppgaver\": ['+
            '                       {'+
            '                           \"feilregistrert\": false,'+
            '                           \"ferdigstilt\": true,'+
            '                           \"oppgaveId\": \"O-1\",'+
            '                           \"oppgavetype\": \"Assignment\",'+
            '                           \"opprettet\": \"2023-01-01T09:45:00\"'+
            '                       }'+
            '                   ],'+
            '                   \"vedtak\": ['+
            '                       {'+
            '                           \"vedtakId\": \"V-1\",'+
            '                           \"vedtaksdato\": \"2023-01-10T00:00:00\",'+
            '                           \"vedtaksstatus\": \"Approved\"'+
            '                       }'+
            '                   ]'+
            '               }'+
            '           ]'+
            '       }'+
            '   }'+
            '}';

            HttpResponse res = new HttpResponse();
            res.setBody(mockResponse);
            res.setStatusCode(200);
            return res;
        }
    }

    // Denne mock-klassen returnerer en JSON-respons uten 'data'-nøkkelen.
    private class NoDataMock implements HttpCalloutMock {
        public HttpResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            return res;
        }
    }
    

    // Denne mock-klassen returnerer en JSON-respons med 'data', men uten 'saksoversiktInnbygger'.
    private class NoSaksoversiktMock implements HttpCalloutMock {
        public HttpResponse respond(HTTPRequest req) {
            String mockResponse =
            '{'+
            '   \"data\": {'+
            '       \"somethingElse\": \"value\"'+
            '   }'+
            '}';
            HttpResponse res = new HttpResponse();
            res.setBody(mockResponse);
            res.setStatusCode(200);
            return res;
        }
    }

    // Denne mock-klassen returnerer en JSON-respons med saksoversiktInnbygger, men uten 'saker'.
    private class NoSakerMock implements HttpCalloutMock {
        public HttpResponse respond(HTTPRequest req) {
            String mockResponse =
            '{'+
            '   \"data\": {'+
            '       \"saksoversiktInnbygger\": {'+
            '           \"somethingElse\": \"val\"'+
            '       }'+
            '   }'+
            '}';
            HttpResponse res = new HttpResponse();
            res.setBody(mockResponse);
            res.setStatusCode(200);
            return res;
        }
    }

    // Denne mock-klassen returnerer en JSON-respons med bare én hendelse (ikke liste).
    private class SingleHendelseMock implements HttpCalloutMock {
        public HttpResponse respond(HTTPRequest req) {
            String mockResponse =
            '{'+
            '  \"data\": {'+
            '    \"saksoversiktInnbygger\": {'+
            '      \"saker\": ['+
            '        {'+
            '          \"sakId\": \"999\",'+
            '          \"hendelser\": {'+  // Én enkelt objekt i stedet for liste.\n
            '            \"sakshendelseId\": \"H-9\",'+
            '            \"detaljer\": \"Noe\",'+
            '            \"hendelse\": \"SingleEvent\",'+
            '            \"opprettet\": \"2024-05-01T10:00:00\"'+
            '          }'+
            '        }'+
            '      ]'+
            '    }'+
            '  }'+
            '}';
            HttpResponse res = new HttpResponse();
            res.setBody(mockResponse);
            res.setStatusCode(200);
            return res;
        }
    }

    // Lignende mock for oppgaver som enkeltobjekt.
    private class SingleOppgaveMock implements HttpCalloutMock {
        public HttpResponse respond(HTTPRequest req) {
            String mockResponse =
            '{'+
            '  \"data\": {'+
            '    \"saksoversiktInnbygger\": {'+
            '      \"saker\": ['+
            '        {'+
            '          \"sakId\": \"888\",'+
            '          \"oppgaver\": {'+  // Én enkelt oppgave.\n
            '            \"feilregistrert\": true,'+
            '            \"ferdigstilt\": false,'+
            '            \"oppgaveId\": \"O-9\",'+
            '            \"oppgavetype\": \"SingleOppgaveType\",'+
            '            \"opprettet\": \"2025-01-01T12:00:00\"'+
            '          }'+
            '        }'+
            '      ]'+
            '    }'+
            '  }'+
            '}';
            HttpResponse res = new HttpResponse();
            res.setBody(mockResponse);
            res.setStatusCode(200);
            return res;
        }
    }

    // Lignende mock for vedtak som enkeltobjekt.
    private class SingleVedtakMock implements HttpCalloutMock {
        public HttpResponse respond(HTTPRequest req) {
            String mockResponse =
            '{'+
            '  \"data\": {'+
            '    \"saksoversiktInnbygger\": {'+
            '      \"saker\": ['+
            '        {'+
            '          \"sakId\": \"777\",'+
            '          \"vedtak\": {'+  // Én enkelt vedtak.\n
            '            \"vedtakId\": \"V-9\",'+
            '            \"vedtaksdato\": \"2023-12-01T00:00:00\",'+
            '            \"vedtaksstatus\": \"SingleStatus\"'+
            '          }'+
            '        }'+
            '      ]'+
            '    }'+
            '  }'+
            '}';
            HttpResponse res = new HttpResponse();
            res.setBody(mockResponse);
            res.setStatusCode(200);
            return res;
        }
    }

    // -------------------------------------------------------------
    // TESTER
    // -------------------------------------------------------------

    // Test 1: Standard gyldig respons.
    @IsTest
    static void testGetSaker_StandardMock() {
        Test.setMock(HttpCalloutMock.class, new HotsakMock());
        Test.startTest();
        List<HOT_HotsakIntegrationController.SakWrapper> result =
            HOT_HotsakIntegrationController.getSaker('12345678910');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result list should not be null');
        System.assertEquals(1, result.size(), 'Expected 1 sak record');
    }

    // Test 2: Respons uten data-nøkkel.
    @IsTest
    static void testGetSaker_NoData() {
        Test.setMock(HttpCalloutMock.class, new NoDataMock());
        Test.startTest();
        List<HOT_HotsakIntegrationController.SakWrapper> result =
            HOT_HotsakIntegrationController.getSaker('12345678910');
        Test.stopTest();

        // Forventer tom liste, siden dataMap blir null.
        System.assertNotEquals(null, result, 'Result list should not be null');
        System.assertEquals(0, result.size(), 'Expected 0 sak records');
    }

    // Test 3: Respons med data, men uten 'saksoversiktInnbygger'.
    @IsTest
    static void testGetSaker_NoSaksoversikt() {
        Test.setMock(HttpCalloutMock.class, new NoSaksoversiktMock());
        Test.startTest();
        List<HOT_HotsakIntegrationController.SakWrapper> result =
            HOT_HotsakIntegrationController.getSaker('12345678910');
        Test.stopTest();

        // Forventer tom liste.
        System.assertNotEquals(null, result);
        System.assertEquals(0, result.size());
    }

    // Test 4: Respons med saksoversiktInnbygger, men uten 'saker'.
    @IsTest
    static void testGetSaker_NoSaker() {
        Test.setMock(HttpCalloutMock.class, new NoSakerMock());
        Test.startTest();
        List<HOT_HotsakIntegrationController.SakWrapper> result =
            HOT_HotsakIntegrationController.getSaker('12345678910');
        Test.stopTest();

        // Forventer tom liste.
        System.assertNotEquals(null, result);
        System.assertEquals(0, result.size());
    }

    // Test 5: Én enkelt hendelse i stedet for liste.
    @IsTest
    static void testGetSaker_SingleHendelse() {
        Test.setMock(HttpCalloutMock.class, new SingleHendelseMock());
        Test.startTest();
        List<HOT_HotsakIntegrationController.SakWrapper> result =
            HOT_HotsakIntegrationController.getSaker('12345678910');
        Test.stopTest();

        // Verifiser at sakene ikke er null og at vi faktisk fikk 1 sak.
        System.assertNotEquals(null, result);
        System.assertEquals(1, result.size());
        // Sjekk at hendelser ble parslet til én i stedet for 0.
        System.assertEquals(1, result[0].hendelser.size(), 'Forventet én hendelse selv om JSON ikke var en liste');
    }

    // Test 6: Én enkelt oppgave i stedet for liste.
    @IsTest
    static void testGetSaker_SingleOppgave() {
        Test.setMock(HttpCalloutMock.class, new SingleOppgaveMock());
        Test.startTest();
        List<HOT_HotsakIntegrationController.SakWrapper> result =
            HOT_HotsakIntegrationController.getSaker('12345678910');
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(1, result.size());
        // Forventer nøyaktig én oppgave.
        System.assertEquals(1, result[0].oppgaver.size(), 'Forventet én oppgave fra singleObject JSON');
    }

    // Test 7: Én enkelt vedtak i stedet for liste.
    @IsTest
    static void testGetSaker_SingleVedtak() {
        Test.setMock(HttpCalloutMock.class, new SingleVedtakMock());
        Test.startTest();
        List<HOT_HotsakIntegrationController.SakWrapper> result =
            HOT_HotsakIntegrationController.getSaker('12345678910');
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(1, result.size());
        // Forventer nøyaktig ett vedtak.
        System.assertEquals(1, result[0].vedtak.size(), 'Forventet ett vedtak fra singleObject JSON');
    }
}
