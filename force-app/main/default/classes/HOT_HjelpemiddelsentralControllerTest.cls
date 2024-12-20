@IsTest
public with sharing class HOT_HjelpemiddelsentralControllerTest {
    @IsTest
    static void testGetAllHjelpemiddelSentraler() {
        List<HOT_HjelpemiddelsentralMapping__mdt> result = HOT_HjelpemiddelsentralController.getAllHjelpemiddelSentraler();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(14, result.size(), 'There should be 14 records returned');
    }
    @IsTest
    static void testGetPersonMunicipalityAndRegionsAccount() {
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
}
