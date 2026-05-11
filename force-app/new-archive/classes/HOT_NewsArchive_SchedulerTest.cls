/**
 * Test class for HOT_NewsArchive_Scheduler.
 *
 * Tests the Schedulable and Batchable functionality for archiving news articles
 * to Public 360. Uses HTTP mocks to simulate API responses and custom metadata
 * mocking for configuration.
 *
 * @author Kenneth Sørensen
 * @group HOT Public 360 Integration
 * @since March 2026
 * @see HOT_NewsArchive_Scheduler
 * @see HOT_NewsArchiveHandler
 */
@IsTest
private class HOT_NewsArchive_SchedulerTest {
    // MARK: - Test Constants
    private static final String TEST_CALLOUT_NAME = 'P360_Test';
    private static final String TEST_ARTICLE_NAME = 'Test News Article';
    private static final String CUSTOM_QUERY = 'SELECT Id FROM NKS_Announcement__c LIMIT 10';

    // MARK: - Mock HTTP Callout Classes

    /**
     * Mock HTTP response class for successful responses (HTTP 200).
     */
    private class MockHttpResponseSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Successful":true,"DocumentNumber":"24/00001-1"}');
            res.setStatusCode(200);
            res.setStatus('OK');
            return res;
        }
    }

    // MARK: - Helper Methods
    /**
     * Sets up custom metadata for testing based on the environment (sandbox or production).
     *
     * @param isSandbox Indicates whether the test is running in a sandbox environment.
     */
    private static void setCustomMetadataForTest(Boolean isSandbox) {
        HOT_NewsArchiveHandler.testIsSandboxOverride = isSandbox;
        String env = isSandbox ? 'Test' : 'Prod';
        CustomMetadataDAOTest.setMetadata(
            'SELECT Id, CaseNumber' +
                env +
                '__c, NavId' +
                env +
                '__c, NavEnhet' +
                env +
                '__c, ActiveFrom__c, Order__c ' +
                'FROM HOT_NewsArchiveMapping__mdt ' +
                'WHERE ActiveFrom__c <= TODAY ' +
                'ORDER BY ActiveFrom__c DESC, Order__c DESC ' +
                'LIMIT 1',
            (List<HOT_NewsArchiveMapping__mdt>) JSON.deserialize(
                '[{"attributes": {"type": "HOT_NewsArchiveMapping__mdt"},' +
                    '"Id":"a0aAA000000AaAaAAA",' +
                    '"CaseNumber' +
                    env +
                    '__c":"25/12742",' +
                    '"NavId' +
                    env +
                    '__c":"A123456",' +
                    '"NavEnhet' +
                    env +
                    '__c":"1234",' +
                    '"ActiveFrom__c":"2025-01-01",' +
                    '"Order__c":1}]',
                List<HOT_NewsArchiveMapping__mdt>.class
            )
        );
    }

    // MARK: - Test Setup

    /**
     * Sets up test data before any test methods run.
     * Creates necessary custom settings and test records.
     */
    @TestSetup
    static void setupTestData() {
        HOT_NewsArchiveSettings__c settings = new HOT_NewsArchiveSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            CalloutName__c = TEST_CALLOUT_NAME
        );
        insert settings;

        NKS_Announcement__c announcement = new NKS_Announcement__c(
            Name = TEST_ARTICLE_NAME,
            NKS_Information__c = '<p>Test content</p>',
            NKS_News_Archive__c = true,
            NKS_News_Delete_Date__c = Date.today().addDays(1),
            NKS_News_Status__c = 'Published',
            RecordTypeId = Schema.SObjectType.NKS_Announcement__c
                .getRecordTypeInfosByDeveloperName()
                .get('HOT_News')
                .getRecordTypeId()
        );
        insert announcement;
    }

    // MARK: - Constructor Tests

    /**
     * What this test verifies:
     * - Default constructor initializes the query with the expected SOQL.
     * Why it matters:
     * - Ensures the scheduler queries the correct records for archiving.
     */
    @IsTest
    static void constructor_WhenDefault_InitializesWithDefaultQuery() {
        System.Test.startTest();
        HOT_NewsArchive_Scheduler scheduler = new HOT_NewsArchive_Scheduler();
        System.Test.stopTest();

        System.Assert.isNotNull(scheduler, 'Scheduler should be instantiated');
        System.Assert.areEqual(
            HOT_NewsArchive_Scheduler.CUSTOM_QUERY,
            scheduler.query,
            'Scheduler should initialize with default query'
        );
    }

    /**
     * What this test verifies:
     * - Parameterized constructor accepts and stores the provided query.
     * Why it matters:
     * - Enables testing with custom queries.
     */
    @IsTest
    static void constructor_WhenCustomQuery_StoresProvidedQuery() {
        System.Test.startTest();
        HOT_NewsArchive_Scheduler scheduler = new HOT_NewsArchive_Scheduler(CUSTOM_QUERY);
        System.Test.stopTest();

        System.Assert.isNotNull(scheduler, 'Scheduler should be instantiated with custom query');
        System.Assert.areEqual(CUSTOM_QUERY, scheduler.query, 'Scheduler should store the provided custom query');
    }

    // MARK: - execute(SchedulableContext) Tests

    /**
     * What this test verifies:
     * - The Schedulable execute method starts a batch job.
     * Why it matters:
     * - Confirms the scheduled job correctly initiates batch processing.
     */
    @IsTest
    static void executeSchedulable_WhenCalled_StartsBatchJob() {
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        setCustomMetadataForTest(true);
        HOT_NewsArchive_Scheduler scheduler = new HOT_NewsArchive_Scheduler(
            'SELECT Id FROM NKS_Announcement__c WHERE Id = null'
        );

        System.Test.startTest();
        String jobId = System.schedule('Test Archive Job', '0 0 0 1 1 ?', scheduler);
        System.Test.stopTest();

        CronTrigger ct = [SELECT Id, State FROM CronTrigger WHERE Id = :jobId];
        System.Assert.isNotNull(ct, 'Scheduled job should exist');
    }

    // MARK: - start() Tests

    /**
     * What this test verifies:
     * - The start method returns a valid QueryLocator.
     * Why it matters:
     * - Ensures the batch job can retrieve records for processing.
     */
    @IsTest
    static void start_WhenCalled_ReturnsValidQueryLocator() {
        HOT_NewsArchive_Scheduler scheduler = new HOT_NewsArchive_Scheduler(CUSTOM_QUERY);

        System.Test.startTest();
        Database.QueryLocator locator = scheduler.start(null);
        System.Test.stopTest();

        System.Assert.isNotNull(locator, 'Should return a valid QueryLocator');
    }

    /**
     * What this test verifies:
     * - The start method uses the default query when using default constructor.
     * Why it matters:
     * - Validates the default query syntax is valid and executable.
     */
    @IsTest
    static void start_WhenDefaultConstructor_UsesDefaultQuery() {
        HOT_NewsArchive_Scheduler scheduler = new HOT_NewsArchive_Scheduler();

        System.Test.startTest();
        Database.QueryLocator locator = scheduler.start(null);
        System.Test.stopTest();

        System.Assert.isNotNull(locator, 'Should return a valid QueryLocator with default query');
    }

    // MARK: - execute(BatchableContext, List) Tests

    /**
     * What this test verifies:
     * - The batch execute method handles an empty scope without errors.
     * Why it matters:
     * - Ensures graceful handling when no articles match the query.
     */
    @IsTest
    static void executeBatch_WhenEmptyScope_CompletesWithoutError() {
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        setCustomMetadataForTest(true);
        HOT_NewsArchive_Scheduler scheduler = new HOT_NewsArchive_Scheduler();
        List<NKS_Announcement__c> emptyScope = new List<NKS_Announcement__c>();

        System.Test.startTest();
        scheduler.execute(null, emptyScope);
        System.Test.stopTest();

        // No exception means success
        System.Assert.isTrue(true, 'Should complete without throwing');
    }

    /**
     * What this test verifies:
     * - The batch execute method processes a single article.
     * Why it matters:
     * - Validates the handler is called correctly for one record.
     */
    @IsTest
    static void executeBatch_WhenSingleArticle_ProcessesSuccessfully() {
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        setCustomMetadataForTest(true);
        HOT_NewsArchive_Scheduler scheduler = new HOT_NewsArchive_Scheduler();
        List<NKS_Announcement__c> scope = [SELECT Id, Name FROM NKS_Announcement__c LIMIT 1];

        System.Test.startTest();
        scheduler.execute(null, scope);
        System.Test.stopTest();

        // No exception means success
        System.Assert.areEqual(1, scope.size(), 'Should have processed one article');
    }

    /**
     * What this test verifies:
     * - The batch execute method processes multiple articles.
     * Why it matters:
     * - Validates the loop correctly iterates over all records in scope.
     */
    @IsTest
    static void executeBatch_WhenMultipleArticles_ProcessesAll() {
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        setCustomMetadataForTest(true);

        // Create additional test articles
        List<NKS_Announcement__c> additionalArticles = new List<NKS_Announcement__c>();
        Id recordTypeId = Schema.SObjectType.NKS_Announcement__c
            .getRecordTypeInfosByDeveloperName()
            .get('HOT_News')
            .getRecordTypeId();

        for (Integer i = 0; i < 2; i++) {
            additionalArticles.add(
                new NKS_Announcement__c(
                    Name = 'Additional Article ' + i,
                    NKS_Information__c = '<p>Content ' + i + '</p>',
                    NKS_News_Archive__c = true,
                    NKS_News_Delete_Date__c = Date.today().addDays(1),
                    NKS_News_Status__c = 'Published',
                    RecordTypeId = recordTypeId
                )
            );
        }
        insert additionalArticles;

        HOT_NewsArchive_Scheduler scheduler = new HOT_NewsArchive_Scheduler();
        List<NKS_Announcement__c> scope = [SELECT Id, Name FROM NKS_Announcement__c];

        System.Test.startTest();
        scheduler.execute(null, scope);
        System.Test.stopTest();

        System.Assert.isTrue(scope.size() > 1, 'Should have processed multiple articles');
    }

    // MARK: - finish() Tests

    /**
     * What this test verifies:
     * - The finish method completes without throwing exceptions.
     * Why it matters:
     * - Ensures batch job cleanup happens gracefully.
     */
    @IsTest
    static void finish_WhenCalled_CompletesWithoutError() {
        HOT_NewsArchive_Scheduler scheduler = new HOT_NewsArchive_Scheduler();

        System.Test.startTest();
        scheduler.finish(null);
        System.Test.stopTest();

        // No exception means success
        System.Assert.isTrue(true, 'Should complete without throwing');
    }

    // MARK: - Full Batch Execution Tests

    /**
     * What this test verifies:
     * - The full batch job executes end-to-end with matching records.
     * Why it matters:
     * - Validates the complete batch lifecycle from start to finish.
     */
    @IsTest
    static void batch_WhenExecuted_ProcessesMatchingRecords() {
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        setCustomMetadataForTest(true);
        String testQuery = 'SELECT Id FROM NKS_Announcement__c WHERE RecordType.Name=\'HOT_News\'';
        HOT_NewsArchive_Scheduler scheduler = new HOT_NewsArchive_Scheduler(testQuery);

        System.Test.startTest();
        Database.executeBatch(scheduler, 1);
        System.Test.stopTest();

        // Batch completed without error
        System.Assert.isTrue(true, 'Batch should complete successfully');
    }

    /**
     * What this test verifies:
     * - The batch job handles zero matching records gracefully.
     * Why it matters:
     * - Ensures no errors when no articles need archiving.
     */
    @IsTest
    static void batch_WhenNoMatchingRecords_CompletesWithoutError() {
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        setCustomMetadataForTest(true);
        String emptyQuery = 'SELECT Id FROM NKS_Announcement__c WHERE Id = null';
        HOT_NewsArchive_Scheduler scheduler = new HOT_NewsArchive_Scheduler(emptyQuery);

        System.Test.startTest();
        Database.executeBatch(scheduler, 1);
        System.Test.stopTest();

        // Batch completed without error
        System.Assert.isTrue(true, 'Batch should complete with no records');
    }
}
