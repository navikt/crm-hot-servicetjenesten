@isTest
public with sharing class HOT_PostAddressControllerTest {
    @isTest
    public static void getPostAddressTest() {
        Person__c p = new Person__c(
            Name = '12345678910',
            INT_FirstName__c = 'Harry',
            INT_LastName__c = 'Potter',
            INT_Confidential__c = 'UGRADERT',
            INT_ActorId__c = '1234567899876'
        );
        insert p;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__r.Name = '12345678910' LIMIT 1].Id;
        ApiMock.setTestMock('POST_REGOPPSLAG_API', 200, 'OK');
        Test.startTest();
        HOT_PostAddressController.PostAddress post = HOT_PostAddressController.getPostAddress(accountId, 'Account');
        Test.stopTest();
        System.assertEquals('Norge', post.land);
    }
}
