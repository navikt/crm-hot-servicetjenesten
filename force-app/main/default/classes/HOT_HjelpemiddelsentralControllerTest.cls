@IsTest
public with sharing class HOT_HjelpemiddelsentralControllerTest {
    @TestSetup
    static void setup() {
        List<Person__c> persons = HOT_ST_TestDataFactory.createPersons(3);

        for(Person__c p : persons) {
            p.INT_MunicipalityNumber__c = '0000';
            p.INT_RegionNumber__c = '00';
        }
        update persons;

        HOT_ST_TestDataFactory.createPersonAccount(1, persons[0]);
        HOT_ST_TestDataFactory.createPersonAccount(2, persons[1]);
        HOT_ST_TestDataFactory.createPersonAccount(3, persons[2]);
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
        
        // Fetch the account created in setup
        Account acc = [SELECT Id, CRM_Person__c FROM Account LIMIT 1];
        
        // Update the person with a specific municipality to test the return
        Person__c p = [SELECT Id FROM Person__c WHERE Id = :acc.CRM_Person__c];
        p.INT_MunicipalityNumber__c = '0301'; // Example value
        update p;
        
        Person__c result = HOT_HjelpemiddelsentralController.getPersonMunicipalityAndRegions(acc.Id, 'Account');
        System.assertEquals('0301', result.INT_MunicipalityNumber__c, 'Did not get correct municipalitynumber');
    }

    @IsTest
    static void testGetPersonMunicipalityAndRegionsCase() {
        myTriggers.disable(PersonAccessHandler.class);
        
        Account acc = [SELECT Id, CRM_Person__c FROM Account LIMIT 1];
        Person__c p = [SELECT Id FROM Person__c WHERE Id = :acc.CRM_Person__c];
        p.INT_MunicipalityNumber__c = '0301';
        update p;

        Case testCase = new Case(AccountId = acc.Id);
        insert testCase;
        Person__c result = HOT_HjelpemiddelsentralController.getPersonMunicipalityAndRegions(testCase.Id, 'Case');
        System.assertEquals('0301', result.INT_MunicipalityNumber__c, 'Did not get correct municipalitynumber');
    }
    @IsTest
    static void testGetBilsenter() {
        HOT_Bilsenter_Mapping__mdt realMapping;
        try {
            realMapping = [
                SELECT Bilsenter_Navn__c, Kommunenummer__c, Fylkenummer__c 
                FROM HOT_Bilsenter_Mapping__mdt 
                LIMIT 1
            ];
        } catch (QueryException e) {
            System.assert(false, 'No HOT_Bilsenter_Mapping__mdt records found in the Org. Test cannot run.');
        }

        Account acc = [SELECT Id, CRM_Person__c FROM Account LIMIT 1];
        Person__c p = [SELECT Id FROM Person__c WHERE Id = :acc.CRM_Person__c];

        p.INT_MunicipalityNumber__c = realMapping.Kommunenummer__c;
        p.INT_RegionNumber__c = String.valueOf(realMapping.Fylkenummer__c).removeEnd('.0');
        update p;

        Test.startTest();
        HOT_Bilsenter_Mapping__mdt result = HOT_HjelpemiddelsentralController.getBilsenter(acc.Id);
        Test.stopTest();

        System.assertEquals(
            realMapping.Bilsenter_Navn__c,
            result.Bilsenter_Navn__c,
            'Should return the Bilsenter defined in the existing metadata'
        );
    }
}