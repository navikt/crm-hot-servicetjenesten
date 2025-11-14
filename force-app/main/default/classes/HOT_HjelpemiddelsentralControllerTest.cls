@IsTest
public with sharing class HOT_HjelpemiddelsentralControllerTest {
    @TestSetup
    static void setup() {
        List<Person__c> persons = HOT_ST_TestDataFactory.createPersons(3);

        Person__c non_split_person = persons[0];
        Person__c split_person_1 = persons[1];
        Person__c split_person_2 = persons[2];

        non_split_person.INT_MunicipalityNumber__c = '0301';
        non_split_person.INT_RegionNumber__c = '03';
        split_person_1.INT_MunicipalityNumber__c = '3404';
        split_person_1.INT_RegionNumber__c = '34';
        split_person_2.INT_MunicipalityNumber__c = '3410';
        split_person_2.INT_RegionNumber__c = '34';

        update persons;

        Account non_split_account = HOT_ST_TestDataFactory.createPersonAccount(1, non_split_person.Id);
        Account split_account_1 = HOT_ST_TestDataFactory.createPersonAccount(2, split_person1.Id);
        Account split_account_2 = HOT_ST_TestDataFactory.createPersonAccount(3, split_person2.Id);

        HOT_Bilsenter_Mapping__mdt m1 = new HOT_Bilsenter_Mapping__mdt(
            DeveloperName = 'Bilsenter_Non_Split',
            Label = 'Bilsenter Non Split',
            Fylkenummer__c = '03',
            Kommunenummer__c = '0301',
            Bilsenter_Navn__c = 'Non Split Bilsenter'
        );

        HOT_Bilsenter_Mapping__mdt m2 = new HOT_Bilsenter_Mapping__mdt(
            DeveloperName = 'Bilsenter_Split_1',
            Label = 'Bilsenter Split 1',
            Fylkenummer__c = '34',
            Kommunenummer__c = '3404',
            Bilsenter_Navn__c = 'Split Bilsenter 1'
        );

        HOT_Bilsenter_Mapping__mdt m3 = new HOT_Bilsenter_Mapping__mdt(
            DeveloperName = 'Bilsenter_Split_2',
            Label = 'Bilsenter Split 2',
            Fylkenummer__c = '34',
            Kommunenummer__c = '3404',
            Bilsenter_Navn__c = 'Split Bilsenter 2'
        );

        insert new List<HOT_Bilsenter_Mapping__mdt>{ m1, m2, m3 };
    }
    @IsTest
    static void testGetAllHjelpemiddelSentraler() {
        List<HOT_HjelpemiddelsentralMapping__mdt> result = HOT_HjelpemiddelsentralController.getAllHjelpemiddelSentraler();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(14, result.size(), 'There should be 14 records returned');
    }
    @IsTest
    static void testGetPersonMunicipalityAndRegionsAccount() {
        myTriggers.disable(PersonAccessHandler.class);
        List<Person__c> persons = HOT_ST_TestDataFactory.createPersons(1);
        List<Id> personIds = new List<Id>();
        for (Person__c p : persons) {
            personIds.add(p.Id);
        }
        List<Account> acc = [SELECT Id FROM Account WHERE CRM_Person__c IN :personIds];
        Person__c result = HOT_HjelpemiddelsentralController.getPersonMunicipalityAndRegions(acc[0].Id, 'Account');
        System.assertEquals('0301', result.INT_MunicipalityNumber__c, 'Did not get correct municipalitynumber');
    }
    @IsTest
    static void testGetPersonMunicipalityAndRegionsCase() {
        myTriggers.disable(PersonAccessHandler.class);
        List<Person__c> persons = HOT_ST_TestDataFactory.createPersons(1);
        List<Id> personIds = new List<Id>();
        for (Person__c p : persons) {
            personIds.add(p.Id);
        }
        List<Account> acc = [SELECT Id FROM Account WHERE CRM_Person__c IN :personIds];
        Case testCase = new Case(AccountId = acc[0].Id);
        insert testCase;
        Person__c result = HOT_HjelpemiddelsentralController.getPersonMunicipalityAndRegions(testCase.Id, 'Case');
        System.assertEquals('0301', result.INT_MunicipalityNumber__c, 'Did not get correct municipalitynumber');
    }
    @IsTest
    static void testGetBilsenter() {
        Account acc = [
            SELECT Id
            FROM Account
            WHERE CRM_Person__r.INT_RegionNumber__c = '03' AND CRM_Person__r.INT_MunicipalityNumber__c = '0301'
            LIMIT 1
        ];

        Test.startTest();
        HOT_Bilsenter_Mapping__mdt result_non_split = HOT_HjelpemiddelsentralController.getBilsenter(acc.Id);
        Test.stopTest();

        System.assertEquals(
            'Non Split Bilsenter',
            result_non_split.Bilsenter_Navn__c,
            'Did not get correct bilsenter for non-split person'
        );
    }
}
