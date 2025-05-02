@IsTest
private class HOT_PostAddressControllerTest {
    // Mock for a successful PostAddress response
    private class MockPostAddressSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody(
                '{"status":"200","navn":"Harry Potter",' +
                '"adresse":{"type":"Gate",' +
                '"adresselinje1":"Baker Street 221B","adresselinje2":"","adresselinje3":"","postnummer":"1234",' +
                '"poststed":"Oslo","landkode":"NO","land":"Norge"}}'
            );
            return res;
        }
    }

    @IsTest static void testGetPostAddressAccountSuccess() {
        //--- setup Person + Account ---
        Person__c p = new Person__c(
            Name                = '12345678910',
            INT_FirstName__c    = 'Harry',
            INT_LastName__c     = 'Potter',
            INT_Confidential__c = 'UGRADERT',
            INT_ActorId__c      = '1234567899876'
        );
        insert p;
        Account acct = new Account(
            Name          = 'TestAcc',
            CRM_Person__c = p.Id
        );
        insert acct;

        Test.setMock(HttpCalloutMock.class, new MockPostAddressSuccess());
        Test.startTest();
            HOT_PostAddressController.PostAddress result =
                HOT_PostAddressController.getPostAddress(acct.Id, 'Account');
        Test.stopTest();

        //--- asserts ---
        System.assertNotEquals(null, result, 'Should return a PostAddress');
        System.assertEquals('200',         result.status);
        System.assertEquals('Harry Potter', result.navn);
        System.assertEquals('Gate',        result.type);
        System.assertEquals('Baker Street 221B', result.adresselinje1);
        System.assertEquals('1234',        result.postummer);
        System.assertEquals('Oslo',        result.poststed);
        System.assertEquals('NO',          result.landkode);
        System.assertEquals('Norge',       result.land);
    }

    @IsTest static void testGetPostAddressInvalidObject() {
        Test.startTest();
            HOT_PostAddressController.PostAddress result =
                HOT_PostAddressController.getPostAddress(UserInfo.getUserId(), 'Opportunity');
        Test.stopTest();
        System.assertEquals(null, result, 'Unsupported objectApiName returns null');
    }
}
