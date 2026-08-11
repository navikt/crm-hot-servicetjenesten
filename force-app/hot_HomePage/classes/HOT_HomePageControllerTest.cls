@isTest
private class HOT_HomePageControllerTest {
    @TestSetup
    static void makeData() {
        Id HOTStatusRecordTypeId = Schema.SObjectType.NKS_Announcement__c.getRecordTypeInfosByName()
            .get('HOT Info')
            .getRecordTypeId();

        NKS_Announcement__c traffic = new NKS_Announcement__c(
            Name = 'Test Traffic',
            NKS_Information__c = 'Leveransen lørdag 31. oktober ble levert som planlagt, og NAV Arbeid og ytelser kan derfor nå innvilge dagpenger til personer også fra den 1. november eller senere. Opprinnelig melding 29.10.20: Hvis bruker har søkt om dagpenger med virkningstidspunkt fra 1.november eller senere, så kan vi få henvendelser hvor bruker etterlyser svar på søknaden. NAV Arbeid og ytelser behandler for tiden ingen søknader om dagpenger med virkningstidspunkt (startdato) fra 1. november eller senere. Årsaken er regelverksendringer fra den datoen, som vi må få oppdatert i fagsystemene først, for at utfall i saken skal bli rett.Informer gjerne bruker om dette, og henvis eller til saksbehandlingstidene på nav.no.!!!!',
            RecordTypeId = HOTStatusRecordTypeId
        );
        insert traffic;

        Knowledge__kav testKnowledge = new Knowledge__kav(
            Title = 'Test Article',
            UrlName = 'Test-Article',
            Summary = 'Informasjon for test'
        );
        insert testKnowledge;
    }

    @isTest
    public static void testGetField() {
        Test.startTest();
        try {
            HOT_HomePageController.getField('Hot_Info');
        } catch (AurahandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    public static void testGetFielderr() {
        Test.startTest();
        try {
            HOT_HomePageController.getField('');
        } catch (AurahandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGetAnnouncementTraffic() {
        Test.startTest();
        NKS_Announcement__c traffic = HOT_HomePageController.getHOTStatus('Test Traffic');
        Test.stopTest();

        Assert.areEqual('Test Traffic', traffic.Name);
    }

    @isTest
    static void testGetReadyResponse() {
        Test.startTest();
        List<Knowledge__kav> testList = HOT_HomePageController.getReadyResponses();
        Test.stopTest();

        Assert.areEqual(null, testList);
    }

    @isTest
    static void testUpdateHOTStatus_SuccessfulUpdate() {
        NKS_Announcement__c status = [
            SELECT Id, Name
            FROM NKS_Announcement__c
            WHERE NKS_TypeFormula__c = 'HOT Info'
            LIMIT 1
        ];

        Map<String, String> fields = new Map<String, String>{
            'Id' => status.Id,
            'NKS_Information__c' => 'Updated Information'
        };

        Test.startTest();
        HOT_HomePageController.updateHOTStatus(fields);
        Test.stopTest();

        NKS_Announcement__c updatedStatus = [SELECT NKS_Information__c FROM NKS_Announcement__c WHERE Id = :status.Id];
        Assert.areEqual(
            'Updated Information',
            updatedStatus.NKS_Information__c,
            'The NKS_Information__c field should be updated.'
        );
    }

    @isTest
    static void testUpdateHOTStatusError() {
        Exception ex;

        Test.startTest();
        try {
            HOT_HomePageController.updateHOTStatus(null);
        } catch (Exception e) {
            ex = e;
        }
        Test.stopTest();

        Assert.areNotEqual(null, ex);
    }
}
