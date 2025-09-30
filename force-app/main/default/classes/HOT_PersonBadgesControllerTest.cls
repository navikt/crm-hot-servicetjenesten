@IsTest
public with sharing class HOT_PersonBadgesControllerTest {
    static String toIso(Date d) {
        return Datetime.newInstanceGmt(d, Time.newInstance(12, 0, 0, 0)).format('yyyy-MM-dd');
    }

    @TestSetup
    static void makeData() {
        Person__c p = (Person__c) HOT_ST_TestDataFactory.createRecord(
            new Person__c(
                Name = '12345678901',
                INT_FirstName__c = 'Harry',
                INT_LastName__c = 'Potter',
                INT_Confidential__c = 'UGRADERT'
            ),
            true
        );

        Person__c p2 = (Person__c) HOT_ST_TestDataFactory.createRecord(
            new Person__c(
                Name = '01234567890',
                INT_FirstName__c = 'Motpart',
                INT_LastName__c = 'Motpartsen',
                INT_Confidential__c = 'UGRADERT'
            ),
            true
        );

        insert new List<Common_Code__c>{
            new Common_Code__c(
                CRM_Active__c = true,
                CRM_Archive_Theme__c = true,
                CRM_Code__c = 'AAP',
                CRM_Code_Set__c = 'Tema',
                CRM_Display_Name__c = '',
                CRM_UniqueKey__c = 'TemaAAP',
                Name = 'Arbeidsavklaringspenger'
            ),
            new Common_Code__c(
                CRM_Active__c = true,
                CRM_Archive_Theme__c = true,
                CRM_Code__c = 'DAG',
                CRM_Code_Set__c = 'Tema',
                CRM_Display_Name__c = '',
                CRM_UniqueKey__c = 'TemaDAG',
                Name = 'Dagpenger'
            )
        };
    }

    @IsTest
    static void setBadgeData_GuardianshipOrFuturePowerOfAttorney() {
        ApiMock.setTestMock('GET_OEBS_BrukerPass', 200, '{"brukerPass":{"status":"PENDING"}}');

        String jsonString = '[{"type": "voksen","embete": "Fylkesmannen i Trøndelag","vergeEllerFullmektig": {"navn": {"fornavn": "Djerv","mellomnavn": null,"etternavn": "Eplekake"},"identifiserendeInformasjon": {"navn": {"fornavn": "Djerv","mellomnavn": null,"etternavn": "Eplekake"},"kjoenn": null,"foedselsdato": null,"statsborgerskap": null},"motpartsPersonident": "01234567890","omfang": "personligeOgOekonomiskeInteresser","omfangetErInnenPersonligOmraade": true,"tjenesteomraade": []}}]';
        Person__c p = [SELECT Id, CRM_Account__c FROM Person__c WHERE Name = '12345678901'];
        p.INT_GuardianshipOrFuturePowerOfAttorney__c = jsonString;
        update p;

        HOT_PersonBadgesController.PersonBadgeData result;
        Test.startTest();
        result = HOT_PersonBadgesController.getPersonBadgesAndInfo('CRM_Person__c', 'Account', p.CRM_Account__c, false);
        Test.stopTest();

        System.assert(result.guardianships.size() >= 1, 'Expected at least one guardianship');
        Assert.areEqual(
            'Ja',
            result.guardianships[0].omfangetErInnenPersonligOmraadeTxt,
            'Expected "Ja" since omfangetErInnenPersonligOmraade = "true"'
        );

        System.assert(result.badges.size() >= 1, 'Expected at least one guardianship badge');
        Assert.areEqual('Motpart Motpartsen', result.guardianships[0].vergeEllerFullmektig.navn.fullName, 'Wrong name');
        System.assertNotEquals(
            result.guardianships[0].vergeEllerFullmektig.omfang,
            result.guardianships[0].omfangLabel,
            'Expected omfang to have a label'
        );
        System.assertNotEquals(
            result.guardianships[0].type,
            result.guardianships[0].typeLabel,
            'Expected type to have a label'
        );
        Assert.areNotEqual(
            result.guardianships[0].vergeEllerFullmektig.motpartsPersonIdent,
            result.guardianships[0].motpartLabel,
            'Expected motpart to have a label'
        );
        Assert.isNotNull(
            result.guardianships[0].vergeEllerFullmektig.tjenesteomraadeLabel,
            'Expected tjenesteomraade to have a label'
        );
    }

    @IsTest
    static void setBadgeData_GuardianshipOrFuturePowerOfAttorneyError() {
        ApiMock.setTestMock('GET_FULLMAKTSGIVER', 200, 'ok');
        ApiMock.setTestMock('GET_OEBS_BrukerPass', 200, '{"brukerPass":{"status":"PENDING"}}');

        String jsonString = '{"type":"midlertidigForVoksen","omfangetErInnenPersonligOmraade":true,"omfang":"personligeOgOekonomiskeInteresser","navn":null,"motpartsPersonident":"01234567890","embete":"fylkesmannenITromsOgFinnmark"}]';
        Person__c p = [SELECT Id, CRM_Account__c FROM Person__c WHERE Name = '12345678901'];
        p.INT_GuardianshipOrFuturePowerOfAttorney__c = jsonString;
        update p;

        HOT_PersonBadgesController.PersonBadgeData result;
        Test.startTest();
        result = HOT_PersonBadgesController.getPersonBadgesAndInfo('CRM_Person__c', 'Account', p.CRM_Account__c, false);
        Test.stopTest();

        Assert.areEqual(0, result.guardianships.size(), 'Expected 0 guardianship');
        System.assert(result.errors.size() >= 1, 'Expected at least 1 error');
        Assert.areEqual(2, result.badges.size(), 'Expected 2 guardianship badge');
    }

    @IsTest
    static void setBadgeData_PowerOfAttorneySomeAreas() {
        ApiMock.setTestMock('GET_FULLMAKTSGIVER', 200, 'ok');
        ApiMock.setTestMock('GET_OEBS_BrukerPass', 200, '{"brukerPass":{"status":"PENDING"}}');

        Person__c p = [SELECT Id, CRM_Account__c FROM Person__c WHERE Name = '12345678901'];

        HOT_PersonBadgesController.PersonBadgeData result;
        Test.startTest();
        result = HOT_PersonBadgesController.getPersonBadgesAndInfo('CRM_Person__c', 'Account', p.CRM_Account__c, false);
        Test.stopTest();

        Assert.areEqual(1, result.badges.size(), 'Expected one guardianship');
    }

    @IsTest
    static void setBadgeData_PowerOfAttorneyError() {
        ApiMock.setTestMock('GET_FULLMAKTSGIVER', 400, 'ERROR');
        ApiMock.setTestMock('GET_OEBS_BrukerPass', 200, '{"brukerPass":{"status":"PENDING"}}');

        Person__c p = [SELECT Id, CRM_Account__c FROM Person__c WHERE Name = '12345678901'];

        HOT_PersonBadgesController.PersonBadgeData result;
        Test.startTest();
        result = HOT_PersonBadgesController.getPersonBadgesAndInfo('CRM_Person__c', 'Account', p.CRM_Account__c, false);
        Test.stopTest();

        Assert.areEqual(0, result.powerOfAttorneys.size(), 'Expected no guardianships');
        Assert.areEqual(1, result.errors.size(), 'Expected one error');
        System.assert(result.badges.size() == 0 || result.badges.size() == 1,

            'Expected 0 badges (or 1 from other logic)');
    }

    @IsTest
    static void setBadgeData_SecurityMeasure() {
        ApiMock.setTestMock('GET_FULLMAKTSGIVER', 200, 'ok');
        Person__c p = [SELECT Id, CRM_Account__c FROM Person__c WHERE Name = '12345678901'];
        p.INT_SecurityMeasures__c = '[{"tiltaksType":"TFUS","kontaktPersonId":"Z212168","kontaktPersonEnhet":"0106","gyldigTilOgMed":"2027-08-08","gyldigFraOgMed":"2024-06-14","beskrivelse":"Telefonisk utestengelse"}]';
        update p;

        HOT_PersonBadgesController.PersonBadgeData result;
        Test.startTest();
        result = HOT_PersonBadgesController.getPersonBadgesAndInfo('CRM_Person__c', 'Account', p.CRM_Account__c, false);
        Test.stopTest();

        Assert.areEqual(1, result.securityMeasures.size(), 'Expected 1 securitymeasure');
        Assert.areEqual(0, result.errors.size(), 'Expected no error');
    }

    @IsTest
    static void setBadgeData_SecurityMeasures() {
        ApiMock.setTestMock('GET_FULLMAKTSGIVER', 200, 'ok');
        Person__c p = [SELECT Id, CRM_Account__c FROM Person__c WHERE Name = '12345678901'];
        p.INT_SecurityMeasures__c = '[{"tiltaksType":"TFUS","kontaktPersonId":"Z212168","kontaktPersonEnhet":"0106","gyldigTilOgMed":"2027-08-08","gyldigFraOgMed":"2024-06-14","beskrivelse":"Telefonisk utestengelse"},{"tiltaksType":"TFUS","kontaktPersonId":"Z212168","kontaktPersonEnhet":"0106","gyldigTilOgMed":"2027-09-08","gyldigFraOgMed":"2024-09-14","beskrivelse":"Telefonisk utestengelse2"}]';
        update p;

        HOT_PersonBadgesController.PersonBadgeData result;
        Test.startTest();
        result = HOT_PersonBadgesController.getPersonBadgesAndInfo('CRM_Person__c', 'Account', p.CRM_Account__c, false);
        Test.stopTest();

        Assert.areEqual(2, result.securityMeasures.size(), 'Expected 2 securitymeasure');
        Assert.areEqual(0, result.errors.size(), 'Expected no error');
    }
}
