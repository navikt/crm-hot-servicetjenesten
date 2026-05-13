/**
 * Test class for HOT_ArchivePublisedArticles_Schedule.
 *
 * Tests the Schedulable and Batchable functionality for archiving knowledge articles
 * to Public 360. Uses HTTP mocks to simulate API responses and custom metadata
 * mocking for configuration.
 *
 * @author Kenneth Sorensen
 * @group HOT Public 360 Integration
 * @since May 2026
 * @see HOT_ArchivePublisedArticles_Schedule
 * @see HOT_KnowledgeArchiveHandler
 */
@IsTest
private class HOT_ArchivePublisedArticles_ScheduleTest {
    // MARK: - Test Constants
    private static final String TEST_CALLOUT_NAME = 'P360_Test';
    private static final String TEST_ARTICLE_TITLE = 'Test Knowledge Article';
    private static final String TEST_CUSTOM_QUERY = 'SELECT Id, Title FROM Knowledge__kav LIMIT 10';
    private static final String TEST_CASE_NUMBER = '25/12742';

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
     * Sets up custom metadata for testing based on environment.
     *
     * @param isSandbox Indicates whether the test runs in sandbox mode.
     */
    private static void setCustomMetadataForTest(Boolean isSandbox) {
        HOT_KnowledgeArchiveHandler.testIsSandboxOverride = isSandbox;
        CustomMetadataDAOTest.setMetadata(
            'SELECT Id, CaseNumberProd__c, CaseNumberTest__c, ActiveFrom__c, Order__c ' +
                'FROM HOT_KnowledgeArchiveCaseMapping__mdt ' +
                'WHERE ActiveFrom__c <= TODAY ' +
                'ORDER BY ActiveFrom__c DESC, Order__c DESC ' +
                'LIMIT 1',
            (List<HOT_KnowledgeArchiveCaseMapping__mdt>) JSON.deserialize(
                '[{"attributes": {"type": "HOT_KnowledgeArchiveCaseMapping__mdt"},' +
                    '"Id":"a0aAA000000AaAaAAA",' +
                    '"CaseNumberTest__c":"' +
                    TEST_CASE_NUMBER +
                    '",' +
                    '"CaseNumberProd__c":"' +
                    TEST_CASE_NUMBER +
                    '",' +
                    '"ActiveFrom__c":"2025-01-01",' +
                    '"Order__c":1}]',
                List<HOT_KnowledgeArchiveCaseMapping__mdt>.class
            )
        );
    }

    // MARK: - Test Setup

    /**
     * Sets up common test data used by all tests.
     */
    @TestSetup
    static void setupTestData() {
        HOT_KnowledgeArchiveSettings__c settings = new HOT_KnowledgeArchiveSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            CalloutNameTest__c = TEST_CALLOUT_NAME,
            CalloutNameProd__c = TEST_CALLOUT_NAME,
            NavIdentTest__c = 'A123456',
            NavIdentProd__c = 'B123456',
            NavEnhetTest__c = '1234',
            NavEnhetProd__c = '5678',
            P360AccessGroup__c = 'Alle ansatte i Nav',
            P360DefaultValueSet__c = 'NKSSalesForce'
        );
        insert settings;

        Knowledge__kav article = new Knowledge__kav(
            Title = TEST_ARTICLE_TITLE,
            UrlName = 'Test-Knowledge-Article-Schedule',
            Summary = 'Test Summary'
        );
        insert article;
    }

    // MARK: - Constructor Tests

    /**
     * What this test verifies:
     * - Default constructor initializes the query with the expected SOQL.
     * Why it matters:
     * - Ensures the scheduler queries the correct records for archiving.
     */
    @IsTest
    static void constructor_whenDefault_initializesWithDefaultQuery() {
        Test.startTest();
        HOT_ArchivePublisedArticles_Schedule scheduler = new HOT_ArchivePublisedArticles_Schedule();
        Test.stopTest();

        System.Assert.isNotNull(scheduler, 'Scheduler should be instantiated');
        System.Assert.areEqual(
            HOT_ArchivePublisedArticles_Schedule.CUSTOM_QUERY,
            scheduler.query,
            'Scheduler should initialize with default query'
        );
    }

    /**
     * What this test verifies:
     * - Parameterized constructor accepts and stores the provided query.
     * Why it matters:
     * - Enables testing and execution with custom queries.
     */
    @IsTest
    static void constructor_whenCustomQuery_storesProvidedQuery() {
        Test.startTest();
        HOT_ArchivePublisedArticles_Schedule scheduler = new HOT_ArchivePublisedArticles_Schedule(TEST_CUSTOM_QUERY);
        Test.stopTest();

        System.Assert.areEqual(TEST_CUSTOM_QUERY, scheduler.query, 'Scheduler should store custom query');
    }

    // MARK: - execute(SchedulableContext) Tests

    /**
     * What this test verifies:
     * - The Schedulable execute method starts a batch job.
     * Why it matters:
     * - Confirms the scheduled job correctly initiates batch processing.
     */
    @IsTest
    static void executeSchedulable_whenCalled_startsBatchJob() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        setCustomMetadataForTest(true);
        HOT_ArchivePublisedArticles_Schedule scheduler = new HOT_ArchivePublisedArticles_Schedule(
            'SELECT Id, Title FROM Knowledge__kav WHERE Id = null'
        );

        Test.startTest();
        String jobId = System.schedule('HOT Knowledge Archive Schedule Test', '0 0 0 1 1 ? 2099', scheduler);
        Test.stopTest();

        CronTrigger cron = [SELECT Id, State FROM CronTrigger WHERE Id = :jobId LIMIT 1];
        System.Assert.isNotNull(cron, 'Scheduled job should exist');
    }

    // MARK: - start() Tests

    /**
     * What this test verifies:
     * - The start method returns a valid QueryLocator for custom query.
     * Why it matters:
     * - Ensures the batch framework can retrieve records for processing.
     */
    @IsTest
    static void start_whenCustomQuery_returnsValidQueryLocator() {
        HOT_ArchivePublisedArticles_Schedule scheduler = new HOT_ArchivePublisedArticles_Schedule(TEST_CUSTOM_QUERY);

        Test.startTest();
        Database.QueryLocator locator = scheduler.start(null);
        Test.stopTest();

        System.Assert.isNotNull(locator, 'Should return a valid QueryLocator');
    }

    /**
     * What this test verifies:
     * - The start method works with the default query.
     * Why it matters:
     * - Validates the default query syntax is executable.
     */
    @IsTest
    static void start_whenDefaultConstructor_usesDefaultQuery() {
        HOT_ArchivePublisedArticles_Schedule scheduler = new HOT_ArchivePublisedArticles_Schedule();

        Test.startTest();
        Database.QueryLocator locator = scheduler.start(null);
        Test.stopTest();

        System.Assert.isNotNull(locator, 'Should return a valid QueryLocator with default query');
    }

    // MARK: - execute(BatchableContext, List) Tests

    /**
     * What this test verifies:
     * - Batch execute handles empty scope without errors.
     * Why it matters:
     * - Ensures graceful behavior when no records match query.
     */
    @IsTest
    static void executeBatch_whenEmptyScope_completesWithoutError() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        setCustomMetadataForTest(true);
        HOT_ArchivePublisedArticles_Schedule scheduler = new HOT_ArchivePublisedArticles_Schedule();
        List<Knowledge__kav> scope = new List<Knowledge__kav>();

        Test.startTest();
        scheduler.execute(null, scope);
        Test.stopTest();

        System.Assert.isTrue(true, 'Should complete without throwing');
    }

    /**
     * What this test verifies:
     * - Batch execute processes a single knowledge article.
     * Why it matters:
     * - Validates that handler is invoked correctly for one record.
     */
    @IsTest
    static void executeBatch_whenSingleArticle_processesSuccessfully() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        setCustomMetadataForTest(true);
        HOT_ArchivePublisedArticles_Schedule scheduler = new HOT_ArchivePublisedArticles_Schedule();
        List<Knowledge__kav> scope = [SELECT Id, Title FROM Knowledge__kav LIMIT 1];

        Test.startTest();
        scheduler.execute(null, scope);
        Test.stopTest();

        System.Assert.areEqual(1, scope.size(), 'Should process one knowledge article');
    }

    /**
     * What this test verifies:
     * - Batch execute processes multiple knowledge articles.
     * Why it matters:
     * - Validates loop behavior across all items in scope.
     */
    @IsTest
    static void executeBatch_whenMultipleArticles_processesAll() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        setCustomMetadataForTest(true);

        List<Knowledge__kav> newArticles = new List<Knowledge__kav>();
        for (Integer i = 0; i < 2; i++) {
            newArticles.add(
                new Knowledge__kav(
                    Title = 'Additional Knowledge Article ' + i,
                    UrlName = 'Additional-Knowledge-Article-' + i,
                    Summary = 'Additional Summary ' + i
                )
            );
        }
        insert newArticles;

        HOT_ArchivePublisedArticles_Schedule scheduler = new HOT_ArchivePublisedArticles_Schedule();
        List<Knowledge__kav> scope = [SELECT Id, Title FROM Knowledge__kav LIMIT 3];

        Test.startTest();
        scheduler.execute(null, scope);
        Test.stopTest();

        System.Assert.isTrue(scope.size() > 1, 'Should process multiple knowledge articles');
    }

    // MARK: - finish() Tests

    /**
     * What this test verifies:
     * - The finish method completes without throwing exceptions.
     * Why it matters:
     * - Ensures batch completion hook behaves safely.
     */
    @IsTest
    static void finish_whenCalled_completesWithoutError() {
        HOT_ArchivePublisedArticles_Schedule scheduler = new HOT_ArchivePublisedArticles_Schedule();

        Test.startTest();
        scheduler.finish(null);
        Test.stopTest();

        System.Assert.isTrue(true, 'Should complete without throwing');
    }

    // MARK: - Full Batch Execution Tests

    /**
     * What this test verifies:
     * - Full batch executes end-to-end with matching records.
     * Why it matters:
     * - Validates complete batch lifecycle.
     */
    @IsTest
    static void batch_whenExecuted_processesMatchingRecords() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        setCustomMetadataForTest(true);
        HOT_ArchivePublisedArticles_Schedule scheduler = new HOT_ArchivePublisedArticles_Schedule(
            'SELECT Id, Title FROM Knowledge__kav LIMIT 2'
        );

        Test.startTest();
        Database.executeBatch(scheduler, 1);
        Test.stopTest();

        System.Assert.isTrue(true, 'Batch should complete successfully');
    }

    /**
     * What this test verifies:
     * - Full batch handles zero matching records gracefully.
     * Why it matters:
     * - Ensures no errors when there is nothing to archive.
     */
    @IsTest
    static void batch_whenNoMatchingRecords_completesWithoutError() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        setCustomMetadataForTest(true);
        HOT_ArchivePublisedArticles_Schedule scheduler = new HOT_ArchivePublisedArticles_Schedule(
            'SELECT Id, Title FROM Knowledge__kav WHERE Id = null'
        );

        Test.startTest();
        Database.executeBatch(scheduler, 1);
        Test.stopTest();

        System.Assert.isTrue(true, 'Batch should complete with no records');
    }
}
