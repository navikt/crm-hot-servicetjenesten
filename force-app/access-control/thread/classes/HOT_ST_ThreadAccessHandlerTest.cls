@IsTest
private class HOT_ST_ThreadAccessHandlerTest {
    @TestSetup
    static void makeData() {
        //we don't want person trigger access handlers to be run on test data insert
        myTriggers.disable(PersonAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;
    }

    @IsTest
    private static void grantAccessWhenUgradertAndNotNavEmployee() {
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        Id groupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :HOT_ST_ThreadAccessService.SERVICETJENESTEN_VEILEDERE
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
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread to be shared with group 410011'
        );
    }

    @IsTest
    private static void grantAccessOnCategoryChange() {
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        Id groupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :HOT_ST_ThreadAccessService.SERVICETJENESTEN_VEILEDERE
            LIMIT 1
        ]
        .Id;

        Thread__c thread = new Thread__c(
            CRM_Account__c = accountId,
            CRM_Thread_Type__c = 'STO',
            STO_Category__c = 'Arbeid'
        );
        insert thread;
        Test.getEventBus().deliver();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread not to be shared with group 410011'
        );

        Test.startTest();
        thread.STO_Category__c = 'Hjelpemidler';
        update thread;
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread to be shared with group 410011'
        );
    }

    @IsTest
    private static void revokeAccessWhenOnCategoryChange() {
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        Id groupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :HOT_ST_ThreadAccessService.SERVICETJENESTEN_VEILEDERE
            LIMIT 1
        ]
        .Id;

        Thread__c thread = new Thread__c(
            CRM_Account__c = accountId,
            CRM_Thread_Type__c = 'STO',
            STO_Category__c = 'Hjelpemidler'
        );
        insert thread;
        Test.getEventBus().deliver();
        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread to be shared with group 410011'
        );
        Test.startTest();
        thread.STO_Category__c = 'Arbeid';
        update thread;
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread to be not shared with group 410011'
        );
    }

    @IsTest
    private static void grantAccessWhenFortrolig() {
        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'FORTROLIG';
        person.INT_IsNavEmployee__c = false;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id veiledereGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :HOT_ST_ThreadAccessService.SERVICETJENESTEN_VEILEDERE
            LIMIT 1
        ]
        .Id;
        Id code7GroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :HOT_ST_ThreadAccessService.SERVICETJENESTEN_FORTROLIG
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
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :veiledereGroupId],
            'Expected thread not to be shared with veiledere'
        );

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :code7GroupId],
            'Expected thread to be shared with code 7 group'
        );
    }

    @IsTest
    private static void grantAccessWhenNavEmployee() {
        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = true;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id veiledereGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :HOT_ST_ThreadAccessService.SERVICETJENESTEN_VEILEDERE
            LIMIT 1
        ]
        .Id;
        Id skjermetGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :HOT_ST_ThreadAccessService.SERVICETJENESTEN_SKJERMET
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
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :veiledereGroupId],
            'Expected thread not to be shared with veiledere'
        );

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :skjermetGroupId],
            'Expected thread to be shared with skjermet group'
        );
    }

    @IsTest
    private static void grantAccessWhenConfEmployee() {
        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'FORTROLIG';
        person.INT_IsNavEmployee__c = true;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id veiledereGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :HOT_ST_ThreadAccessService.SERVICETJENESTEN_VEILEDERE
            LIMIT 1
        ]
        .Id;
        Id skjermetGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :HOT_ST_ThreadAccessService.SERVICETJENESTEN_SKJERMET
            LIMIT 1
        ]
        .Id;
        Id fortroligGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :HOT_ST_ThreadAccessService.SERVICETJENESTEN_FORTROLIG
            LIMIT 1
        ]
        .Id;
        Id fortroligSkjermetGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :HOT_ST_ThreadAccessService.SERVICETJENESTEN_FORTROLIG_SKJERMET
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
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :veiledereGroupId],
            'Expected thread NOT to be shared with veiledere'
        );

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :fortroligGroupId],
            'Expected thread NOT to be shared with fortrolig'
        );

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :skjermetGroupId],
            'Expected thread NOT to be shared with skjermet group'
        );

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :fortroligSkjermetGroupId],
            'Expected thread to be shared with fortrolig skjermet group'
        );
    }
}
