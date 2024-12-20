@isTest
public with sharing class HOT_STORecordInfoControllerTest {
    @TestSetup
    static void makeData() {
        Person__c person = new Person__c(
            Name = '1234567890',
            INT_MunicipalityNumber__c = '0301',
            INT_FirstName__c = 'Navn',
            INT_LastName__c = 'Navnesen',
            INT_Confidential__c = 'UGRADERT',
            INT_MaritalStatus__c = 'UOPPGITT'
        );
        insert person;

        String personAccountRecordType = Schema.getGlobalDescribe()
            .get('Account')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();
        Account account = new Account(
            FirstName = 'Navn',
            LastName = 'Navnesen',
            INT_PersonIdent__c = '1234567890',
            RecordTypeId = personAccountRecordType,
            CRM_Person__c = person.Id
        );
        insert account;

        HOT_ST_TestDataFactory.createRecord(new Thread__c());
    }

    @isTest
    static void getRelatedRecordTest() {
        Account testAccount = [SELECT Id FROM Account WHERE LastName = 'Navnesen' LIMIT 1];
        Test.startTest();
        testAccount = (Account) HOT_STORecordInfoController.getRelatedRecord(
            String.valueOf(testAccount.Id),
            'CRM_Person__c',
            'Account'
        );
        Test.stopTest();
        System.assertNotEquals(null, testAccount.CRM_Person__c);
    }

    @isTest
    static void testGetByApiReference() {
        String apiRef = [SELECT CRM_API_Reference__c FROM Thread__c LIMIT 1]?.CRM_API_Reference__c;

        System.assertNotEquals(null, HOT_STORecordInfoController.getThreadIdByApiReference(apiRef));
    }
}
