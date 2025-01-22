@IsTest
private class HOT_ST_ThreadAccessRecalcBatchTest {
    @TestSetup
    private static void makeData() {
        List<Person__c> personsToInsert = TestDataFactory.getPersons(4, false);

        personsToInsert[0].INT_Confidential__c = 'UGRADERT';
        personsToInsert[0].INT_IsNavEmployee__c = false;

        personsToInsert[1].INT_Confidential__c = 'FORTROLIG';
        personsToInsert[1].INT_IsNavEmployee__c = false;

        personsToInsert[2].INT_Confidential__c = 'UGRADERT';
        personsToInsert[2].INT_IsNavEmployee__c = true;

        personsToInsert[3].INT_Confidential__c = 'FORTROLIG';
        personsToInsert[3].INT_IsNavEmployee__c = true;

        myTriggers.disable(PersonAccessHandler.class);

        insert personsToInsert;

        List<Account> accounts = [SELECT Id FROM Account WHERE CRM_Person__c IN :personsToInsert];

        List<Thread__c> threadsToInsert = new List<Thread__c>{
            new Thread__c(
                CRM_Account__c = accounts[0].id,
                CRM_Thread_Type__c = 'STO',
                STO_Category__c = 'Hjelpemidler'
            ),
            new Thread__c(
                CRM_Account__c = accounts[1].Id,
                CRM_Thread_Type__c = 'STO',
                STO_Category__c = 'Hjelpemidler'
            ),
            new Thread__c(
                CRM_Account__c = accounts[2].Id,
                CRM_Thread_Type__c = 'STO',
                STO_Category__c = 'Hjelpemidler'
            ),
            new Thread__c(CRM_Account__c = accounts[3].Id, CRM_Thread_Type__c = 'STO', STO_Category__c = 'Hjelpemidler')
        };
        myTriggers.disable(HOT_ST_ThreadAccessHandler.class);
        insert threadsToInsert;
        Test.getEventBus().deliver();
    }
    @IsTest
    private static void recalculateSharing() {
        Person__c person = [
            SELECT Id, INT_IsNavEmployee__c, INT_Confidential__c, CRM_Account__c
            FROM Person__c
            WHERE INT_IsNavEmployee__c = FALSE AND INT_Confidential__c = 'UGRADERT'
            LIMIT 1
        ];

        Id veilederGroupId = [
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

        Thread__c thread = [SELECT Id FROM Thread__c WHERE CRM_Account__c = :person.CRM_Account__c LIMIT 1];

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :veilederGroupId
            ],
            'Expected thread not to be shared with group 470011'
        );
        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :skjermetGroupId
            ],
            'Expected thread not to be shared with group 470013'
        );
        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :fortroligGroupId
            ],
            'Expected thread not to be shared with group 470012'
        );
        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :fortroligSkjermetGroupId
            ],
            'Expected thread not to be shared with group 470014'
        );

        Test.startTest();
        HOT_ST_ThreadAccessRecalcBatch batch = new HOT_ST_ThreadAccessRecalcBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :veilederGroupId
            ],
            'Expected thread to be shared with group 470011'
        );
        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :skjermetGroupId
            ],
            'Expected thread not to be shared with group 470013'
        );
        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :fortroligGroupId
            ],
            'Expected thread not to be shared with group 470012'
        );
        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :fortroligSkjermetGroupId
            ],
            'Expected thread not to be shared with group 470014'
        );
    }
}
