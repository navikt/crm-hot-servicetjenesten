@isTest
private class HOT_ChatTranscriptService_Test {
    @TestSetup
    static void makeData() {
        String botConversation = '22:15:14 - bot:\n';
        botConversation += 'Det er mange som vil snakke med oss nå. Hold chatten åpen og følg med, så svarer vi deg så snart vi kan.\n';
        botConversation += '22:15:14 - bot:\n';
        botConversation = 'Jeg setter deg over, et øyeblikk.\n';

        Case botCase = (Case) HOT_ST_TestDataFactory.createRecord(new Case(Description = botConversation));

        List<LiveChatTranscript> transcripts = new List<LiveChatTranscript>();
        for (Integer i = 0; i < 10; i++) {
            transcripts.add(
                new LiveChatTranscript(
                    NKS_Journal_Entry_Created__c = true,
                    Body = 'TESTBODY',
                    CaseId = botCase.Id,
                    NKS_Journal_Entry_ID__c = HOT_ST_TestDataFactory.generateRandomNumberString(10),
                    CRM_Authentication_Status__c = 'Completed',
                    NKS_Authentication_Timestamp__c = Datetime.now()
                )
            );
        }
        HOT_ST_TestDataFactory.createRecord(
            new Thread__c(
                CRM_Related_Object__c = (String) HOT_ST_TestDataFactory.createRecordList(transcripts)[0].get('Id')
            )
        );

        User testUser = new User();
        testUser.CRM_NAV_Ident__c = 'Z999998';
        HOT_ST_TestDataFactory.createRecord(testUser);
    }

    @isTest
    static void testStoreConversation() {
        LiveChatTranscript transcript = [SELECT Id, NKS_Conversation__c FROM LiveChatTranscript LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE CRM_NAV_Ident__c = 'Z999998'];

        StaticResource testConversation = [
            SELECT Id, Body
            FROM StaticResource
            WHERE Name = 'HOT_Chat_Conversation_Mock'
        ];
        String conversation = testConversation.Body.toString();

        Test.startTest();
        HOT_ChatTranscriptService.navIdentUserMap.clear();
        HOT_ChatTranscriptService.navIdentUserMap.put('Z999998', testUser);
        HOT_ChatTranscriptService.storeConversation(transcript.Id, conversation);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Thread__c WHERE CRM_Related_Object__c = :transcript.Id]);
    }

    @isTest
    static void testGetChatTranscript() {
        LiveChatTranscript transcript = [SELECT Id, NKS_Conversation__c FROM LiveChatTranscript LIMIT 1];
        LiveChatTranscript result;
        Test.startTest();
        result = HOT_ChatTranscriptService.getChatTranscript(transcript.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGenerateAuthMessage() {
        LiveChatTranscript transcript = [SELECT Id FROM LiveChatTranscript LIMIT 1];
        Test.startTest();
        String result = HOT_ChatTranscriptService.generateAuthMessage(transcript.Id);
        Test.stopTest();
        String expectedText = HOT_ChatTranscriptService.authTexts.get('norwegian');

        Assert.areEqual(expectedText, result);
    }
}
