/**
 * Test class for HOT_KnowledgeArchiveHandler.
 *
 * Note: Custom Metadata (HOT_KnowledgeArchiveCaseMapping__mdt) cannot be inserted in tests.
 * The getKnowledgeArchiveCaseMapping() method queries real metadata, so full coverage
 * of sandbox vs production branches depends on the org's metadata configuration.
 * The @TestVisible annotation on private methods allows direct testing of isolated logic.
 *
 * @author Kenneth Sørensen
 * @group HOT Public 360 Integration
 * @since May 2026
 * @see HOT_KnowledgeArchiveHandler
 */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.ApexDoc,PMD.MethodNamingConventions')
@IsTest
private class HOT_KnowledgeArchiveHandlerTest {
    // MARK: - Test Constants
    private static final String TEST_CASE_NUMBER = '25/12345';
    private static final String TEST_CASE_NUMBER_PROD = 'PROD/99999';
    private static final String TEST_NAV_IDENT = 'A123456';
    private static final String TEST_NAV_IDENT_PROD = 'PRD1234';
    private static final String TEST_NAV_ENHET = '1234';
    private static final String TEST_NAV_ENHET_PROD = 'PROD_ENHET';
    private static final String TEST_CALLOUT_NAME = 'P360_Test';
    private static final String TEST_ARTICLE_TITLE = 'Test Knowledge Article';

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

    /**
     * Mock HTTP response class for failed responses (HTTP 500).
     */
    private class MockHttpResponseFailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Successful":false,"ErrorMessage":"Internal Server Error"}');
            res.setStatusCode(500);
            res.setStatus('Internal Server Error');
            return res;
        }
    }

    private static void setCustomMetadataForTest(Boolean isSandbox) {
        HOT_KnowledgeArchiveHandler.testIsSandboxOverride = isSandbox;
        String env = isSandbox ? 'Test' : 'Prod';
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
                    TEST_CASE_NUMBER_PROD +
                    '",' +
                    '"ActiveFrom__c":"2025-01-01",' +
                    '"Order__c":1}]',
                List<HOT_KnowledgeArchiveCaseMapping__mdt>.class
            )
        );
    }

    private static void setNoCustomMetadataForTest(Boolean isSandbox) {
        HOT_KnowledgeArchiveHandler.testIsSandboxOverride = isSandbox;
        CustomMetadataDAOTest.setMetadata(
            'SELECT Id, CaseNumberProd__c, CaseNumberTest__c, ActiveFrom__c, Order__c ' +
                'FROM HOT_KnowledgeArchiveCaseMapping__mdt ' +
                'WHERE ActiveFrom__c <= TODAY ' +
                'ORDER BY ActiveFrom__c DESC, Order__c DESC ' +
                'LIMIT 1',
            new List<HOT_KnowledgeArchiveCaseMapping__mdt>()
        );
    }

    // MARK: - Test Setup

    /**
     * Sets up test data before any test methods run.
     * Creates necessary custom settings and test records.
     */
    @TestSetup
    static void setupTestData() {
        HOT_KnowledgeArchiveSettings__c settings = new HOT_KnowledgeArchiveSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            CalloutNameTest__c = TEST_CALLOUT_NAME,
            CalloutNameProd__c = TEST_CALLOUT_NAME,
            NavIdentTest__c = TEST_NAV_IDENT,
            NavIdentProd__c = TEST_NAV_IDENT_PROD,
            NavEnhetTest__c = TEST_NAV_ENHET,
            NavEnhetProd__c = TEST_NAV_ENHET_PROD,
            P360AccessGroup__c = 'Alle ansatte i Nav',
            P360DefaultValueSet__c = 'NKSSalesForce'
        );
        insert settings;

        Knowledge__kav article = new Knowledge__kav(
            Title = TEST_ARTICLE_TITLE,
            UrlName = 'Test-Knowledge-Article',
            Summary = 'Test Summary'
        );
        insert article;
    }

    // MARK: - Constructor Tests

    /**
     * What this test verifies:
     * - Constructor initializes without throwing exceptions when settings exist.
     * Why it matters:
     * - Ensures the handler can be instantiated in a valid org configuration.
     *
     * @see HOT_KnowledgeArchiveHandler
     */
    @IsTest
    static void constructor_whenSettingsExist_initializesSuccessfully() {
        Test.startTest();
        HOT_KnowledgeArchiveHandler handler = new HOT_KnowledgeArchiveHandler();
        Test.stopTest();

        System.Assert.isNotNull(handler, 'Handler should be instantiated');
    }

    // MARK: - execute() Tests

    /**
     * What this test verifies:
     * - execute() handles the case when metadata settings exist and all values are populated in sandbox.
     * Why it matters:
     * - Validates the happy path where all configuration is properly set up for sandbox environment.
     *
     * @see HOT_KnowledgeArchiveHandler.execute
     */
    @IsTest
    static void execute_whenInSandboxWithMetadataSettings_processesWithoutError() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        setCustomMetadataForTest(true);
        Knowledge__kav article = [SELECT Id, Title FROM Knowledge__kav LIMIT 1];
        HOT_KnowledgeArchiveHandler handler = new HOT_KnowledgeArchiveHandler();

        Test.startTest();
        handler.execute(article);
        Test.stopTest();

        System.Assert.isNotNull(handler, 'Handler should complete execution');
    }

    /**
     * What this test verifies:
     * - execute() handles the case when metadata settings exist and all values are populated in production.
     * Why it matters:
     * - Validates the happy path where all configuration is properly set up for production environment.
     *
     * @see HOT_KnowledgeArchiveHandler.execute
     */
    @IsTest
    static void execute_whenInProductionWithMetadataSettings_processesWithoutError() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        setCustomMetadataForTest(false);
        Knowledge__kav article = [SELECT Id, Title FROM Knowledge__kav LIMIT 1];
        HOT_KnowledgeArchiveHandler handler = new HOT_KnowledgeArchiveHandler();

        Test.startTest();
        handler.execute(article);
        Test.stopTest();

        System.Assert.isNotNull(handler, 'Handler should complete execution');
    }

    /**
     * What this test verifies:
     * - execute() handles the case when the HTTP callout fails (non-200 response).
     * Why it matters:
     * - Ensures errors from Public 360 API are handled gracefully without throwing exceptions.
     *
     * @see HOT_KnowledgeArchiveHandler.execute
     */
    @IsTest
    static void execute_whenCalloutFails_handlesErrorGracefully() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseFailure());
        setCustomMetadataForTest(true);
        Knowledge__kav article = [SELECT Id, Title FROM Knowledge__kav LIMIT 1];
        HOT_KnowledgeArchiveHandler handler = new HOT_KnowledgeArchiveHandler();

        Test.startTest();
        handler.execute(article);
        Test.stopTest();

        System.Assert.isNotNull(handler, 'Handler should complete execution without throwing');
        System.Assert.areEqual(500, handler.operationResponse.getStatusCode(), 'Should have received error response');
    }

    /**
     * What this test verifies:
     * - execute() returns early when no archive metadata is found.
     * Why it matters:
     * - Ensures handler handles missing metadata safely without performing callouts.
     *
     * @see HOT_KnowledgeArchiveHandler.execute
     */
    @IsTest
    static void execute_whenMetadataMissing_returnsEarlyWithoutCallout() {
        setNoCustomMetadataForTest(true);
        Knowledge__kav article = [SELECT Id, Title FROM Knowledge__kav LIMIT 1];
        HOT_KnowledgeArchiveHandler handler = new HOT_KnowledgeArchiveHandler();

        Test.startTest();
        handler.execute(article);
        Test.stopTest();

        System.Assert.isNull(handler.operationResponse, 'No callout should be performed when metadata is missing');
    }

    /**
     * What this test verifies:
     * - execute() returns early when custom settings are missing (NAV ident/enhet cannot be resolved).
     * Why it matters:
     * - Ensures handler fails safely when required org settings are not configured.
     *
     * @see HOT_KnowledgeArchiveHandler.execute
     */
    @IsTest
    static void execute_whenSettingsMissing_returnsEarlyWithoutCallout() {
        setCustomMetadataForTest(true);
        delete [
            SELECT Id
            FROM HOT_KnowledgeArchiveSettings__c
            WHERE SetupOwnerId = :UserInfo.getOrganizationId()
            LIMIT 1
        ];

        Knowledge__kav article = [SELECT Id, Title FROM Knowledge__kav LIMIT 1];
        HOT_KnowledgeArchiveHandler handler = new HOT_KnowledgeArchiveHandler();

        Test.startTest();
        handler.execute(article);
        Test.stopTest();

        System.Assert.isNull(handler.operationResponse, 'No callout should be performed when settings are missing');
    }

    // MARK: - getCaseNumber() Tests

    /**
     * What this test verifies:
     * - getCaseNumber() returns null when settings parameter is null.
     * Why it matters:
     * - Ensures method handles null input gracefully without throwing exceptions.
     *
     * @see HOT_KnowledgeArchiveHandler.getCaseNumber
     */
    @IsTest
    static void getCaseNumber_whenSettingsNull_returnsNull() {
        HOT_KnowledgeArchiveHandler.testIsSandboxOverride = true;
        HOT_KnowledgeArchiveHandler handler = new HOT_KnowledgeArchiveHandler();

        Test.startTest();
        String result = handler.getCaseNumber(null);
        Test.stopTest();

        System.Assert.isNull(result, 'Should return null when settings are null');
    }

    /**
     * What this test verifies:
     * - getCaseNumber() returns the test case number when in sandbox environment.
     * Why it matters:
     * - Ensures correct case number is used in sandbox for archiving.
     *
     * @see HOT_KnowledgeArchiveHandler.getCaseNumber
     */
    @IsTest
    static void getCaseNumber_whenInSandbox_returnsTestCaseNumber() {
        HOT_KnowledgeArchiveHandler.testIsSandboxOverride = true;
        HOT_KnowledgeArchiveHandler handler = new HOT_KnowledgeArchiveHandler();
        HOT_KnowledgeArchiveCaseMapping__mdt settings = new HOT_KnowledgeArchiveCaseMapping__mdt(
            CaseNumberTest__c = TEST_CASE_NUMBER,
            CaseNumberProd__c = TEST_CASE_NUMBER_PROD
        );

        Test.startTest();
        String result = handler.getCaseNumber(settings);
        Test.stopTest();

        System.Assert.areEqual(TEST_CASE_NUMBER, result, 'Should return test case number in sandbox');
    }

    /**
     * What this test verifies:
     * - getCaseNumber() returns the production case number when in production environment.
     * Why it matters:
     * - Ensures correct case number is used in production for archiving.
     *
     * @see HOT_KnowledgeArchiveHandler.getCaseNumber
     */
    @IsTest
    static void getCaseNumber_whenInProduction_returnsProdCaseNumber() {
        HOT_KnowledgeArchiveHandler.testIsSandboxOverride = false;
        HOT_KnowledgeArchiveHandler handler = new HOT_KnowledgeArchiveHandler();
        HOT_KnowledgeArchiveCaseMapping__mdt settings = new HOT_KnowledgeArchiveCaseMapping__mdt(
            CaseNumberTest__c = TEST_CASE_NUMBER,
            CaseNumberProd__c = TEST_CASE_NUMBER_PROD
        );

        Test.startTest();
        String result = handler.getCaseNumber(settings);
        Test.stopTest();

        System.Assert.areEqual(TEST_CASE_NUMBER_PROD, result, 'Should return prod case number in production');
    }

    // MARK: - getNavIdent() Tests

    /**
     * What this test verifies:
     * - getNavIdent() returns the test NAV ident when in sandbox environment.
     * Why it matters:
     * - Ensures correct NAV ident is used for archiving documents in sandbox.
     *
     * @see HOT_KnowledgeArchiveHandler.getNavIdent
     */
    @IsTest
    static void getNavIdent_whenInSandbox_returnsTestNavIdent() {
        HOT_KnowledgeArchiveHandler.testIsSandboxOverride = true;
        HOT_KnowledgeArchiveHandler handler = new HOT_KnowledgeArchiveHandler();

        Test.startTest();
        String result = handler.getNavIdent();
        Test.stopTest();

        System.Assert.areEqual(TEST_NAV_IDENT, result, 'Should return test NAV ident in sandbox');
    }

    /**
     * What this test verifies:
     * - getNavIdent() returns the production NAV ident when in production environment.
     * Why it matters:
     * - Ensures correct NAV ident is used for archiving documents in production.
     *
     * @see HOT_KnowledgeArchiveHandler.getNavIdent
     */
    @IsTest
    static void getNavIdent_whenInProduction_returnsProdNavIdent() {
        HOT_KnowledgeArchiveHandler.testIsSandboxOverride = false;
        HOT_KnowledgeArchiveHandler handler = new HOT_KnowledgeArchiveHandler();

        Test.startTest();
        String result = handler.getNavIdent();
        Test.stopTest();

        System.Assert.areEqual(TEST_NAV_IDENT_PROD, result, 'Should return prod NAV ident in production');
    }

    /**
     * What this test verifies:
     * - getNavIdent() returns null when org settings are missing.
     * Why it matters:
     * - Ensures method handles missing configuration safely.
     *
     * @see HOT_KnowledgeArchiveHandler.getNavIdent
     */
    @IsTest
    static void getNavIdent_whenSettingsMissing_returnsNull() {
        HOT_KnowledgeArchiveHandler.testIsSandboxOverride = true;
        delete [
            SELECT Id
            FROM HOT_KnowledgeArchiveSettings__c
            WHERE SetupOwnerId = :UserInfo.getOrganizationId()
            LIMIT 1
        ];
        HOT_KnowledgeArchiveHandler handler = new HOT_KnowledgeArchiveHandler();

        Test.startTest();
        String result = handler.getNavIdent();
        Test.stopTest();

        System.Assert.isNull(result, 'Should return null when settings are missing');
    }

    // MARK: - getNavEnhet() Tests

    /**
     * What this test verifies:
     * - getNavEnhet() returns the test NAV unit when in sandbox environment.
     * Why it matters:
     * - Ensures correct NAV unit is used for archiving documents in sandbox.
     *
     * @see HOT_KnowledgeArchiveHandler.getNavEnhet
     */
    @IsTest
    static void getNavEnhet_whenInSandbox_returnsTestNavEnhet() {
        HOT_KnowledgeArchiveHandler.testIsSandboxOverride = true;
        HOT_KnowledgeArchiveHandler handler = new HOT_KnowledgeArchiveHandler();

        Test.startTest();
        String result = handler.getNavEnhet();
        Test.stopTest();

        System.Assert.areEqual(TEST_NAV_ENHET, result, 'Should return test NAV unit in sandbox');
    }

    /**
     * What this test verifies:
     * - getNavEnhet() returns the production NAV unit when in production environment.
     * Why it matters:
     * - Ensures correct NAV unit is used for archiving documents in production.
     *
     * @see HOT_KnowledgeArchiveHandler.getNavEnhet
     */
    @IsTest
    static void getNavEnhet_whenInProduction_returnsProdNavEnhet() {
        HOT_KnowledgeArchiveHandler.testIsSandboxOverride = false;
        HOT_KnowledgeArchiveHandler handler = new HOT_KnowledgeArchiveHandler();

        Test.startTest();
        String result = handler.getNavEnhet();
        Test.stopTest();

        System.Assert.areEqual(TEST_NAV_ENHET_PROD, result, 'Should return prod NAV unit in production');
    }

    /**
     * What this test verifies:
     * - getNavEnhet() returns null when org settings are missing.
     * Why it matters:
     * - Ensures method handles missing configuration safely.
     *
     * @see HOT_KnowledgeArchiveHandler.getNavEnhet
     */
    @IsTest
    static void getNavEnhet_whenSettingsMissing_returnsNull() {
        HOT_KnowledgeArchiveHandler.testIsSandboxOverride = true;
        delete [
            SELECT Id
            FROM HOT_KnowledgeArchiveSettings__c
            WHERE SetupOwnerId = :UserInfo.getOrganizationId()
            LIMIT 1
        ];
        HOT_KnowledgeArchiveHandler handler = new HOT_KnowledgeArchiveHandler();

        Test.startTest();
        String result = handler.getNavEnhet();
        Test.stopTest();

        System.Assert.isNull(result, 'Should return null when settings are missing');
    }

    // MARK: - createRequestBody() Tests

    /**
     * What this test verifies:
     * - createRequestBody() generates valid JSON with all required fields.
     * Why it matters:
     * - Ensures the request body conforms to the Public 360 API contract.
     *
     * @see HOT_KnowledgeArchiveHandler.createRequestBody
     */
    @IsTest
    static void createRequestBody_withValidInputs_returnsValidJson() {
        HOT_KnowledgeArchiveHandler.testIsSandboxOverride = true;
        HOT_KnowledgeArchiveHandler handler = new HOT_KnowledgeArchiveHandler();
        Knowledge__kav article = [SELECT Id, Title FROM Knowledge__kav LIMIT 1];
        Blob testPdf = Blob.valueOf('Test PDF Content');

        Test.startTest();
        String result = handler.createRequestBody(TEST_CASE_NUMBER, TEST_NAV_IDENT, article, testPdf);
        Test.stopTest();

        Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.Assert.areEqual(TEST_ARTICLE_TITLE, parsedJson.get('Title'), 'Title should match article title');
        System.Assert.areEqual(TEST_CASE_NUMBER, parsedJson.get('CaseNumber'), 'Case number should match');
        System.Assert.areEqual(TEST_NAV_IDENT, parsedJson.get('ResponsiblePersonIdNumber'), 'NAV ident should match');
        System.Assert.isNotNull(parsedJson.get('Files'), 'Files array should be present');
    }

    // MARK: - send() Tests

    /**
     * What this test verifies:
     * - send() returns true when the HTTP callout succeeds (200 response).
     * Why it matters:
     * - Ensures successful callouts are properly detected and reported.
     *
     * @see HOT_KnowledgeArchiveHandler.send
     */
    @IsTest
    static void send_whenCalloutSucceeds_returnsTrue() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        HOT_KnowledgeArchiveHandler.testIsSandboxOverride = true;
        HOT_KnowledgeArchiveHandler handler = new HOT_KnowledgeArchiveHandler();
        String requestBody = '{"Title":"Test"}';

        Test.startTest();
        Boolean result = handler.send(requestBody);
        Test.stopTest();

        System.Assert.isTrue(result, 'Should return true on successful callout');
        System.Assert.areEqual(200, handler.operationResponse.getStatusCode(), 'Response should be 200');
    }

    /**
     * What this test verifies:
     * - send() returns false when the HTTP callout fails (non-200 response).
     * Why it matters:
     * - Ensures failed callouts are properly detected and logged.
     *
     * @see HOT_KnowledgeArchiveHandler.send
     */
    @IsTest
    static void send_whenCalloutFails_returnsFalse() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseFailure());
        HOT_KnowledgeArchiveHandler.testIsSandboxOverride = true;
        HOT_KnowledgeArchiveHandler handler = new HOT_KnowledgeArchiveHandler();
        String requestBody = '{"Title":"Test"}';

        Test.startTest();
        Boolean result = handler.send(requestBody);
        Test.stopTest();

        System.Assert.isFalse(result, 'Should return false on failed callout');
        System.Assert.areEqual(500, handler.operationResponse.getStatusCode(), 'Response should be 500');
    }

    // MARK: - archiveArticle() Tests

    /**
     * What this test verifies:
     * - archiveArticle() returns true when archiving succeeds.
     * Why it matters:
     * - Ensures the full archiving flow works end-to-end.
     *
     * @see HOT_KnowledgeArchiveHandler.archiveArticle
     */
    @IsTest
    static void archiveArticle_whenCalloutSucceeds_returnsTrue() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        HOT_KnowledgeArchiveHandler.testIsSandboxOverride = true;
        HOT_KnowledgeArchiveHandler handler = new HOT_KnowledgeArchiveHandler();
        Knowledge__kav article = [SELECT Id, Title FROM Knowledge__kav LIMIT 1];

        Test.startTest();
        Boolean result = handler.archiveArticle(article, TEST_CASE_NUMBER, TEST_NAV_IDENT, TEST_NAV_ENHET);
        Test.stopTest();

        System.Assert.isTrue(result, 'Should return true when archiving succeeds');
    }

    /**
     * What this test verifies:
     * - archiveArticle() returns false when archiving fails.
     * Why it matters:
     * - Ensures failures in the archiving flow are properly reported.
     *
     * @see HOT_KnowledgeArchiveHandler.archiveArticle
     */
    @IsTest
    static void archiveArticle_whenCalloutFails_returnsFalse() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseFailure());
        HOT_KnowledgeArchiveHandler.testIsSandboxOverride = true;
        HOT_KnowledgeArchiveHandler handler = new HOT_KnowledgeArchiveHandler();
        Knowledge__kav article = [SELECT Id, Title FROM Knowledge__kav LIMIT 1];

        Test.startTest();
        Boolean result = handler.archiveArticle(article, TEST_CASE_NUMBER, TEST_NAV_IDENT, TEST_NAV_ENHET);
        Test.stopTest();

        System.Assert.isFalse(result, 'Should return false when archiving fails');
    }
}
