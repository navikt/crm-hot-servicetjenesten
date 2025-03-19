@isTest
public class HOT_ChatAuthControllerTest {
    @TestSetup
    static void makeData() {
        Case casy = (Case) HOT_ST_TestDataFactory.createRecord(new Case());
        HOT_ST_TestDataFactory.createRecord(new LiveChatTranscript(CaseId = casy.Id));
    }

    @isTest
    static void testGetChatStatus() {
        Map<String, String> chatStatuses;

        Test.startTest();
        LiveChatTranscript chatTranscript = [SELECT Id FROM LiveChatTranscript LIMIT 1];
        chatStatuses = HOT_ChatAuthController.getChatInfo(chatTranscript.Id);

        //Testing exception
        try {
            HOT_ChatAuthController.getChatInfo('FAKEID');
        } catch (Exception ex) {
            System.assertEquals(new AuraHandledException('Test').getTypeName(), ex.getTypeName());
        }
        Test.stopTest();

        System.assertEquals('Not Started', chatStatuses.get('AUTH_STATUS'));
    }

    @isTest
    static void testSetStatusRequested() {
        Test.startTest();
        LiveChatTranscript chatTranscript = [SELECT Id FROM LiveChatTranscript LIMIT 1];
        LiveChatVisitor visitor = [SELECT Id FROM LiveChatVisitor LIMIT 1];
        HOT_ChatAuthController.setStatusRequested(chatTranscript.Id);

        //Testing exception
        try {
            HOT_ChatAuthController.setStatusRequested(visitor.Id);
        } catch (Exception ex) {
            System.assertEquals(new AuraHandledException('Test').getTypeName(), ex.getTypeName());
        }
        Test.stopTest();

        LiveChatTranscript updatedTranscript = [
            SELECT Id, CRM_Authentication_Status__c
            FROM LiveChatTranscript
            WHERE Id = :chatTranscript.Id
        ];

        System.assertEquals('Authentication Requested', updatedTranscript.CRM_Authentication_Status__c);
    }

    @isTest
    static void testSetStatusCompleted() {
        LiveChatTranscript chatTranscript = [SELECT Id FROM LiveChatTranscript LIMIT 1];

        Test.startTest();
        HOT_ChatAuthController.setStatusCompleted(chatTranscript.Id);
        Test.stopTest();

        LiveChatTranscript updatedTranscript = [
            SELECT Id, CRM_Authentication_Status__c
            FROM LiveChatTranscript
            WHERE Id = :chatTranscript.Id
        ];
        System.assertEquals('Completed', updatedTranscript.CRM_Authentication_Status__c);
    }

    @isTest
    static void testGetCommunityAuthUrl() {
        String communityUrl;

        Test.startTest();
        communityUrl = HOT_ChatAuthController.getCommunityAuthUrl();
        Test.stopTest();

        System.assert(String.isNotBlank(communityUrl));
    }

    @isTest
    static void testGetCounselorName() {
        String fullname;
        LiveChatTranscript chatTranscript = [SELECT Id FROM LiveChatTranscript LIMIT 1];

        Test.startTest();
        fullname = HOT_ChatAuthController.getCounselorName(chatTranscript.Id);
        Test.stopTest();

        System.assert(String.isNotBlank(fullname));
    }
}
