@isTest
public with sharing class HOT_GetStoUtilityControllerTest {
    @TestSetup
    static void makeData() {
        List<Person__c> persons = HOT_STO_TestDataFactory.createPersons(2);
        List<Id> personIds = new List<Id>();
        for (Person__c p : persons) {
            personIds.add(p.Id);
        }
        List<Account> accs = [SELECT Id FROM Account WHERE CRM_Person__c IN :personIds];

        Group testGroup = new Group(Name = 'TEST GROUP', Type = 'Queue');
        insert testGroup;

        System.runAs(new User(Id = UserInfo.getUserId())) {
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Case');
            insert testQueue;
        }

        String STO_RECORD_TYPE = Case.getSObjectType()
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('STO_Case')
            .getRecordTypeId();

        Case c = new Case();
        c.AccountId = accs[0].Id;
        c.Status = 'New';
        c.Origin = 'STO';
        c.STO_Category__c = 'Familie';
        c.OwnerId = testGroup.Id;
        c.RecordTypeId = STO_RECORD_TYPE;

        HOT_UTIL_TestDataFactory.createRecordList(c, 2);
    }

    @isTest
    static void testGetSto() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User usr = HOT_TestDataFactory.createUser('user', profile);
        insert usr;
        // User usr = (User) HOT_UTIL_TestDataFactory.createRecord(new User());
        List<HOT_GetStoUtilityController.Record> records;
        List<HOT_GetStoUtilityController.Record> noRecord;
        List<HOT_GetStoUtilityController.Record> ownedList;

        Test.startTest();
        System.runAs(usr) {
            records = HOT_GetStoUtilityController.getSto();
            ownedList = HOT_GetStoUtilityController.getList('10');
        }
        delete [SELECT Id FROM Case];
        System.runAs(usr) {
            try {
                noRecord = HOT_GetStoUtilityController.getSto();
                System.assert(false);
            } catch (AuraHandledException auraEx) {
                System.assert(true);
            }
        }
        Test.stopTest();

        System.assertNotEquals(0, records.size());
        System.assertEquals(2, ownedList.size());
    }
}
