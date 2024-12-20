@IsTest
private class HOT_ST_ThreadPersonAccessHandlerTest {
    private static String SERVICETJENESTEN_VEILEDERE = 'group_470011';
    private static String SERVICETJENESTEN_FORTROLIG = 'group_470012';
    private static String SERVICETJENESTEN_SKJERMET = 'group_470013';
    private static String SERVICETJENESTEN_FORTROLIG_SKJERMET = 'group_470014';
    @TestSetup
    private static void makeData() {
        TestDataFactory.getPublicGroup('NKS Veileder', SERVICETJENESTEN_VEILEDERE);
        TestDataFactory.getPublicGroup('NKS Fortrolig Adresse', SERVICETJENESTEN_FORTROLIG);
        TestDataFactory.getPublicGroup('NKS Skjermet', SERVICETJENESTEN_SKJERMET);
        TestDataFactory.getPublicGroup('NKS Fortrolig Skjermet', SERVICETJENESTEN_FORTROLIG_SKJERMET);
    }

    @IsTest
    private static void grantAccessWhePersonIsChagnedToNavEmployee() {
        //we don't want person trigger access handlers to be run on test data insert
        myTriggers.disable(PersonAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;

        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = :SERVICETJENESTEN_SKJERMET LIMIT 1].Id;

        Thread__c thread = new Thread__c(
            CRM_Account__c = accountId,
            CRM_Thread_Type__c = 'STO',
            STO_Category__c = 'Hjelpemidler'
        );
        insert thread;

        Test.startTest();
        person.INT_IsNavEmployee__c = true;
        update person;
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread to be shared with group 470013'
        );
    }

    @IsTest
    private static void grantAccessWhePersonIsChagnedFromNavEmployee() {
        //we don't want person trigger access handlers to be run on test data insert
        myTriggers.disable(PersonAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = true;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = :SERVICETJENESTEN_VEILEDERE LIMIT 1].Id;
        Id groupSkjermetId = [SELECT Id FROM Group WHERE DeveloperName = :SERVICETJENESTEN_SKJERMET LIMIT 1].Id;

        Thread__c thread = new Thread__c(
            CRM_Account__c = accountId,
            CRM_Thread_Type__c = 'STO',
            STO_Category__c = 'Hjelpemidler'
        );
        insert thread;

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread to not be shared with group 470011'
        );

        Test.startTest();
        person.INT_IsNavEmployee__c = false;
        update person;
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread to be shared with group 470011'
        );
    }
    @isTest
    private static void grantAccessWhenPersonIsConfEmployee() {
        myTriggers.disable(PersonAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;

        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;

        Id veilederGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :SERVICETJENESTEN_VEILEDERE
            LIMIT 1
        ]
        .Id;
        Id skjermetGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :SERVICETJENESTEN_SKJERMET
            LIMIT 1
        ]
        .Id;
        Id fortroligGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :SERVICETJENESTEN_FORTROLIG
            LIMIT 1
        ]
        .Id;
        Id fortroligSkjermetGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :SERVICETJENESTEN_FORTROLIG_SKJERMET
            LIMIT 1
        ]
        .Id;

        Thread__c thread = new Thread__c(
            CRM_Account__c = accountId,
            CRM_Thread_Type__c = 'STO',
            STO_Category__c = 'Hjelpemidler'
        );
        insert thread;

        Test.startTest();
        person.INT_Confidential__c = 'FORTROLIG';
        person.INT_IsNavEmployee__c = true;
        update person;
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :veilederGroupId],
            'Expected thread to be shared with group 470011'
        );
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :skjermetGroupId],
            'Expected thread to be NOT shared with group 470013'
        );
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :fortroligGroupId],
            'Expected thread to be NOT shared with group 470012'
        );
        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :fortroligSkjermetGroupId],
            'Expected thread to be NOT shared with group 470014'
        );
    }

    @isTest
    private static void grantAccessOnThreadCreate() {
        myTriggers.disable(PersonAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;

        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;

        Id veilederGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :SERVICETJENESTEN_VEILEDERE
            LIMIT 1
        ]
        .Id;
        Id skjermetGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :SERVICETJENESTEN_SKJERMET
            LIMIT 1
        ]
        .Id;
        Id fortroligGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :SERVICETJENESTEN_FORTROLIG
            LIMIT 1
        ]
        .Id;
        Id fortroligSkjermetGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :SERVICETJENESTEN_FORTROLIG_SKJERMET
            LIMIT 1
        ]
        .Id;

        Test.startTest();
        Thread__c thread = new Thread__c(
            CRM_Account__c = accountId,
            CRM_Thread_Type__c = 'STO',
            STO_Category__c = 'Hjelpemidler'
        );
        insert thread;
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :veilederGroupId],
            'Expected thread to be shared with group 470011'
        );

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :skjermetGroupId],
            'Expected thread to be NOT shared with group 470013'
        );
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :fortroligGroupId],
            'Expected thread to be NOT shared with group 470012'
        );
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :fortroligSkjermetGroupId],
            'Expected thread to be NOT shared with group 470014'
        );
    }

    @isTest
    private static void grantNoAccessOnNotHjelpemidler() {
        myTriggers.disable(PersonAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;

        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;

        Id veilederGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :SERVICETJENESTEN_VEILEDERE
            LIMIT 1
        ]
        .Id;
        Id skjermetGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :SERVICETJENESTEN_SKJERMET
            LIMIT 1
        ]
        .Id;
        Id fortroligGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :SERVICETJENESTEN_FORTROLIG
            LIMIT 1
        ]
        .Id;
        Id fortroligSkjermetGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :SERVICETJENESTEN_FORTROLIG_SKJERMET
            LIMIT 1
        ]
        .Id;

        Test.startTest();
        Thread__c thread = new Thread__c(CRM_Account__c = accountId, CRM_Thread_Type__c = 'STO');
        insert thread;
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :veilederGroupId],
            'Expected thread to be shared with group 470011'
        );

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :skjermetGroupId],
            'Expected thread to be NOT shared with group 470013'
        );
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :fortroligGroupId],
            'Expected thread to be NOT shared with group 470012'
        );
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :fortroligSkjermetGroupId],
            'Expected thread to be NOT shared with group 470014'
        );
    }
}
