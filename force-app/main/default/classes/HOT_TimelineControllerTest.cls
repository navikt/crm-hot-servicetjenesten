@isTest
private class HOT_TimelineControllerTest {
    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'Timeline Test Account');
        insert acc;

        insert new List<Thread__c>{
            new Thread__c(
                CRM_Account__c = acc.Id,
                CRM_Latest_Message_Datetime__c = Datetime.now().addDays(-1),
                CRM_Conversation_Summary__c = 'Summary 1'
            ),
            new Thread__c(
                CRM_Account__c = acc.Id,
                CRM_Latest_Message_Datetime__c = Datetime.now().addMonths(-2),
                CRM_Conversation_Summary__c = 'Summary 2'
            )
        };

        insert new List<Conversation_Note__c>{
            new Conversation_Note__c(
                CRM_Account__c = acc.Id,
                CRM_Date_Time_Registered__c = Datetime.now().addDays(-3),
                CRM_Conversation_Note__c = 'Note content 1'
            ),
            new Conversation_Note__c(
                CRM_Account__c = acc.Id,
                CRM_Date_Time_Registered__c = Datetime.now().addMonths(-3),
                CRM_Conversation_Note__c = 'Note content 2'
            )
        };

        if (Schema.getGlobalDescribe().containsKey('NKS_Call_Log__c')) {
            Schema.SObjectType callLogType = Schema.getGlobalDescribe().get('NKS_Call_Log__c');
            SObject callLog1 = callLogType.newSObject();
            callLog1.put('NKS_Account__c', acc.Id);
            callLog1.put('NKS_Call_Time__c', Datetime.now().addDays(-5));
            callLog1.put('NKS_Timeline_Name__c', 'Call Log 1');

            SObject callLog2 = callLogType.newSObject();
            callLog2.put('NKS_Account__c', acc.Id);
            callLog2.put('NKS_Call_Time__c', Datetime.now().addMonths(-4));
            callLog2.put('NKS_Timeline_Name__c', 'Call Log 2');

            insert new List<SObject>{ callLog1, callLog2 };
        }
    }

    @isTest
    static void testGetRecordsBlankId() {
        System.assertEquals(0, HOT_TimelineController.getRecords('', 10).size());
        System.assertEquals(0, HOT_TimelineController.getRecords(null, 10).size());
    }

    @isTest
    static void testGetRecordsUsesDefaultLimit() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Timeline Test Account' LIMIT 1];

        Test.startTest();
        List<HOT_TimelineController.TimelineGroup> result = HOT_TimelineController.getRecords(acc.Id, null);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assert(result.size() > 0, 'Expected grouped timeline results');
    }

    @isTest
    static void testGetRecordsReturnsGroupedResults() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Timeline Test Account' LIMIT 1];

        Test.startTest();
        List<HOT_TimelineController.TimelineGroup> result = HOT_TimelineController.getRecords(acc.Id, 50);
        Test.stopTest();

        Integer totalModels = 0;
        for (HOT_TimelineController.TimelineGroup groupRecord : result) {
            System.assertNotEquals(null, groupRecord.id);
            System.assertNotEquals(null, groupRecord.name);
            System.assertEquals(groupRecord.models.size(), groupRecord.size);
            totalModels += groupRecord.size;
        }

        Integer expectedTotal = 4 + (Schema.getGlobalDescribe().containsKey('NKS_Call_Log__c') ? 2 : 0);
        System.assertEquals(expectedTotal, totalModels, 'Expected all available records to be returned across groups');
    }

    @isTest
    static void testGetRecordsAppliesChronologicalCutoff() {
        Account acc = new Account(Name = 'Cutoff Account');
        insert acc;

        insert new Thread__c(
            CRM_Account__c = acc.Id,
            CRM_Latest_Message_Datetime__c = Datetime.now().addDays(-1),
            CRM_Conversation_Summary__c = 'Recent thread'
        );
        insert new Conversation_Note__c(
            CRM_Account__c = acc.Id,
            CRM_Date_Time_Registered__c = Datetime.now().addMonths(-3),
            CRM_Conversation_Note__c = 'Old note'
        );

        Test.startTest();
        List<HOT_TimelineController.TimelineGroup> result = HOT_TimelineController.getRecords(acc.Id, 1);
        Test.stopTest();

        Integer totalModels = 0;
        String onlyRecordType;
        for (HOT_TimelineController.TimelineGroup groupRecord : result) {
            for (HOT_TimelineController.TimelineModel model : groupRecord.models) {
                totalModels++;
                onlyRecordType = model.record.sObjectKind;
            }
        }

        System.assertEquals(1, totalModels, 'Expected cutoff logic to hide older incomplete months');
        System.assertEquals('Thread__c', onlyRecordType, 'Expected only the newest non-gapped record type');
    }

    @isTest
    static void testTimelineRecordCompareTo() {
        HOT_TimelineController.TimelineRecord newer = new HOT_TimelineController.TimelineRecord();
        newer.dateValue = Datetime.now();

        HOT_TimelineController.TimelineRecord older = new HOT_TimelineController.TimelineRecord();
        older.dateValue = Datetime.now().addDays(-1);

        System.assertEquals(-1, newer.compareTo(older));
        System.assertEquals(1, older.compareTo(newer));
        System.assertEquals(0, newer.compareTo(newer));
    }

    @isTest
    static void testTimelineModelStructure() {
        HOT_TimelineController.TimelineRecord rec = new HOT_TimelineController.TimelineRecord();
        rec.recordId = UserInfo.getUserId();
        rec.dateValue = Datetime.now();
        rec.sObjectType = 'Thread__c';
        rec.icon = 'standard:messaging_user';
        rec.color = '7D7D7D';
        rec.subtitleOverride = 'Summary';
        rec.customComponent = 'ThreadExpandedTimeline';
        rec.clampLines = 2;
        rec.themeGroupName = 'Group1';
        rec.headers = new List<HOT_TimelineController.Header>{
            new HOT_TimelineController.Header('HeaderA', true),
            new HOT_TimelineController.Header(Datetime.now(), false)
        };

        HOT_TimelineController.TimelineModel model = new HOT_TimelineController.TimelineModel(rec);

        System.assertEquals('Thread__c', model.record.sObjectKind);
        System.assertEquals('standard:messaging_user', model.theme.icon);
        System.assertEquals('Group1', model.filter.picklistValue1);
        System.assertEquals(false, model.filter.shown);
        System.assertEquals(2, model.record.headers.size());
    }
}
