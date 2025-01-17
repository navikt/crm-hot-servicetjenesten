@IsTest
public class HOT_KrrInformationControllerTest {
    @TestSetup
    static void makeData() {
        HOT_ST_TestDataFactory.createRecord(new Person__c(Name = '01048800153'));
    }

    @IsTest
    static void testKrrUpdate() {
        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(
                200,
                'OK',
                '{\"personer\":{\"additionalProp1\":{\"personident\":\"01048800153\",\"aktiv\":true,\"kanVarsles\":true,\"reservert\":true,\"spraak\":\"string\",\"spraakOppdatert\":\"2022-10-17T10:12:25.864Z\",\"epostadresse\":\"01048800153-test@minid.norge.no\",\"epostadresseOppdatert\":\"2022-10-17T10:12:25.864Z\",\"epostadresseVerifisert\":\"2022-10-17T10:12:25.864Z\",\"mobiltelefonnummer\":\"+4799999999\",\"mobiltelefonnummerOppdatert\":\"2022-10-17T10:12:25.864Z\",\"mobiltelefonnummerVerifisert\":\"2022-10-17T10:12:25.864Z\",\"sikkerDigitalPostkasse\":{\"adresse\":\"string\",\"leverandoerAdresse\":\"string\",\"leverandoerSertifikat\":\"string\"}}}}',
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
