@isTest
public with sharing class HOT_HomePageControllerTest {
    /*
    @TestSetup
    static void makeData() {
        Id SFUpdateRecordTypeId = Schema.SObjectType.NKS_Announcement__c.getRecordTypeInfosByName()
            .get('Salesforce Update')
            .getRecordTypeId();
        Id campaignRecordTypeId = Schema.SObjectType.NKS_Announcement__c.getRecordTypeInfosByName()
            .get('Campaign')
            .getRecordTypeId();
        Id newsRecordTypeId = Schema.SObjectType.NKS_Announcement__c.getRecordTypeInfosByName()
            .get('News')
            .getRecordTypeId();
        Id nksStatusRecordTypeId = Schema.SObjectType.NKS_Announcement__c.getRecordTypeInfosByName()
            .get('NKS Status')
            .getRecordTypeId();
        Id nksCurrentRecordTypeId = Schema.SObjectType.NKS_Announcement__c.getRecordTypeInfosByName()
            .get('NKS Current')
            .getRecordTypeId();

        NKS_TestDataFactory.createAnnouncements(1, SFUpdateRecordTypeId);
        NKS_TestDataFactory.createAnnouncements(1, campaignRecordTypeId);
        NKS_TestDataFactory.createAnnouncements(1, newsRecordTypeId);
        NKS_TestDataFactory.createAnnouncements(1, nksStatusRecordTypeId);

        List<NKS_Announcement__c> announcements = new List<NKS_Announcement__c>();
        for (Integer i = 0; i < 6; i++) {
            announcements.add(
                new NKS_Announcement__c(
                    Name = 'Test Announcement ' + i,
                    NKS_Link_URL__c = 'https://example.com/' + i,
                    RecordTypeId = nksCurrentRecordTypeId
                )
            );
        }
        insert announcements;

        Knowledge__kav testKnowledge = new Knowledge__kav(
            Title = 'Test Article',
            UrlName = 'Test-Article',
            Summary = 'Informasjon for test'
        );
        insert testKnowledge;

        Case testCase = new Case();
        insert testCase;
    }

    @isTest
    static void testGetField() {
        Test.startTest();
        String info = HOT_HomePageController.getField('Salesforce_Update');
        Test.stopTest();

        Assert.areEqual(700, info.length());
    }

    @isTest
    static void testGetFieldWithNullValue() {
        Test.startTest();
        String info = HOT_HomePageController.getField('Traffic');
        Test.stopTest();

        Assert.areEqual('', info);
    }

    @isTest
    static void testGetListAnnouncement() {
        Test.startTest();
        List<HOT_HomePageController.RecordWrapper> recordlist = HOT_HomePageController.getAnnouncementList(
            'Name',
            'NKS_Information__c',
            'NKS_TypeFormula__c != null',
            'LastModifiedDate DESC',
            '3',
            'CreatedDate',
            true,
            true,
            new List<String>()
        );
        Test.stopTest();

        Assert.areNotEqual(0, recordlist.size());
    }

    @isTest
    static void testGetListKnowledge() {
        Test.startTest();
        List<HOT_HomePageController.RecordWrapper> recordlist = HOT_HomePageController.getKnowledgeList(
            'Title',
            null,
            'LastModifiedDate = LAST_N_DAYS:30 AND Title != \'\'',
            'LastModifiedDate DESC',
            '3',
            'CreatedDate',
            false,
            false,
            null
        );
        Test.stopTest();

        Assert.areNotEqual(0, recordlist.size());
    }

    @isTest
    static void testGetListCase() {
        Test.startTest();
        List<HOT_HomePageController.RecordWrapper> recordlist = HOT_HomePageController.getCaseList(
            'CaseNumber',
            null,
            'Status IN (\'New\', \'In progress\', \'Reserved\')',
            'LastModifiedDate DESC',
            '3',
            'CreatedDate'
        );
        Test.stopTest();

        Assert.areNotEqual(0, recordlist.size());
    }

    @isTest
    static void testGetListWithNullValue() {
        Test.startTest();
        List<HOT_HomePageController.RecordWrapper> recordlist = HOT_HomePageController.getList(
            'Title',
            null,
            'Knowledge__kav',
            'publishStatus=\'Online\'',
            'LastModifiedDate DESC',
            '3',
            'CreatedDate'
        );
        Test.stopTest();

        Assert.areEqual(0, recordlist.size());
    }

    @isTest
    static void testGetUserSkills() {
        //User testUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        List<String> testSkills;
        Test.startTest();
        testSkills = HOT_HomePageController.getUserSkills();
        Test.stopTest();

        if (testSkills.size() > 0) {
            Assert.areNotEqual(0, testSkills.size());
        } else {
            Assert.areEqual(0, testSkills.size());
        }
    }

    @isTest
    static void testGetCampaign() {
        Test.startTest();
        NKS_Announcement__c testCampaign = HOT_HomePageController.getCampaign();
        Test.stopTest();
        Assert.areEqual(null, testCampaign);
    }

    @isTest
    static void testGetNews() {
        NKS_Announcement__c obj = [SELECT Id FROM NKS_Announcement__c WHERE NKS_TypeFormula__c = 'Nyhet' LIMIT 1];
        Test.startTest();
        NKS_Announcement__c testNews = HOT_HomePageController.getNews(obj.Id);
        Test.stopTest();
        Assert.areNotEqual(null, testNews);
    }

    @isTest
    static void testGetReadyResponse() {
        Test.startTest();
        List<Knowledge__kav> testList = HOT_HomePageController.getReadyResponses();
        Test.stopTest();

        Assert.areEqual(null, testList);
    }

    @isTest
    static void testRemoveHtmlTags() {
        String info = '<p><span style="color:rgb(0,0,0);font-size:14px;">Test String</span></p>';
        List<String> testList = new List<String>();
        testList.add(info);
        Test.startTest();
        List<String> res = HOT_HomePageController.removeHtmlTags(testList);
        Test.stopTest();

        Assert.areEqual('Test String', res[0]);
    }

    @isTest
    static void testGetImageUrlNULL() {
        NKS_Announcement__c testNews = [SELECT Id FROM NKS_Announcement__c WHERE NKS_TypeFormula__c = 'Nyhet' LIMIT 1];
        Test.startTest();
        String testURL = HOT_HomePageController.getImageUrl(testNews.Id);
        Test.stopTest();

        Assert.areEqual(null, testURL);
    }

    @isTest
    static void testGetImageUrl() {
        NKS_Announcement__c testNews = [SELECT Id FROM NKS_Announcement__c WHERE NKS_TypeFormula__c = 'Nyhet' LIMIT 1];

        ContentVersion content = new ContentVersion();
        content.Title = 'Header_Picture1';
        content.PathOnClient = '/' + content.Title + '.jpg';
        content.VersionData = Blob.valueOf('Unit Test ContentVersion Body');
        content.origin = 'H';
        insert content;

        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = testNews.id;
        contentlink.contentdocumentid = [SELECT contentDocumentId FROM ContentVersion WHERE id = :content.id]
        .contentDocumentId;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers';
        insert contentlink;

        Test.startTest();
        String testURL = HOT_HomePageController.getImageUrl(testNews.Id);
        Test.stopTest();

        Assert.areNotEqual(null, testURL);
    }

    // Not possible to insert UserAppInfo and AppDefinition, so this is just for coverage
    @isTest
    static void testGetUsersCurrentApp() {
        Test.startTest();
        HOT_HomePageController.getUsersCurrentApp();
        Test.stopTest();
    }

    // Not possible to insert UserAppInfo and AppDefinition, so this is just for coverage
    @isTest
    static void testUpdateUsersCurrentApp() {
        Test.startTest();
        HOT_HomePageController.updateUsersCurrentApp('NewApp');
        Test.stopTest();
    }

    @isTest
    static void testGetNksStatus() {
        Test.startTest();
        NKS_Announcement__c testNksStatus = HOT_HomePageController.getNksStatus('Test 0');
        Test.stopTest();

        Assert.areNotEqual(null, testNksStatus);
    }

    @isTest
    static void testUpdateNksStatus_SuccessfulUpdate() {
        NKS_Announcement__c status = [
            SELECT Id, Name
            FROM NKS_Announcement__c
            WHERE NKS_TypeFormula__c = 'NKS status'
            LIMIT 1
        ];

        Map<String, String> fields = new Map<String, String>{
            'Id' => status.Id,
            'NKS_Information__c' => 'Updated Information'
        };

        Test.startTest();
        HOT_HomePageController.updateNksStatus(fields);
        Test.stopTest();

        NKS_Announcement__c updatedStatus = [SELECT NKS_Information__c FROM NKS_Announcement__c WHERE Id = :status.Id];
        Assert.areEqual(
            'Updated Information',
            updatedStatus.NKS_Information__c,
            'The NKS_Information__c field should be updated.'
        );
    }

    @isTest
    static void testGetNksCurrents() {
        Test.startTest();
        List<NKS_Announcement__c> result = HOT_HomePageController.getNksCurrents();
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual(5, result.size(), 'Should return only 5 latest announcements');
        Assert.isTrue(
            result[0].NKS_Link_URL__c.startsWith('https://example.com'),
            'URL should be present in the result'
        );
    }

    @isTest
    static void testCreateNksCurrent() {
        String testTitle = 'New Test Announcement';
        String testURL = 'https://newtest.com';

        Test.startTest();
        HOT_HomePageController.createNksCurrent(testTitle, testURL);
        Test.stopTest();

        List<NKS_Announcement__c> insertedRecords = [
            SELECT Id, Name, NKS_Link_URL__c, RecordType.DeveloperName
            FROM NKS_Announcement__c
            WHERE Name = :testTitle
        ];

        Assert.areEqual(1, insertedRecords.size(), 'A new Announcement should have been created.');
        Assert.areEqual(testTitle, insertedRecords[0].Name, 'The title of the record should match the input.');
        Assert.areEqual(testURL, insertedRecords[0].NKS_Link_URL__c, 'The URL of the record should match the input.');
        Assert.areEqual(
            'NKS_Current',
            insertedRecords[0].RecordType.DeveloperName,
            'The RecordType should be NKS_Current.'
        );
    }
        */
}
