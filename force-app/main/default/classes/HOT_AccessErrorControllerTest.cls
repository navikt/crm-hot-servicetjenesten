@isTest
private without sharing class HOT_AccessErrorControllerTest {
    @IsTest
    static void checkAccess() {
        Person__c p = (Person__c) HOT_ST_TestDataFactory.createRecord(
            new Person__c(
                INT_ActorId__c = '100003000120',
                INT_Confidential__c = 'FORTROLIG',
                INT_FirstName__c = 'Harry',
                INT_IsNavEmployee__c = true,
                INT_LastName__c = 'Potter'
            ),
            true
        );

        p = [SELECT Id, CRM_Account__c FROM Person__c WHERE Id = :p.Id];

        String result;

        Test.startTest();
        result = HOT_AccessErrorController.checkAccess('CRM_Person__c', 'Account', p.CRM_Account__c);
        Test.stopTest();

        System.assertEquals(null, result, 'null');
    }
}