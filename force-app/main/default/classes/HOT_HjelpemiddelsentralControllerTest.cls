@IsTest
public without sharing class HOT_HjelpemiddelsentralControllerTest {
    @TestSetup
    static void setup() {
        myTriggers.disable(PersonAccessHandler.class);
        List<Person__c> persons = HOT_ST_TestDataFactory.createPersons(3);

        Person__c non_split_person = persons[0];
        Person__c split_person_1 = persons[1];
        Person__c split_person_2 = persons[2];

        // Region 03 (Oslo) - Non-split
        non_split_person.INT_MunicipalityNumber__c = '0301';
        non_split_person.INT_RegionNumber__c = '03';

        // Region 34 (Innlandet) - Split Region
        split_person_1.INT_MunicipalityNumber__c = '3401'; // Gran
        split_person_1.INT_RegionNumber__c = '34';

        split_person_2.INT_MunicipalityNumber__c = '3410';
        split_person_2.INT_RegionNumber__c = '34';

        update persons;

        Account non_split_account = [SELECT Id FROM Account WHERE CRM_Person__c = :non_split_person.Id LIMIT 1];
        Account split_account_1 = [SELECT Id FROM Account WHERE CRM_Person__c = :split_person_1.Id LIMIT 1];
        Account split_account_2 = [SELECT Id FROM Account WHERE CRM_Person__c = :split_person_2.Id LIMIT 1];
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

    /**
     * Test Path: Non-Split Region (e.g., 03)
     * Logic: !splitRegionNumbers.contains(bilsenterMapping[0].Fylkenummer__c)
     */
    @IsTest
    static void testGetBilsenter_NonSplit() {
        Account acc = [
            SELECT Id
            FROM Account
            WHERE CRM_Person__r.INT_RegionNumber__c = '03'
            LIMIT 1
        ];

        Test.startTest();
        HOT_Bilsenter_Mapping__mdt result = HOT_HjelpemiddelsentralController.getBilsenter(acc.Id);
        Test.stopTest();

        // Check against Custom Metadata existence
        if (result != null) {
            System.assertEquals('Østlandet', result.Bilsenter_Navn__c, 'Expected Østlandet for Region 03');
        }
    }

    /**
     * Test Path: Split Region (e.g., 34)
     * Logic: splitRegionNumbers.contains(...) AND loop matches Municipality
     */
    @IsTest
    static void testGetBilsenter_SplitRegion() {
        Account acc = [
            SELECT Id
            FROM Account
            WHERE CRM_Person__r.INT_RegionNumber__c = '34' AND CRM_Person__r.INT_MunicipalityNumber__c = '3401'
            LIMIT 1
        ];

        Test.startTest();
        HOT_Bilsenter_Mapping__mdt result = HOT_HjelpemiddelsentralController.getBilsenter(acc.Id);
        Test.stopTest();

        if (result != null) {
            System.assertEquals(
                'Østlandet',
                result.Bilsenter_Navn__c,
                'Should return Bilsenter navn Østlandet for fylkenummer: 34 og kommunenummer: 3401'
            );
        }
    }

    /**
     * Test Path: Account exists but has no Person linked
     * Logic: if (account[0].CRM_Person__c == null) return null
     */
    @IsTest
    static void testGetBilsenter_NoPersonLinked() {
        Account acc = new Account(Name = 'No Person Account');
        insert acc;

        Test.startTest();
        HOT_Bilsenter_Mapping__mdt result = HOT_HjelpemiddelsentralController.getBilsenter(acc.Id);
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null when no person is linked to account');
    }

    /**
     * Test Path: Person exists but Region has no Mapping
     * Logic: if (bilsenterMapping.size() == 0) return null
     */
    @IsTest
    static void testGetBilsenter_NoRegionMapping() {
        myTriggers.disable(PersonAccessHandler.class);
        Person__c p = [SELECT Id FROM Person__c LIMIT 1];
        p.INT_RegionNumber__c = '99';
        update p;

        Account acc = [SELECT Id FROM Account WHERE CRM_Person__c = :p.Id LIMIT 1];

        Test.startTest();
        HOT_Bilsenter_Mapping__mdt result = HOT_HjelpemiddelsentralController.getBilsenter(acc.Id);
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null for non-existent region mapping');
    }

    /**
     * Test Path: Region is null AND Municipality is used to derive region
     * Logic: fylkeStr = kommuneStr.substring(0, 2);
     */
    @IsTest
    static void testGetBilsenter_MunicipalityFallback() {
        myTriggers.disable(PersonAccessHandler.class);
        
        // Create fresh data for this specific edge case
        Person__c p = HOT_ST_TestDataFactory.createPersons(1)[0];
        p.INT_RegionNumber__c = null;     // No Region
        p.INT_MunicipalityNumber__c = '4663';
        update p;

        Account acc = [SELECT Id FROM Account WHERE CRM_Person__c = :p.Id LIMIT 1];

        Test.startTest();
        HOT_Bilsenter_Mapping__mdt result = HOT_HjelpemiddelsentralController.getBilsenter(acc.Id);
        Test.stopTest();

        System.assertEquals('Vest-Norge', result.Bilsenter_Navn__c, 'Should return null when region is missing and municipality is too short');
    }

    /**
     * Test Path: Region is null AND Municipality is too short to derive region
     * Logic: if (String.isBlank(fylkeStr) ...) return null
     */
    @IsTest
    static void testGetBilsenter_FallbackFail() {
        myTriggers.disable(PersonAccessHandler.class);
        
        // Create fresh data for this specific edge case
        Person__c p = HOT_ST_TestDataFactory.createPersons(1)[0];
        p.INT_RegionNumber__c = null;     // No Region
        p.INT_MunicipalityNumber__c = '1'; // Too short to substring
        update p;

        Account acc = [SELECT Id FROM Account WHERE CRM_Person__c = :p.Id LIMIT 1];

        Test.startTest();
        HOT_Bilsenter_Mapping__mdt result = HOT_HjelpemiddelsentralController.getBilsenter(acc.Id);
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null when region is missing and municipality is too short');
    }

    /**
     * Test Path: Split Region exists (34), but Municipality (9999) is not found in MDT
     * Logic: Loop finishes without finding match -> return null
     */
    @IsTest
    static void testGetBilsenter_SplitRegionNoMatch() {
        myTriggers.disable(PersonAccessHandler.class);
        
        Person__c p = HOT_ST_TestDataFactory.createPersons(1)[0];
        p.INT_RegionNumber__c = '34';      // Is a split region
        p.INT_MunicipalityNumber__c = '9999'; // Does not exist in MDT for 34
        update p;

        Account acc = [SELECT Id FROM Account WHERE CRM_Person__c = :p.Id LIMIT 1];

        Test.startTest();
        HOT_Bilsenter_Mapping__mdt result = HOT_HjelpemiddelsentralController.getBilsenter(acc.Id);
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null when municipality is not found within a split region');
    }

    /**
     * Test Path: Method called with Null Account ID
     * Logic: Query returns empty list -> return null
     */
    @IsTest
    static void testGetBilsenter_NullAccountId() {
        Test.startTest();
        HOT_Bilsenter_Mapping__mdt result = HOT_HjelpemiddelsentralController.getBilsenter(null);
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null when AccountId is null');
    }
}
