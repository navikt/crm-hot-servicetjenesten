@isTest
public class HOT_RelatedListControllerTest {
    @TestSetup
    static void makeData() {
        Person__c person = new Person__c(Name = '12345678911', INT_ActorId__c = '123');
        insert person;
    }

    @isTest
    static void testGetCRMRelatesList() {
        Person__c person = [SELECT Id FROM Person__c LIMIT 1];

        Test.startTest();
        List<sObject> retList = HOT_RelatedListController.getCRMRelatedList(
            person.Id,
            'Account',
            'CRM_Person__c',
            'Id',
            'Person__c',
            null,
            null,
            null
        );
        Test.stopTest();

        System.assertEquals(1, retList.size());
    }

    @isTest
    static void testGetRelatesList() {
        Person__c person = [SELECT Id FROM Person__c LIMIT 1];

        Test.startTest();
        List<sObject> retList = HOT_RelatedListController.getRelatedList(
            new List<String>{ 'Name' },
            person.Id,
            'Account',
            'CRM_Person__c',
            'Id',
            'Person__c',
            null
        );
        Test.stopTest();

        System.assertEquals(1, retList.size());
    }
}