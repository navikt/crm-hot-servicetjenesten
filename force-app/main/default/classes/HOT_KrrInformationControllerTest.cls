@IsTest
public class HOT_KrrInformationControllerTest {
    @TestSetup
    static void makeData() {
        HOT_ST_TestDataFactory.createRecord(new Person__c(Name = '01048800153'));
    }

    @IsTest
    static void testKrrUpdateEmailEqualMobile() {
        String json = '{"personer": {"01048800153": {"personident": "01048800153","aktiv": true,"kanVarsles": true,"reservert": true,"spraak": "string","spraakOppdatert": "2022-10-17T10:12:25.864Z","epostadresse": "01048800153-test@minid.norge.no","epostadresseOppdatert": "2022-10-17T10:12:25.864Z","epostadresseVerifisert": "2022-10-17T10:12:25.864Z","mobiltelefonnummer": "+4799999999","mobiltelefonnummerOppdatert": "2022-10-17T10:12:25.864Z","mobiltelefonnummerVerifisert": "2022-10-17T10:12:25.864Z","sikkerDigitalPostkasse": {"adresse": "string","leverandoerAdresse": "string","leverandoerSertifikat": "string"}}},"feil": {}}';
        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(
                200,
                'OK',
                json,
                null
            )
        );

        Test.startTest();
        HOT_KrrInformationController.updateKrrInformation('01048800153');
        Test.stopTest();

        System.assertEquals(
            true,
            [SELECT Id, INT_KRR_Reservation__c FROM Person__c WHERE Name = '01048800153' LIMIT 1].INT_KRR_Reservation__c
        );
    }

    @IsTest
    static void testKrrUpdateErr() {
        Test.startTest();
        try {
            HOT_KrrInformationController.updateKrrInformation('12345678901');
            System.assertEquals(
                null,
                [SELECT Id, INT_KRR_Reservation__c FROM Person__c WHERE Name = '12345678901' LIMIT 1]
                ?.INT_KRR_Reservation__c
            );
        } catch (AurahandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testKrrUpdateMobileNewest() {
        String json = '{"personer": {"01048800153": {"personident": "01048800153","aktiv": true,"kanVarsles": true,"reservert": true,"spraak": "string","spraakOppdatert": "2022-10-17T10:12:25.864Z","epostadresse": "01048800153-test@minid.norge.no","epostadresseOppdatert": "2022-10-17T10:12:25.864Z","epostadresseVerifisert": "2022-10-17T10:12:25.864Z","mobiltelefonnummer": "+4799999999","mobiltelefonnummerOppdatert": "2022-10-17T10:12:25.864Z","mobiltelefonnummerVerifisert": "2022-10-18T10:12:25.864Z","sikkerDigitalPostkasse": {"adresse": "string","leverandoerAdresse": "string","leverandoerSertifikat": "string"}}},"feil": {}}';
        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(
                200,
                'OK',
                json,
                null
            )
        );

        Test.startTest();
        HOT_KrrInformationController.updateKrrInformation('01048800153');
        Test.stopTest();

        System.assertEquals(
            true,
            [SELECT Id, INT_KRR_Reservation__c FROM Person__c WHERE Name = '01048800153' LIMIT 1].INT_KRR_Reservation__c
        );
    }

    @IsTest
    static void testKrrUpdateMobile() {
        String json = '{"personer": {"01048800153": {"personident": "01048800153","aktiv": true,"kanVarsles": true,"reservasjonOppdatert": "2025-05-06T11:15:37.514112Z","reservert": true,"spraak": "nb","spraakOppdatert": "2022-10-17T10:12:25.864Z","epostadresse": "01048800153-test@minid.norge.no","epostadresseOppdatert": "2022-10-17T10:12:25.864Z","epostadresseVerifisert": "2025-05-06T11:15:37.514153Z","mobiltelefonnummer": "+4799999999","mobiltelefonnummerOppdatert": "2022-10-17T10:12:25.864Z","mobiltelefonnummerVerifisert":"2022-10-18T10:12:25.864Z", "sikkerDigitalPostkasse": {"adresse": "asd.no","leverandoerAdresse": "984661185","leverandoerSertifikat": "MIIGTzCCBDegAwIBAgILAZdzsvHu7xp9XY..."}}},"feil": {}}';
        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(
                200,
                'OK',
                json,
                null
            )
        );

        Test.startTest();
        HOT_KrrInformationController.updateKrrInformation('01048800153');
        Test.stopTest();

        System.assertEquals(
            true,
            [SELECT Id, INT_KRR_Reservation__c FROM Person__c WHERE Name = '01048800153' LIMIT 1].INT_KRR_Reservation__c
        );
    }

    @IsTest
    static void testKrrUpdateNoVerification() {
        String json = '{"personer": {"01048800153": {"personident": "01048800153","aktiv": true,"kanVarsles": true,"reservasjonOppdatert": "2025-05-06T11:15:37.514112Z","reservert": true,"spraak": "nb","spraakOppdatert": "2022-10-17T10:12:25.864Z","epostadresse": "01048800153-test@minid.norge.no","epostadresseOppdatert": "2022-10-17T10:12:25.864Z","epostadresseVerifisert": "2025-05-06T11:15:37.514153Z","mobiltelefonnummer": "+4799999999","mobiltelefonnummerOppdatert": "2022-10-17T10:12:25.864Z", "sikkerDigitalPostkasse": {"adresse": "asd.no","leverandoerAdresse": "984661185","leverandoerSertifikat": "MIIGTzCCBDegAwIBAgILAZdzsvHu7xp9XY..."}}},"feil": {}}';
        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(
                200,
                'OK',
                json,
                null
            )
        );

        Test.startTest();
        HOT_KrrInformationController.updateKrrInformation('01048800153');
        Test.stopTest();

        System.assertEquals(
            true,
            [SELECT Id, INT_KRR_Reservation__c FROM Person__c WHERE Name = '01048800153' LIMIT 1].INT_KRR_Reservation__c
        );
    }

    @IsTest
    static void testKrrUpdateEmail() {
        String json = '{"personer": {"01048800153": {"personident": "01048800153","aktiv": true,"kanVarsles": false,"reservasjonOppdatert": "2025-05-06T11:15:37.514112Z","reservert": true,"spraak": "nb","spraakOppdatert": "2025-05-06T11:15:37.514155Z","epostadresse": "test@test.no","epostadresseOppdatert": "2025-05-06T11:15:37.514151Z","epostadresseVerifisert": "2025-05-06T11:15:37.514153Z","mobiltelefonnummer": "+4712345678","mobiltelefonnummerOppdatert": "2025-05-06T11:15:37.514136Z","mobiltelefonnummerVerifisert": "2025-05-06T11:15:37.51414Z", "sikkerDigitalPostkasse": {"adresse": "asd.no","leverandoerAdresse": "984661185","leverandoerSertifikat": "MIIGTzCCBDegAwIBAgILAZdzsvHu7xp9XY..."}}},"feil": {}}';

        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(
                200,
                'OK',
                json,
                null
            )
        );

        Test.startTest();
        HOT_KrrInformationController.updateKrrInformation('01048800153');
        Test.stopTest();

        System.assertEquals(
            true,
            [SELECT Id, INT_KRR_Reservation__c FROM Person__c WHERE Name = '01048800153' LIMIT 1].INT_KRR_Reservation__c
        );
    }
}
