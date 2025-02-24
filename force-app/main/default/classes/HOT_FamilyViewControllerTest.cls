@IsTest
private class HOT_FamilyViewControllerTest {
    @IsTest
    private static void getRelationsTest() {
        Person__c testPerson = new Person__c(
            Name = '12106519356',
            INT_LastName__c = 'TestName',
            INT_FirstName__c = 'TestLastname'
        );
        insert testPerson;

        Account testAccount = new Account(CRM_Person__c = testPerson.Id, Name = 'testName');
        insert testAccount;

        Case testCase = new Case(AccountId = testAccount.Id);
        insert testCase;

        LiveChatVisitor testChatVisitor = new LiveChatVisitor();
        insert testChatVisitor;

        LiveChatTranscript testChat = new LiveChatTranscript();
        testChat.LiveChatVisitorid = testChatVisitor.id;
        testChat.AccountId = testAccount.Id;
        insert testChat;

        Test.startTest();
        List<HOT_FamilyViewController.Relation> testRelation1 = HOT_FamilyViewController.getRelations(
            testAccount.Id,
            'Account'
        );
        List<HOT_FamilyViewController.Relation> testRelation2 = HOT_FamilyViewController.getRelations(
            testCase.Id,
            'Case'
        );
        List<HOT_FamilyViewController.Relation> testRelation3 = HOT_FamilyViewController.getRelations(
            testChat.Id,
            'LiveChatTranscript'
        );
        Test.stopTest();

        System.assertEquals(false, testRelation1.isEmpty());
        System.assertEquals(false, testRelation2.isEmpty());
        System.assertEquals(false, testRelation3.isEmpty());
    }

    @IsTest
    private static void getMaritalStatusTest() {
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_QueryHelper query = new PDL_API_QueryHelper('12106519356');
        List<HOT_FamilyViewController.Relation> l = HOT_FamilyViewController.getMaritalStatus(
            query.execute(),
            new HOT_FamilyViewController.Relation()
        );
        System.assertEquals('UGIFT', l[0].role);
        String giftPerson =
            '{' +
            '"data" : {' +
            '"hentPerson" : {' +
            '"sivilstand" : [ {' +
            '"type" : "GIFT",' +
            '"relatertVedSivilstand" : "02091379875",' +
            '"gyldigFraOgMed" : "2021-09-02",' +
            '"bekreftelsesdato" : null' +
            '} ]' +
            '}' +
            '}' +
            '}';
        PDL_API_Response response = (PDL_API_Response) System.JSON.deserialize(giftPerson, PDL_API_Response.class);
        l = HOT_FamilyViewController.getMaritalStatus(response, new HOT_FamilyViewController.Relation());
        System.assertEquals('GIFT', l[0].role);
        giftPerson = '{' + '"data" : {' + '"hentPerson" : {' + '"sivilstand" : []' + '}' + '}' + '}';
        response = (PDL_API_Response) System.JSON.deserialize(giftPerson, PDL_API_Response.class);
        l = HOT_FamilyViewController.getMaritalStatus(response, new HOT_FamilyViewController.Relation());
        System.assertEquals('UOPPGITT', l[0].role);
        giftPerson =
            '{' +
            '"data" : {' +
            '"hentPerson" : {' +
            '"sivilstand" : [ {' +
            '"type" : "SKILT",' +
            '"relatertVedSivilstand" : "02091379875",' +
            '"gyldigFraOgMed" : "2021-09-02",' +
            '"bekreftelsesdato" : null' +
            '} ]' +
            '}' +
            '}' +
            '}';
        response = (PDL_API_Response) System.JSON.deserialize(giftPerson, PDL_API_Response.class);
        l = HOT_FamilyViewController.getMaritalStatus(response, new HOT_FamilyViewController.Relation());
        System.assertEquals('02.09.2021', l[0].eventDate);
    }

    @IsTest
    private static void isOver21Test() {
        String personWithAge =
            '{' +
            '"data" : {' +
            '"hentPerson" : {' +
            '"foedselsdato" : [ {' +
            '"foedselsdato" : "1965-10-12",' +
            '"foedselsaar" : 1965,' +
            '"foedested" : "Fødested i/på Gjemnes",' +
            '"foedeland" : "NOR",' +
            '"foedekommune" : null' +
            '} ]' +
            '}' +
            '}' +
            '}';
        PDL_API_Response response = (PDL_API_Response) System.JSON.deserialize(personWithAge, PDL_API_Response.class);
        System.assertEquals(true, HOT_FamilyViewController.isOver21(response));
        personWithAge =
            '{' +
            '"data" : {' +
            '"hentPerson" : {' +
            '"sivilstand" : [ {' +
            '"type" : "GIFT",' +
            '"relatertVedSivilstand" : "02091379875",' +
            '"gyldigFraOgMed" : "2021-09-02",' +
            '"bekreftelsesdato" : null' +
            '} ]' +
            '}' +
            '}' +
            '}';
        response = (PDL_API_Response) System.JSON.deserialize(personWithAge, PDL_API_Response.class);
        System.assertEquals(false, HOT_FamilyViewController.isOver21(response));
    }

    @IsTest
    private static void getChildrenTest() {
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_QueryHelper query = new PDL_API_QueryHelper('12106519356');
        List<HOT_FamilyViewController.Relation> l = HOT_FamilyViewController.getChildren(
            query.execute(),
            new HOT_FamilyViewController.Relation()
        );
        System.assertEquals(0, l.size());
    }

    @IsTest
    private static void queryRelationsFromPDL() {
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_Response r = HOT_FamilyViewController.queryRelationsFromPDL('12106519356');
        System.assertEquals(1965, r.data?.hentPerson?.foedsel[0]?.foedselsaar);
    }

    @IsTest
    private static void queryMaritalStatusFromPDL() {
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_Response r = HOT_FamilyViewController.queryMaritalStatusFromPDL('12106519356');
        System.assertEquals(1965, r.data?.hentPerson?.foedsel[0]?.foedselsaar);
    }

    @IsTest
    private static void hasSameAddressTest() {
        String PersonWithAddress =
            '{' +
            '"errors" : null,' +
            '"data" : {' +
            '"hentPerson" : {' +
            '"bostedsadresse" : [ {' +
            '"vegadresse" : {' +
            '"tilleggsnavn" : "abrakadabra",' +
            '"postnummer" : "6636",' +
            '"matrikkelId" : 130534152,' +
            '"koordinater" : {' +
            '"z" : 0.0,' +
            '"y" : 6974511.0,' +
            '"x" : 453529.0,' +
            '"kvalitet" : null' +
            '},' +
            '"kommunenummer" : "1557",' +
            '"husnummer" : "1",' +
            '"husbokstav" : "A",' +
            '"bydelsnummer" : "2435",' +
            '"bruksenhetsnummer" : "555",' +
            '"adressenavn" : "Plassavegen"' +
            '}' +
            '} ],' +
            '"deltbosted" : [ {' +
            '"vegadresse" : {' +
            '"tilleggsnavn" : "abrakadabra",' +
            '"postnummer" : "6636",' +
            '"matrikkelId" : 130534152,' +
            '"koordinater" : {' +
            '"z" : 0.0,' +
            '"y" : 6974511.0,' +
            '"x" : 453529.0,' +
            '"kvalitet" : null' +
            '},' +
            '"kommunenummer" : "1557",' +
            '"husnummer" : "1",' +
            '"husbokstav" : "A",' +
            '"bydelsnummer" : "2435",' +
            '"bruksenhetsnummer" : "555",' +
            '"adressenavn" : "Plassavegen"' +
            '}' +
            '} ]' +
            '}' +
            '}' +
            '}';
        Person__c p = new Person__c(
            INT_ActorId__c = '100003000120',
            Name = '12345678910',
            INT_Confidential__c = 'UGRADERT',
            INT_FirstName__c = 'Harry',
            INT_IsNavEmployee__c = true,
            INT_LastName__c = 'Potter',
            INT_DateOfDeath__c = Date.valueOf('2022-12-31'),
            INT_ResidentialAddress__c = 'Plassavegen 1 A',
            INT_AddressMunicipalityNumber__c = '1557',
            INT_AddressDistrictNumber__c = '2435',
            INT_ResidentialZipCode__c = '6636'
        );
        String PersonWithoutAddress =
            '{' +
            '"errors" : null,' +
            '"data" : {' +
            '"hentPerson" : {' +
            '"bostedsadresse" : [ {' +
            '"vegadresse" : {' +
            '"tilleggsnavn" : null,' +
            '"postnummer" : null,' +
            '"matrikkelId" : null,' +
            '"kommunenummer" : null,' +
            '"husnummer" : null,' +
            '"husbokstav" : null,' +
            '"bydelsnummer" : null,' +
            '"bruksenhetsnummer" : null,' +
            '"adressenavn" : null' +
            '}' +
            '} ]' +
            '}' +
            '}' +
            '}';
        PDL_API_Response wAddress = (PDL_API_Response) System.JSON.deserialize(
            PersonWithAddress,
            PDL_API_Response.class
        );
        PDL_API_Response woAddress = (PDL_API_Response) System.JSON.deserialize(
            PersonWithoutAddress,
            PDL_API_Response.class
        );
        System.assertEquals(false, HOT_FamilyViewController.hasSameAddress(wAddress, woAddress));
        System.assertEquals(false, HOT_FamilyViewController.hasSameAddress(woAddress, wAddress));
        System.assertEquals(false, HOT_FamilyViewController.hasSameAddress(woAddress, woAddress));
        System.assertEquals(true, HOT_FamilyViewController.hasSameAddress(wAddress, wAddress));
        System.assertEquals(true, HOT_FamilyViewController.hasSameAddress(wAddress, p));
        System.assertEquals(true, HOT_FamilyViewController.hasSameAddress(p, wAddress));
        PDL_API_Response n;
        System.assertEquals(false, HOT_FamilyViewController.hasSameAddress(wAddress, n));
        System.assertEquals(false, HOT_FamilyViewController.hasSameAddress(n, wAddress));
        System.assertEquals(false, HOT_FamilyViewController.hasSameAddress(n, p));
        System.assertEquals(false, HOT_FamilyViewController.hasSameAddress(p, n));
    }

    @IsTest
    private static void compareDatesTest() {
        Date d1 = Date.valueOf('2022-01-01');
        Date d2 = Date.valueOf('2000-01-01');
        System.assertEquals(true, HOT_FamilyViewController.compareDates(d1, d2) > 0);
        d1 = Date.valueOf('2000-01-01');
        d2 = Date.valueOf('2022-01-01');
        System.assertEquals(true, HOT_FamilyViewController.compareDates(d1, d2) < 0);
        d1 = Date.valueOf('2000-01-01');
        d2 = Date.valueOf('2000-01-01');
        System.assertEquals(true, HOT_FamilyViewController.compareDates(d1, d2) == 0);
        System.assertEquals(true, HOT_FamilyViewController.compareDates(null, null) == 0);
        System.assertEquals(true, HOT_FamilyViewController.compareDates(d1, null) > 0);
        System.assertEquals(true, HOT_FamilyViewController.compareDates(null, d2) < 0);
    }

    @IsTest
    private static void formatDateTest() {
        Date d = Date.valueOf('2022-01-01');
        System.assertEquals('01.01.2022', HOT_FamilyViewController.formatDate(d));
        System.assertEquals(null, HOT_FamilyViewController.formatDate(null));
    }

    @IsTest
    private static void getResponsibilityTest() {
        String parentString =
            '{' +
            '"errors" : null,' +
            '"data" : {' +
            '"hentIdenter" : {' +
            '"identer" : [ { "ident" : "10987654321" },  { "ident" : "11109876543" } ]' +
            '},' +
            '"hentPerson" : {' +
            '"foreldreansvar" : [ {"ansvar":"far","ansvarlig":null,"ansvarssubjekt":"12345678910"}, {"ansvar":"felles","ansvarlig":null,"ansvarssubjekt":"11122233345"} ]' +
            '}' +
            '}' +
            '}';
        String childString1 =
            '{' +
            '"errors" : null,' +
            '"data" : {' +
            '"hentIdenter" : {' +
            '"identer" : [ { "ident" : "12345678910" }, { "ident" : "34567891011" } ]' +
            '},' +
            '"hentPerson" : {' +
            '"foreldreansvar" : [ {"ansvar":"far","ansvarlig":10987654321,"ansvarssubjekt":null} ]' +
            '}' +
            '}' +
            '}';

        String childString2 =
            '{' +
            '"errors" : null,' +
            '"data" : {' +
            '"hentIdenter" : {' +
            '"identer" : [ { "ident" : "90876543212" }, { "ident" : "11122233345" } ]' +
            '},' +
            '"hentPerson" : {' +
            '"foreldreansvar" : [ {"ansvar":"felles","ansvarlig":11109876543,"ansvarssubjekt":"null"} ]' +
            '}' +
            '}' +
            '}';
        PDL_API_Response parent = (PDL_API_Response) System.JSON.deserialize(parentString, PDL_API_Response.class);
        PDL_API_Response child1 = (PDL_API_Response) System.JSON.deserialize(childString1, PDL_API_Response.class);
        PDL_API_Response child2 = (PDL_API_Response) System.JSON.deserialize(childString2, PDL_API_Response.class);

        System.assertEquals('far', HOT_FamilyViewController.getResponsibility(parent, child1));
        System.assertEquals('far', HOT_FamilyViewController.getResponsibility(parent, '12345678910'));
        System.assertEquals('felles', HOT_FamilyViewController.getResponsibility(parent, '11122233345'));
        System.assertEquals(null, HOT_FamilyViewController.getResponsibility(parent, '12345678911'));
        System.assertEquals('far', HOT_FamilyViewController.getResponsibility('10987654321', child1));
        System.assertEquals('felles', HOT_FamilyViewController.getResponsibility('11109876543', child2));
        System.assertEquals(null, HOT_FamilyViewController.getResponsibility('23450987612', child2));
    }

    @IsTest
    private static void getDateOfDeathTest() {
        String deadPerson =
            '{' +
            '"errors" : null,' +
            '"data" : {' +
            '"hentPerson" : {' +
            '"doedsfall" : [ { "doedsdato" : "2021-09-02" } ]' +
            '}' +
            '}' +
            '}';
        PDL_API_Response dead = (PDL_API_Response) System.JSON.deserialize(deadPerson, PDL_API_Response.class);
        String r = HOT_FamilyViewController.getDateOfDeath(dead);
        System.assertEquals('02.09.2021', r);
        String deadNullPerson =
            '{' +
            '"errors" : null,' +
            '"data" : {' +
            '"hentPerson" : {' +
            '"doedsfall" : [ { "doedsdato" : null } ]' +
            '}' +
            '}' +
            '}';
        dead = (PDL_API_Response) System.JSON.deserialize(deadNullPerson, PDL_API_Response.class);
        r = HOT_FamilyViewController.getDateOfDeath(dead);
        System.assertEquals(null, r);
        Person__c p = new Person__c(
            INT_ActorId__c = '100003000120',
            Name = '12345678910',
            INT_Confidential__c = 'UGRADERT',
            INT_FirstName__c = 'Harry',
            INT_IsNavEmployee__c = true,
            INT_LastName__c = 'Potter',
            INT_DateOfDeath__c = Date.valueOf('2022-12-31')
        );
        r = HOT_FamilyViewController.getDateOfDeath(p);
        System.assertEquals('31.12.2022', r);
    }

    @IsTest
    private static void getAgeDateTest() {
        String person =
            '{' +
            '"data" : {' +
            '"hentPerson" : {"foedselsdato" : [{"foedselsaar":"2023"}],"doedsfall" : [{"doedsdato" : "2023-01-2"}]}' +
            '}' +
            '}';
        PDL_API_Response response = (PDL_API_Response) System.JSON.deserialize(person, PDL_API_Response.class);
        Date result = HOT_FamilyViewController.getAgeDate(response);
        System.assertEquals(Date.valueOf('0001-01-02'), result);
        person = '{' + '"data" : {' + '"hentPerson" : {"foedselsdato" : [{}]}' + '}' + '}';
        response = (PDL_API_Response) System.JSON.deserialize(person, PDL_API_Response.class);
        result = HOT_FamilyViewController.getAgeDate(response);
        System.assertEquals(null, result);
        Person__c p = new Person__c(
            INT_ActorId__c = '100003000120',
            Name = '12345678910',
            INT_Confidential__c = 'UGRADERT',
            INT_FirstName__c = 'Harry',
            INT_IsNavEmployee__c = true,
            INT_LastName__c = 'Potter',
            INT_DateOfBirth__c = '2021-12-31',
            INT_DateOfDeath__c = Date.valueOf('2022-12-31')
        );
        result = HOT_FamilyViewController.getAgeDate(p);
        System.assertEquals(Date.valueOf('0002-01-01'), result);
    }

    @IsTest
    private static void getAgeStringTest() {
        Date d = Date.valueOf('0001-01-02');
        String result = HOT_FamilyViewController.getAgeString(d);
        System.assertEquals('1 d', result);

        d = Date.valueOf('0001-02-01');
        result = HOT_FamilyViewController.getAgeString(d);
        System.assertEquals('1 mnd', result);

        d = Date.valueOf('0002-01-01');
        result = HOT_FamilyViewController.getAgeString(d);
        System.assertEquals('12 mnd', result);

        d = Date.valueOf('0002-12-01');
        result = HOT_FamilyViewController.getAgeString(d);
        System.assertEquals('23 mnd', result);

        d = Date.valueOf('0003-01-01');
        result = HOT_FamilyViewController.getAgeString(d);
        System.assertEquals('2 år', result);

        d = Date.valueOf('0004-01-01');
        result = HOT_FamilyViewController.getAgeString(d);
        System.assertEquals('3 år', result);
    }

    @IsTest
    private static void getConfidentialStatusTest() {
        String person =
            '{' +
            '"data" : {' +
            '"hentPerson" : {"adressebeskyttelse" : [{"gradering" : "UGRADERT"}]}' +
            '}' +
            '}';
        PDL_API_Response response = (PDL_API_Response) System.JSON.deserialize(person, PDL_API_Response.class);
        String result = HOT_FamilyViewController.getConfidentialStatus(response);
        System.assertEquals('UGRADERT', result);
    }

    @IsTest
    private static void isConfidentialRelationTest() {
        String person =
            '{' +
            '"data" : {' +
            '"hentPerson" : {"adressebeskyttelse" : [{"gradering" : "UGRADERT"}]}' +
            '}' +
            '}';
        PDL_API_Response personResponse = (PDL_API_Response) System.JSON.deserialize(person, PDL_API_Response.class);
        String relation =
            '{' +
            '"data" : {' +
            '"hentPerson" : {"adressebeskyttelse" : [{"gradering" : "UGRADERT"}]}' +
            '}' +
            '}';
        PDL_API_Response relationResponse = (PDL_API_Response) System.JSON.deserialize(
            relation,
            PDL_API_Response.class
        );
        Boolean result = HOT_FamilyViewController.isConfidentialRelation(personResponse, relationResponse);
        System.assertEquals(false, result);
        result = HOT_FamilyViewController.isConfidentialRelation('UGRADERT', 'FORTROLIG');
        System.assertEquals(true, result);
    }

    @IsTest
    private static void isUnauthrizedTest() {
        PDL_API_Response response = (PDL_API_Response) System.JSON.deserialize(
            unauthorizedPerson,
            PDL_API_Response.class
        );
        System.assertEquals(true, HOT_FamilyViewController.isUnauthorized(response));
        response = (PDL_API_Response) System.JSON.deserialize(testPerson1, PDL_API_Response.class);
        System.assertEquals(false, HOT_FamilyViewController.isUnauthorized(response));
    }

    @IsTest
    private static void fillRelationFromResponseTest() {
        HOT_FamilyViewController.Relation r = new HOT_FamilyViewController.Relation();
        PDL_API_Response response = (PDL_API_Response) System.JSON.deserialize(
            unauthorizedPerson,
            PDL_API_Response.class
        );
        response = (PDL_API_Response) System.JSON.deserialize(testPerson1, PDL_API_Response.class);
        HOT_FamilyViewController.fillRelationFromResponse(r, response);
        System.assertEquals('MANN', r.sex);
        r = null;
        response = null;
        HOT_FamilyViewController.fillRelationFromResponse(r, response);
        System.assertEquals(null, r);
    }

    @IsTest
    private static void fillRelationFromPersonTest() {
        HOT_FamilyViewController.Relation r = new HOT_FamilyViewController.Relation();
        Person__c p = new Person__c();
        p.INT_AddressMunicipalityNumber__c = null;
        p.INT_AddressDistrictNumber__c = null;
        p.INT_IsNavEmployee__c = null;
        p.INT_Confidential__c = null;
        p.INT_DateOfBirth__c = null;
        p.INT_DateOfDeath__c = null;
        p.INT_FirstName__c = 'Name';
        p.INT_ResidentialZipCode__c = '6868';
        p.INT_Sex__c = 'Kvinne';
        p.INT_ResidentialAddress__c = null;
        HOT_FamilyViewController.fillRelationFromPerson(r, p);
        System.assertEquals('Kvinne', r.sex);
        System.assertEquals(false, r.employee);
        p = null;
        HOT_FamilyViewController.fillRelationFromPerson(r, p);
        System.assertEquals('Kvinne', r.sex);
    }

    @IsTest
    private static void getPersonTest() {
        Person__c p = new Person__c(
            INT_ActorId__c = '100003000120',
            Name = '12345678910',
            INT_Confidential__c = 'UGRADERT',
            INT_FirstName__c = 'Harry',
            INT_IsNavEmployee__c = true,
            INT_LastName__c = 'Potter'
        );
        insert p;
        Set<String> identsList = new Set<String>();
        identsList.add(p.Name);
        Person__c result = HOT_FamilyViewController.getPerson(identsList);
        System.assertEquals(p.INT_Confidential__c, result.INT_Confidential__c);
        result = HOT_FamilyViewController.getPerson(null);
        System.assertEquals(null, result);
    }

    @IsTest
    private static void getFullNameTest() {
        String person = '{' + '"data" : {' + '"hentPerson" : {}' + '}' + '}';
        PDL_API_Response response = (PDL_API_Response) System.JSON.deserialize(person, PDL_API_Response.class);
        String result = HOT_FamilyViewController.getFullName(response);
        System.assertEquals(null, result);
        person = '{' + '"data" : {' + '"hentPerson" : {"navn" : [{}]}' + '}' + '}';
        response = (PDL_API_Response) System.JSON.deserialize(person, PDL_API_Response.class);
        result = HOT_FamilyViewController.getFullName(response);
        System.assertEquals(null, result);
        person = '{' + '"data" : {' + '"hentPerson" : {"navn" : [{"fornavn" : " "}]}' + '}' + '}';
        response = (PDL_API_Response) System.JSON.deserialize(person, PDL_API_Response.class);
        result = HOT_FamilyViewController.getFullName(response);
        System.assertEquals(null, result);
    }

    @IsTest
    private static void getBirthdateTest() {
        String person = '{' + '"data" : {' + '"hentPerson" : {"foedsel" : []}' + '}' + '}';
        PDL_API_Response response = (PDL_API_Response) System.JSON.deserialize(person, PDL_API_Response.class);
        String result = HOT_FamilyViewController.getBirthdate(response);
        System.assertEquals(null, result);
        person = '{' + '"data" : {' + '"hentPerson" : {"foedsel" : [{}]}' + '}' + '}';
        response = (PDL_API_Response) System.JSON.deserialize(person, PDL_API_Response.class);
        result = HOT_FamilyViewController.getBirthdate(response);
        System.assertEquals(null, result);
        Person__c p = new Person__c(
            INT_ActorId__c = '100003000120',
            Name = '12345678910',
            INT_Confidential__c = 'UGRADERT',
            INT_FirstName__c = 'Harry',
            INT_IsNavEmployee__c = true,
            INT_LastName__c = 'Potter',
            INT_DateOfBirth__c = '2022-12-31'
        );
        result = HOT_FamilyViewController.getBirthdate(p);
        System.assertEquals('31.12.2022', result);
    }

    @IsTest
    private static void isNavEmployeeTest() {
        Person__c p = new Person__c(
            INT_ActorId__c = '2762473496911',
            Name = '12345678910',
            INT_Confidential__c = 'UGRADERT',
            INT_FirstName__c = 'Harry',
            INT_IsNavEmployee__c = true,
            INT_LastName__c = 'Potter'
        );
        insert p;
        String person =
            '{' +
            '"data" : {' +
            '"hentPerson" : {},' +
            '"hentIdenter" : {' +
            '"identer" : [ {' +
            '"ident" : "12345678910",' +
            '"historisk" : false,' +
            '"gruppe" : "FOLKEREGISTERIDENT"' +
            '}, {' +
            '"ident" : "2762473496911",' +
            '"historisk" : false,' +
            '"gruppe" : "AKTORID"' +
            '} ]' +
            '}' +
            '}' +
            '}';
        PDL_API_Response response = (PDL_API_Response) System.JSON.deserialize(person, PDL_API_Response.class);
        Boolean result = HOT_FamilyViewController.isNavEmployee(response);
        System.assertEquals(true, result);
        result = HOT_FamilyViewController.isNavEmployee('12345678910');
        System.assertEquals(true, result);
        result = HOT_FamilyViewController.isNavEmployee('12345678911');
        System.assertEquals(false, result);
    }

    @IsTest
    private static void isVisibleTest() {
        Person__c p = new Person__c(
            INT_ActorId__c = '2762473496911',
            Name = '12345678910',
            INT_Confidential__c = 'UGRADERT',
            INT_FirstName__c = 'Harry',
            INT_IsNavEmployee__c = true,
            INT_LastName__c = 'Potter'
        );
        insert p;
        HOT_FamilyViewController.Relation r = new HOT_FamilyViewController.Relation();
        r.confidentialStatus = 'UGRADERT';
        Boolean result = HOT_FamilyViewController.isVisible(r, p);
        System.assertEquals(true, result);
        result = HOT_FamilyViewController.isVisible(r, null);
        System.assertEquals(false, result);
        p.INT_Confidential__c = 'FORTROLIG';
        result = HOT_FamilyViewController.isVisible(r, p);
        System.assertEquals(false, result);
    }

    @IsTest
    private static void getParentsTest() {
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_Response response = (PDL_API_Response) System.JSON.deserialize(
            withParentsPerson,
            PDL_API_Response.class
        );
        List<HOT_FamilyViewController.Relation> parents = HOT_FamilyViewController.getParents(
            response,
            new HOT_FamilyViewController.Relation()
        );
        System.assertEquals(1, parents.size());
    }

    @IsTest
    private static void getStillBornsTest() {
        String hasStillBorn =
            '{' +
            '"data" : {' +
            '"hentPerson" : {' +
            '"doedfoedtBarn" : [ {' +
            '"dato" : "2021-09-02"' +
            '},' +
            '{' +
            '"dato" : "2020-09-02"' +
            '} ]' +
            '}' +
            '}' +
            '}';
        PDL_API_Response response = (PDL_API_Response) System.JSON.deserialize(hasStillBorn, PDL_API_Response.class);
        List<HOT_FamilyViewController.Relation> l = HOT_FamilyViewController.getStillBorns(response);
        System.assertEquals(2, l.size());
        hasStillBorn = '{' + '"data" : {' + '"hentPerson" : {' + '"doedfoedtBarn" : []' + '}' + '}' + '}';
        response = (PDL_API_Response) System.JSON.deserialize(hasStillBorn, PDL_API_Response.class);
        l = HOT_FamilyViewController.getStillBorns(response);
        System.assertEquals(0, l.size());
        hasStillBorn = '{' + '"data" : {' + '"hentPerson" : null' + '}' + '}';
        response = (PDL_API_Response) System.JSON.deserialize(hasStillBorn, PDL_API_Response.class);
        l = HOT_FamilyViewController.getStillBorns(response);
        System.assertEquals(0, l.size());
    }

    /*
    @IsTest
    private static void testjson(){
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_QueryHelper query = new PDL_API_QueryHelper('12106519356');
        String s = JSON.serializePretty(query.execute());
        System.debug(s);
    }
    */
    static final String unauthorizedPerson =
        '{' +
        '"errors" :[' +
        '{' +
        '"message": "Ikke tilgang til å se person",' +
        '"locations": [' +
        '{' +
        '"line": 2,' +
        '"column": 5' +
        '}' +
        '],' +
        '"path": [' +
        '"hentPerson"' +
        '],' +
        '"extensions": {' +
        '"code": "unauthorized",' +
        '"details": {' +
        '"type": "abac-deny",' +
        '"cause": "cause-0001-manglerrolle",' +
        '"policy": "adressebeskyttelse_strengt_fortrolig_adresse"' +
        '},' +
        '"classification": "ExecutionAborted"' +
        '}' +
        '}' +
        '],' +
        '"data" : {' +
        '"hentPerson" : {' +
        '"sikkerhetstiltak" : [ ],' +
        '"navn" : [ {' +
        '"mellomnavn" : "SLØVENDE",' +
        '"gyldigFraOgMed" : "2021-09-02",' +
        '"fornavn" : "VAKKER",' +
        '"forkortetNavn" : "SNERK VAKKER SLØVENDE",' +
        '"etternavn" : "SNERK"' +
        '} ],' +
        '"folkeregisteridentifikator" : [ {' +
        '"type" : "FNR",' +
        '"status" : "I_BRUK",' +
        '"identifikasjonsnummer" : "12106519356"' +
        '} ],' +
        '"adressebeskyttelse" : [ ]' +
        '}' +
        '}' +
        '}';
    static final String emptyPerson = '{' + '"errors" : null,' + '"data" : null' + '}';
    static final String testPerson1 =
        '{' +
        '"errors" : null,' +
        '"data" : {' +
        '"hentPerson" : {' +
        '"sivilstand" : [ {' +
        '"type" : "UGIFT",' +
        '"relatertVedSivilstand" : null,' +
        '"gyldigFraOgMed" : null,' +
        '"bekreftelsesdato" : null' +
        '} ],' +
        '"sikkerhetstiltak" : [ ],' +
        '"oppholdsadresse" : [ ],' +
        '"opphold" : [ ],' +
        '"navn" : [ {' +
        '"mellomnavn" : "SLØVENDE",' +
        '"gyldigFraOgMed" : "2021-09-02",' +
        '"fornavn" : "VAKKER",' +
        '"forkortetNavn" : "SNERK VAKKER SLØVENDE",' +
        '"etternavn" : "SNERK"' +
        '} ],' +
        '"kjoenn" : [ {' +
        '"kjoenn" : "MANN"' +
        '} ],' +
        '"foreldreansvar" : [ {' +
        '"ansvarssubjekt" : "02091379875",' +
        '"ansvarligUtenIdentifikator" : null,' +
        '"ansvarlig" : null,' +
        '"ansvar" : "far"' +
        '} ],' +
        '"forelderBarnRelasjon" : [ {' +
        '"relatertPersonsRolle" : "BARN",' +
        '"relatertPersonsIdent" : "02091379875",' +
        '"minRolleForPerson" : "FAR"' +
        '} ],' +
        '"folkeregisterpersonstatus" : [ {' +
        '"status" : "bosatt",' +
        '"forenkletStatus" : "bosattEtterFolkeregisterloven"' +
        '} ],' +
        '"folkeregisteridentifikator" : [ {' +
        '"type" : "FNR",' +
        '"status" : "I_BRUK",' +
        '"identifikasjonsnummer" : "12106519356"' +
        '} ],' +
        '"foedsel" : [ {' +
        '"foedselsdato" : "1965-10-12",' +
        '"foedselsaar" : 1965,' +
        '"foedested" : "Fødested i/på Gjemnes",' +
        '"foedeland" : "NOR",' +
        '"foedekommune" : null' +
        '} ],' +
        '"falskIdentitet" : null,' +
        '"doedsfall" : [ ],' +
        '"doedfoedtBarn" : [ ],' +
        '"deltBosted" : [ ],' +
        '"bostedsadresse" : [ {' +
        '"vegadresse" : {' +
        '"tilleggsnavn" : null,' +
        '"postnummer" : "6636",' +
        '"matrikkelId" : 130534152,' +
        '"koordinater" : {' +
        '"z" : 0.0,' +
        '"y" : 6974511.0,' +
        '"x" : 453529.0,' +
        '"kvalitet" : null' +
        '},' +
        '"kommunenummer" : "1557",' +
        '"husnummer" : "1",' +
        '"husbokstav" : null,' +
        '"bydelsnummer" : null,' +
        '"bruksenhetsnummer" : null,' +
        '"adressenavn" : "Plassavegen"' +
        '},' +
        '"utenlandskAdresse" : null,' +
        '"ukjentBosted" : null,' +
        '"matrikkeladresse" : null,' +
        '"gyldigTilOgMed" : null,' +
        '"gyldigFraOgMed" : "1965-10-12T00:00:00.000Z",' +
        '"coAdressenavn" : null,' +
        '"angittFlyttedato" : "1965-10-12"' +
        '} ],' +
        '"adressebeskyttelse" : [ ]' +
        '},' +
        '"hentIdenter" : {' +
        '"identer" : [ {' +
        '"ident" : "12106519356",' +
        '"historisk" : false,' +
        '"gruppe" : "FOLKEREGISTERIDENT"' +
        '}, {' +
        '"ident" : "2762473496911",' +
        '"historisk" : false,' +
        '"gruppe" : "AKTORID"' +
        '} ]' +
        '}' +
        '}' +
        '}';
    static final String withParentsPerson =
        '{' +
        '"errors" : null,' +
        '"data" : {' +
        '"hentPerson" : {' +
        '"sivilstand" : [ {' +
        '"type" : "UGIFT",' +
        '"relatertVedSivilstand" : null,' +
        '"gyldigFraOgMed" : null,' +
        '"bekreftelsesdato" : null' +
        '} ],' +
        '"sikkerhetstiltak" : [ ],' +
        '"oppholdsadresse" : [ ],' +
        '"opphold" : [ ],' +
        '"navn" : [ {' +
        '"mellomnavn" : "SLØVENDE",' +
        '"gyldigFraOgMed" : "2021-09-02",' +
        '"fornavn" : "VAKKER",' +
        '"forkortetNavn" : "SNERK VAKKER SLØVENDE",' +
        '"etternavn" : "SNERK"' +
        '} ],' +
        '"kjoenn" : [ {' +
        '"kjoenn" : "MANN"' +
        '} ],' +
        '"foreldreansvar" : [ {' +
        '"ansvarssubjekt" : "02091379875",' +
        '"ansvarligUtenIdentifikator" : null,' +
        '"ansvarlig" : null,' +
        '"ansvar" : "far"' +
        '} ],' +
        '"forelderBarnRelasjon" : [ {' +
        '"relatertPersonsRolle" : "FAR",' +
        '"relatertPersonsIdent" : "02091379875",' +
        '"minRolleForPerson" : "BARN"' +
        '} ],' +
        '"folkeregisteridentifikator" : [ {' +
        '"type" : "FNR",' +
        '"status" : "I_BRUK",' +
        '"identifikasjonsnummer" : "12106519356"' +
        '} ],' +
        '"foedsel" : [ {' +
        '"foedselsdato" : "2005-10-12",' +
        '"foedselsaar" : 2005,' +
        '"foedested" : "Fødested i/på Gjemnes",' +
        '"foedeland" : "NOR",' +
        '"foedekommune" : null' +
        '} ],' +
        '"falskIdentitet" : null,' +
        '"doedsfall" : [ ],' +
        '"doedfoedtBarn" : [ ],' +
        '"deltBosted" : [ ],' +
        '"bostedsadresse" : [ {' +
        '"vegadresse" : {' +
        '"tilleggsnavn" : null,' +
        '"postnummer" : "6636",' +
        '"matrikkelId" : 130534152,' +
        '"koordinater" : {' +
        '"z" : 0.0,' +
        '"y" : 6974511.0,' +
        '"x" : 453529.0,' +
        '"kvalitet" : null' +
        '},' +
        '"kommunenummer" : "1557",' +
        '"husnummer" : "1",' +
        '"husbokstav" : null,' +
        '"bydelsnummer" : null,' +
        '"bruksenhetsnummer" : null,' +
        '"adressenavn" : "Plassavegen"' +
        '},' +
        '"utenlandskAdresse" : null,' +
        '"ukjentBosted" : null,' +
        '"matrikkeladresse" : null,' +
        '"gyldigTilOgMed" : null,' +
        '"gyldigFraOgMed" : "1965-10-12T00:00:00.000Z",' +
        '"coAdressenavn" : null,' +
        '"angittFlyttedato" : "1965-10-12"' +
        '} ],' +
        '"adressebeskyttelse" : [ ]' +
        '},' +
        '"hentIdenter" : {' +
        '"identer" : [ {' +
        '"ident" : "12106519356",' +
        '"historisk" : false,' +
        '"gruppe" : "FOLKEREGISTERIDENT"' +
        '}, {' +
        '"ident" : "2762473496911",' +
        '"historisk" : false,' +
        '"gruppe" : "AKTORID"' +
        '} ]' +
        '}' +
        '}' +
        '}';
    static final String testJsonString =
        '{' +
        '"errors" : null,' +
        '"data" : {' +
        '"hentPerson" : {' +
        '"vergemaalEllerFremtidsfullmakt" : [ ],' +
        '"utflyttingFraNorge" : [ ],' +
        '"utenlandskIdentifikasjonsnummer" : [ ],' +
        '"tilrettelagtKommunikasjon" : [ ],' +
        '"telefonnummer" : [ ],' +
        '"statsborgerskap" : [ {' +
        '"metadata" : {' +
        '"opplysningsId" : "dd35688f-febd-4626-a9b4-39ed732ad69a",' +
        '"master" : "FREG",' +
        '"historisk" : false,' +
        '"endringer" : [ {' +
        '"type" : "OPPRETT",' +
        '"systemkilde" : "FREG",' +
        '"registrertAv" : "Folkeregisteret",' +
        '"registrert" : "2021-09-02T10:17:35.000Z",' +
        '"kilde" : "Dolly"' +
        '} ]' +
        '},' +
        '"land" : "NOR",' +
        '"gyldigTilOgMed" : null,' +
        '"gyldigFraOgMed" : "1965-10-12",' +
        '"folkeregistermetadata" : {' +
        '"sekvens" : null,' +
        '"opphoerstidspunkt" : null,' +
        '"kilde" : "Dolly",' +
        '"gyldighetstidspunkt" : "1965-10-12T00:00:00.000Z",' +
        '"ajourholdstidspunkt" : "2021-09-02T10:17:35.000Z",' +
        '"aarsak" : null' +
        '},' +
        '"bekreftelsesdato" : null' +
        '} ],' +
        '"sivilstand" : [ {' +
        '"type" : "UGIFT",' +
        '"relatertVedSivilstand" : null,' +
        '"metadata" : {' +
        '"opplysningsId" : "69789195-317e-42f7-8c28-c2cdda73901f",' +
        '"master" : "FREG",' +
        '"historisk" : false,' +
        '"endringer" : [ {' +
        '"type" : "OPPRETT",' +
        '"systemkilde" : "FREG",' +
        '"registrertAv" : "Folkeregisteret",' +
        '"registrert" : "2021-09-02T10:17:36.000Z",' +
        '"kilde" : "Dolly"' +
        '} ]' +
        '},' +
        '"gyldigFraOgMed" : null,' +
        '"folkeregistermetadata" : {' +
        '"sekvens" : null,' +
        '"opphoerstidspunkt" : null,' +
        '"kilde" : "Dolly",' +
        '"gyldighetstidspunkt" : "2021-09-02T10:17:36.000Z",' +
        '"ajourholdstidspunkt" : "2021-09-02T10:17:36.000Z",' +
        '"aarsak" : null' +
        '},' +
        '"bekreftelsesdato" : null' +
        '} ],' +
        '"sikkerhetstiltak" : [ ],' +
        '"oppholdsadresse" : [ ],' +
        '"opphold" : [ ],' +
        '"navn" : [ {' +
        '"originaltNavn" : null,' +
        '"metadata" : {' +
        '"opplysningsId" : "c38343b4-2781-4bff-aa26-dc78bc46ee4d",' +
        '"master" : "FREG",' +
        '"historisk" : false,' +
        '"endringer" : [ {' +
        '"type" : "OPPRETT",' +
        '"systemkilde" : "FREG",' +
        '"registrertAv" : "Folkeregisteret",' +
        '"registrert" : "2021-09-02T10:17:35.000Z",' +
        '"kilde" : "Dolly"' +
        '} ]' +
        '},' +
        '"mellomnavn" : "SLØVENDE",' +
        '"gyldigFraOgMed" : "2021-09-02",' +
        '"fornavn" : "VAKKER",' +
        '"forkortetNavn" : "SNERK VAKKER SLØVENDE",' +
        '"folkeregistermetadata" : {' +
        '"sekvens" : null,' +
        '"opphoerstidspunkt" : null,' +
        '"kilde" : "Dolly",' +
        '"gyldighetstidspunkt" : "2021-09-02T10:17:35.000Z",' +
        '"ajourholdstidspunkt" : "2021-09-02T10:17:35.000Z",' +
        '"aarsak" : null' +
        '},' +
        '"etternavn" : "SNERK"' +
        '} ],' +
        '"kontaktinformasjonForDoedsbo" : [ ],' +
        '"kontaktadresse" : [ ],' +
        '"kjoenn" : [ {' +
        '"metadata" : {' +
        '"opplysningsId" : "6be1bb25-2731-489b-ac15-49a93730ea8e",' +
        '"master" : "FREG",' +
        '"historisk" : false,' +
        '"endringer" : [ {' +
        '"type" : "OPPRETT",' +
        '"systemkilde" : "FREG",' +
        '"registrertAv" : "Folkeregisteret",' +
        '"registrert" : "2021-09-02T10:17:35.000Z",' +
        '"kilde" : "Dolly"' +
        '} ]' +
        '},' +
        '"kjoenn" : "MANN",' +
        '"folkeregistermetadata" : {' +
        '"sekvens" : null,' +
        '"opphoerstidspunkt" : null,' +
        '"kilde" : "Dolly",' +
        '"gyldighetstidspunkt" : "2021-09-02T10:17:35.000Z",' +
        '"ajourholdstidspunkt" : "2021-09-02T10:17:35.000Z",' +
        '"aarsak" : null' +
        '}' +
        '} ],' +
        '"innflyttingTilNorge" : [ ],' +
        '"identitetsgrunnlag" : [ ],' +
        '"fullmakt" : [ ],' +
        '"foreldreansvar" : [ {' +
        '"metadata" : {' +
        '"opplysningsId" : "4b47f1b0-9316-49bf-820b-3c5b0080b895",' +
        '"master" : "FREG",' +
        '"historisk" : false,' +
        '"endringer" : [ {' +
        '"type" : "OPPRETT",' +
        '"systemkilde" : "FREG",' +
        '"registrertAv" : "Folkeregisteret",' +
        '"registrert" : "2021-09-02T10:17:37.000Z",' +
        '"kilde" : "Dolly"' +
        '} ]' +
        '},' +
        '"folkeregistermetadata" : {' +
        '"sekvens" : null,' +
        '"opphoerstidspunkt" : null,' +
        '"kilde" : "Dolly",' +
        '"gyldighetstidspunkt" : "2021-09-02T10:17:37.000Z",' +
        '"ajourholdstidspunkt" : "2021-09-02T10:17:37.000Z",' +
        '"aarsak" : null' +
        '},' +
        '"ansvarssubjekt" : "02091379875",' +
        '"ansvarligUtenIdentifikator" : null,' +
        '"ansvarlig" : null,' +
        '"ansvar" : "far"' +
        '} ],' +
        '"forelderBarnRelasjon" : [ {' +
        '"relatertPersonsRolle" : "BARN",' +
        '"relatertPersonsIdent" : "02091379875",' +
        '"minRolleForPerson" : "FAR",' +
        '"metadata" : {' +
        '"opplysningsId" : "8c713184-ebe2-4dbe-8c6e-cff4760273d6",' +
        '"master" : "FREG",' +
        '"historisk" : false,' +
        '"endringer" : [ {' +
        '"type" : "OPPRETT",' +
        '"systemkilde" : "FREG",' +
        '"registrertAv" : "Folkeregisteret",' +
        '"registrert" : "2021-09-02T10:17:36.000Z",' +
        '"kilde" : "Dolly"' +
        '} ]' +
        '},' +
        '"folkeregistermetadata" : {' +
        '"sekvens" : null,' +
        '"opphoerstidspunkt" : null,' +
        '"kilde" : "Dolly",' +
        '"gyldighetstidspunkt" : "2021-09-02T10:17:36.000Z",' +
        '"ajourholdstidspunkt" : "2021-09-02T10:17:36.000Z",' +
        '"aarsak" : null' +
        '}' +
        '} ],' +
        '"folkeregisterpersonstatus" : [ {' +
        '"status" : "bosatt",' +
        '"metadata" : {' +
        '"opplysningsId" : "affd81b7-665c-4e82-88fb-a36181b6cb65",' +
        '"master" : "FREG",' +
        '"historisk" : false,' +
        '"endringer" : [ {' +
        '"type" : "OPPRETT",' +
        '"systemkilde" : "FREG",' +
        '"registrertAv" : "Folkeregisteret",' +
        '"registrert" : "2021-09-02T10:17:35.000Z",' +
        '"kilde" : "Dolly"' +
        '} ]' +
        '},' +
        '"forenkletStatus" : "bosattEtterFolkeregisterloven",' +
        '"folkeregistermetadata" : {' +
        '"sekvens" : null,' +
        '"opphoerstidspunkt" : null,' +
        '"kilde" : "Dolly",' +
        '"gyldighetstidspunkt" : "2021-09-02T10:17:35.000Z",' +
        '"ajourholdstidspunkt" : "2021-09-02T10:17:35.000Z",' +
        '"aarsak" : null' +
        '}' +
        '} ],' +
        '"folkeregisteridentifikator" : [ {' +
        '"type" : "FNR",' +
        '"status" : "I_BRUK",' +
        '"metadata" : {' +
        '"opplysningsId" : "33be3e25-ccd5-4f97-8f21-bbac3c444877",' +
        '"master" : "FREG",' +
        '"historisk" : false,' +
        '"endringer" : [ {' +
        '"type" : "OPPRETT",' +
        '"systemkilde" : "FREG",' +
        '"registrertAv" : "Folkeregisteret",' +
        '"registrert" : "2021-09-02T10:17:35.000Z",' +
        '"kilde" : "srvdolly"' +
        '} ]' +
        '},' +
        '"identifikasjonsnummer" : "12106519356",' +
        '"folkeregistermetadata" : {' +
        '"sekvens" : null,' +
        '"opphoerstidspunkt" : null,' +
        '"kilde" : "srvdolly",' +
        '"gyldighetstidspunkt" : "2021-09-02T10:17:35.000Z",' +
        '"ajourholdstidspunkt" : "2021-09-02T10:17:35.000Z",' +
        '"aarsak" : null' +
        '}' +
        '} ],' +
        '"foedsel" : [ {' +
        '"metadata" : {' +
        '"opplysningsId" : "20e8b676-568e-4eee-b5ce-b57156f850f5",' +
        '"master" : "FREG",' +
        '"historisk" : false,' +
        '"endringer" : [ {' +
        '"type" : "OPPRETT",' +
        '"systemkilde" : "FREG",' +
        '"registrertAv" : "Folkeregisteret",' +
        '"registrert" : "2021-09-02T10:17:35.000Z",' +
        '"kilde" : "Dolly"' +
        '} ]' +
        '},' +
        '"folkeregistermetadata" : {' +
        '"sekvens" : null,' +
        '"opphoerstidspunkt" : null,' +
        '"kilde" : "Dolly",' +
        '"gyldighetstidspunkt" : "2021-09-02T10:17:35.000Z",' +
        '"ajourholdstidspunkt" : "2021-09-02T10:17:35.000Z",' +
        '"aarsak" : null' +
        '},' +
        '"foedselsdato" : "1965-10-12",' +
        '"foedselsaar" : 1965,' +
        '"foedested" : "Fødested i/på Gjemnes",' +
        '"foedeland" : "NOR",' +
        '"foedekommune" : null' +
        '} ],' +
        '"falskIdentitet" : null,' +
        '"doedsfall" : [ ],' +
        '"doedfoedtBarn" : [ ],' +
        '"deltBosted" : [ ],' +
        '"bostedsadresse" : [ {' +
        '"vegadresse" : {' +
        '"tilleggsnavn" : null,' +
        '"postnummer" : "6636",' +
        '"matrikkelId" : 130534152,' +
        '"koordinater" : {' +
        '"z" : 0.0,' +
        '"y" : 6974511.0,' +
        '"x" : 453529.0,' +
        '"kvalitet" : null' +
        '},' +
        '"kommunenummer" : "1557",' +
        '"husnummer" : "1",' +
        '"husbokstav" : null,' +
        '"bydelsnummer" : null,' +
        '"bruksenhetsnummer" : null,' +
        '"adressenavn" : "Plassavegen"' +
        '},' +
        '"utenlandskAdresse" : null,' +
        '"ukjentBosted" : null,' +
        '"metadata" : {' +
        '"opplysningsId" : "53a9f29d-0980-42a3-8e18-13ae0b01b3d7",' +
        '"master" : "FREG",' +
        '"historisk" : false,' +
        '"endringer" : [ {' +
        '"type" : "OPPRETT",' +
        '"systemkilde" : "FREG",' +
        '"registrertAv" : "Folkeregisteret",' +
        '"registrert" : "2021-09-02T10:17:35.000Z",' +
        '"kilde" : "Dolly"' +
        '} ]' +
        '},' +
        '"matrikkeladresse" : null,' +
        '"gyldigTilOgMed" : null,' +
        '"gyldigFraOgMed" : "1965-10-12T00:00:00.000Z",' +
        '"folkeregistermetadata" : {' +
        '"sekvens" : null,' +
        '"opphoerstidspunkt" : null,' +
        '"kilde" : "Dolly",' +
        '"gyldighetstidspunkt" : "1965-10-12T00:00:00.000Z",' +
        '"ajourholdstidspunkt" : "2021-09-02T10:17:35.000Z",' +
        '"aarsak" : null' +
        '},' +
        '"coAdressenavn" : null,' +
        '"angittFlyttedato" : "1965-10-12"' +
        '} ],' +
        '"adressebeskyttelse" : [ ]' +
        '},' +
        '"hentIdenter" : {' +
        '"identer" : [ {' +
        '"ident" : "12106519356",' +
        '"historisk" : false,' +
        '"gruppe" : "FOLKEREGISTERIDENT"' +
        '}, {' +
        '"ident" : "2762473496911",' +
        '"historisk" : false,' +
        '"gruppe" : "AKTORID"' +
        '} ]' +
        '}' +
        '}' +
        '}';
}
