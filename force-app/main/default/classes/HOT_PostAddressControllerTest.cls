@isTest
public with sharing class HOT_PostAddressControllerTest {
    @TestSetup
    static void makeData() {
        Person__c p = new Person__c(
            Name = '12345678910',
            INT_FirstName__c = 'Harry',
            INT_LastName__c = 'Potter',
            INT_Confidential__c = 'UGRADERT',
            INT_ActorId__c = '1234567899876'
        );
        insert p;

        //Case
        case c = new Case();
        c.subject = '23452345';
        c.status = 'New';
        c.origin = 'Web';
        c.AccountId = [SELECT Id FROM Account WHERE CRM_Person__r.Name = '12345678910' LIMIT 1].Id;
        insert c;

        //LiveChatVisitor
        LiveChatVisitor v = new LiveChatVisitor();
        insert v;

        //LiveChatTranscript
        LiveChatTranscript l = new LiveChatTranscript();
        l.LiveChatVisitorid = v.id;
        l.AccountId = [SELECT Id FROM Account WHERE CRM_Person__r.Name = '12345678910' LIMIT 1].Id;
        insert l;
    }

    @isTest
    public static void getPostAddressAccount() {
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__r.Name = '12345678910' LIMIT 1].Id;
        ApiMock.setTestMock('POST_REGOPPSLAG_API', 200, 'OK');
        Test.startTest();
        HOT_PostAddressController.PostAddress post = HOT_PostAddressController.getPostAddress(accountId, 'Account');
        Test.stopTest();
        System.assertEquals('Norge', post.land);
    }

    @isTest
    public static void getPostAddressCase() {
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__r.Name = '12345678910' LIMIT 1].Id;
        Id caseId = [SELECT Id FROM case WHERE accountId = :accountId LIMIT 1].Id;
        ApiMock.setTestMock('POST_REGOPPSLAG_API', 200, 'OK');
        Test.startTest();
        HOT_PostAddressController.PostAddress post = HOT_PostAddressController.getPostAddress(caseId, 'Case');
        Test.stopTest();
        System.assertEquals('Norge', post.land);
    }

    @isTest
    public static void getPostAddressChat() {
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__r.Name = '12345678910' LIMIT 1].Id;
        Id chatId = [SELECT Id FROM LiveChatTranscript WHERE accountId = :accountId LIMIT 1].Id;
        ApiMock.setTestMock('POST_REGOPPSLAG_API', 200, 'OK');
        Test.startTest();
        HOT_PostAddressController.PostAddress post = HOT_PostAddressController.getPostAddress(
            chatId,
            'LiveChatTranscript'
        );
        Test.stopTest();
        System.assertEquals('Norge', post.land);
    }

    @isTest
    public static void getPostAddressErr() {
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__r.Name = '12345678910' LIMIT 1].Id;
        ApiMock.setTestMock('POST_REGOPPSLAG_API', 500, 'ERROR');
        Test.startTest();
        HOT_PostAddressController.PostAddress post = HOT_PostAddressController.getPostAddress(accountId, 'Account');
        Test.stopTest();
        System.assertEquals(null, post.land);
    }

    @isTest
    public static void getPostAddressErrObj() {
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__r.Name = '12345678910' LIMIT 1].Id;
        ApiMock.setTestMock('POST_REGOPPSLAG_API', 500, 'ERROR');
        Test.startTest();
        HOT_PostAddressController.PostAddress post = HOT_PostAddressController.getPostAddress(accountId, 'Opportunity');
        Test.stopTest();
        //Null pointer exception
    }
}
