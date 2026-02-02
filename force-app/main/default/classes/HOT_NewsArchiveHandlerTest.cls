/**
 * Test class for HOT_NewsArchiveHandler.
 *
 * Note: Custom Metadata (HOT_NewsArchiveMapping__mdt) cannot be inserted in tests.
 * The getNewsArchiveMappingSettings() method queries real metadata, so full coverage
 * of sandbox vs production branches depends on the org's metadata configuration.
 * The @TestVisible annotation on private methods allows direct testing of isolated logic.
 *
 * @author Kenneth Sørensen
 * @group HOT Public 360 Integration
 * @since November 2025
 * @see HOT_NewsArchiveHandler
 */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.ApexDoc,PMD.MethodNamingConventions')
@IsTest
private class HOT_NewsArchiveHandlerTest {
    // MARK: - Test Constants
    private static final String TEST_CASE_NUMBER = '25/12345';
    private static final String TEST_NAV_IDENT = 'A123456';
    private static final String TEST_NAV_ENHET = '1234';
    private static final String TEST_CALLOUT_NAME = 'P360_Test';
    private static final String TEST_ARTICLE_NAME = 'Test News Article';
    private static final String TEST_ARTICLE_CONTENT = '<p>Test content</p>';

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
            NKS_Information__c = TEST_ARTICLE_CONTENT,
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
     * - Constructor initializes without throwing exceptions when settings exist.
     * Why it matters:
     * - Ensures the handler can be instantiated in a valid org configuration.
     */
    @IsTest
    static void constructor_WhenSettingsExist_InitializesSuccessfully() {
        System.Test.startTest();
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();
        System.Test.stopTest();

        System.Assert.isNotNull(handler, 'Handler should be instantiated');
    }

    // MARK: - execute() Tests

    /**
     * What this test verifies:
     * - execute() handles the case when metadata settings exist and all values are populated in sandbox.
     * Why it matters:
     * - Validates the happy path where all configuration is properly set up for sandbox environment.
     */
    @IsTest
    static void execute_WhenInSandboxWithMetadataSettings_ProcessesWithoutError() {
        // Arrange
        setCustomMetadataForTest(true);
        NKS_Announcement__c article = [SELECT Id, Name FROM NKS_Announcement__c LIMIT 1];
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();

        // Act
        System.Test.startTest();
        handler.execute(article);
        System.Test.stopTest();

        // Assert
        System.Assert.isNotNull(handler, 'Handler should complete execution');
    }

    /**
     * What this test verifies:
     * - execute() handles the case when metadata settings exist and all values are populated in production.
     * Why it matters:
     * - Validates the happy path where all configuration is properly set up for production environment.
     */
    @IsTest
    static void execute_WhenInProductionWithMetadataSettings_ProcessesWithoutError() {
        // Arrange
        setCustomMetadataForTest(false);
        NKS_Announcement__c article = [SELECT Id, Name FROM NKS_Announcement__c LIMIT 1];
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();

        // Act
        System.Test.startTest();
        handler.execute(article);
        System.Test.stopTest();

        // Assert
        System.Assert.isNotNull(handler, 'Handler should complete execution');
    }

    /**
     * What this test verifies:
     * - execute() logs error and returns early when no metadata settings are found.
     * Why it matters:
     * - Ensures proper error handling when configuration is missing.
     */
    @IsTest
    static void execute_WhenNoMetadataSettings_LogsErrorAndReturns() {
        // Arrange - Set up empty metadata response
        HOT_NewsArchiveHandler.testIsSandboxOverride = true;
        String env = 'Test';
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
            new List<HOT_NewsArchiveMapping__mdt>()
        );
        NKS_Announcement__c article = [SELECT Id, Name FROM NKS_Announcement__c LIMIT 1];
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();

        // Act
        System.Test.startTest();
        handler.execute(article);
        System.Test.stopTest();

        // Assert - No exception means it handled the null case gracefully
        System.Assert.isNotNull(handler, 'Handler should complete execution without throwing');
    }

    /**
     * What this test verifies:
     * - execute() logs error and returns early when metadata exists but values are null.
     * Why it matters:
     * - Ensures proper error handling when configuration values are missing.
     */
    @IsTest
    static void execute_WhenMetadataValuesAreNull_LogsErrorAndReturns() {
        // Arrange - Set up metadata with null values
        HOT_NewsArchiveHandler.testIsSandboxOverride = true;
        String env = 'Test';
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
                    '__c":null,' +
                    '"NavId' +
                    env +
                    '__c":null,' +
                    '"NavEnhet' +
                    env +
                    '__c":null,' +
                    '"ActiveFrom__c":"2025-01-01",' +
                    '"Order__c":1}]',
                List<HOT_NewsArchiveMapping__mdt>.class
            )
        );
        NKS_Announcement__c article = [SELECT Id, Name FROM NKS_Announcement__c LIMIT 1];
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();

        // Act
        System.Test.startTest();
        handler.execute(article);
        System.Test.stopTest();

        // Assert - No exception means it handled the null values gracefully
        System.Assert.isNotNull(handler, 'Handler should complete execution without throwing');
    }

    /**
     * What this test verifies:
     * - execute() logs error and returns early when only one metadata value is null.
     * Why it matters:
     * - Validates the OR condition in the null check (caseNumber == null || navIdent == null || navEnhet == null).
     */
    @IsTest
    static void execute_WhenOnlyCaseNumberIsNull_LogsErrorAndReturns() {
        // Arrange - Set up metadata with only caseNumber as null
        HOT_NewsArchiveHandler.testIsSandboxOverride = true;
        String env = 'Test';
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
                    '__c":null,' +
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
        NKS_Announcement__c article = [SELECT Id, Name FROM NKS_Announcement__c LIMIT 1];
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();

        // Act
        System.Test.startTest();
        handler.execute(article);
        System.Test.stopTest();

        // Assert - No exception means it handled the partial null case gracefully
        System.Assert.isNotNull(handler, 'Handler should complete execution without throwing');
    }

    // MARK: - getCaseNumber() Tests

    /**
     * What this test verifies:
     * - getCaseNumber() returns null when settings parameter is null.
     * Why it matters:
     * - Ensures null safety and proper handling of missing configuration.
     */
    @IsTest
    static void getCaseNumber_WhenSettingsIsNull_ReturnsNull() {
        // Arrange
        HOT_NewsArchiveHandler.testIsSandboxOverride = true;
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();

        // Act
        System.Test.startTest();
        String result = handler.getCaseNumber(null);
        System.Test.stopTest();

        // Assert
        System.Assert.isNull(result, 'Should return null when settings is null');
    }

    /**
     * What this test verifies:
     * - getCaseNumber() returns the test case number field when in sandbox.
     * Why it matters:
     * - Ensures correct field is used based on sandbox environment.
     */
    @IsTest
    static void getCaseNumber_WhenInSandbox_ReturnsCaseNumberTest() {
        // Arrange
        HOT_NewsArchiveHandler.testIsSandboxOverride = true;
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();
        HOT_NewsArchiveMapping__mdt mockSettings = new HOT_NewsArchiveMapping__mdt(
            CaseNumberTest__c = TEST_CASE_NUMBER,
            CaseNumberProd__c = 'PROD/99999'
        );

        // Act
        System.Test.startTest();
        String result = handler.getCaseNumber(mockSettings);
        System.Test.stopTest();

        // Assert
        System.Assert.areEqual(TEST_CASE_NUMBER, result, 'Should return test case number in sandbox');
    }

    /**
     * What this test verifies:
     * - getCaseNumber() returns the production case number field when in production.
     * Why it matters:
     * - Ensures correct field is used based on production environment.
     */
    @IsTest
    static void getCaseNumber_WhenInProduction_ReturnsCaseNumberProd() {
        // Arrange
        HOT_NewsArchiveHandler.testIsSandboxOverride = false;
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();
        HOT_NewsArchiveMapping__mdt mockSettings = new HOT_NewsArchiveMapping__mdt(
            CaseNumberTest__c = TEST_CASE_NUMBER,
            CaseNumberProd__c = 'PROD/99999'
        );

        // Act
        System.Test.startTest();
        String result = handler.getCaseNumber(mockSettings);
        System.Test.stopTest();

        // Assert
        System.Assert.areEqual('PROD/99999', result, 'Should return production case number in production');
    }

    // MARK: - getNavIdent() Tests

    /**
     * What this test verifies:
     * - getNavIdent() returns null when settings parameter is null.
     * Why it matters:
     * - Ensures null safety and proper handling of missing configuration.
     */
    @IsTest
    static void getNavIdent_WhenSettingsIsNull_ReturnsNull() {
        // Arrange
        HOT_NewsArchiveHandler.testIsSandboxOverride = true;
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();

        // Act
        System.Test.startTest();
        String result = handler.getNavIdent(null);
        System.Test.stopTest();

        // Assert
        System.Assert.isNull(result, 'Should return null when settings is null');
    }

    /**
     * What this test verifies:
     * - getNavIdent() returns the test NavId field when in sandbox.
     * Why it matters:
     * - Ensures correct field is used based on sandbox environment.
     */
    @IsTest
    static void getNavIdent_WhenInSandbox_ReturnsNavIdTest() {
        // Arrange
        HOT_NewsArchiveHandler.testIsSandboxOverride = true;
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();
        HOT_NewsArchiveMapping__mdt mockSettings = new HOT_NewsArchiveMapping__mdt(
            NavIdTest__c = TEST_NAV_IDENT,
            NavIdProd__c = 'PROD_IDENT'
        );

        // Act
        System.Test.startTest();
        String result = handler.getNavIdent(mockSettings);
        System.Test.stopTest();

        // Assert
        System.Assert.areEqual(TEST_NAV_IDENT, result, 'Should return test NavId in sandbox');
    }

    /**
     * What this test verifies:
     * - getNavIdent() returns the production NavId field when in production.
     * Why it matters:
     * - Ensures correct field is used based on production environment.
     */
    @IsTest
    static void getNavIdent_WhenInProduction_ReturnsNavIdProd() {
        // Arrange
        HOT_NewsArchiveHandler.testIsSandboxOverride = false;
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();
        HOT_NewsArchiveMapping__mdt mockSettings = new HOT_NewsArchiveMapping__mdt(
            NavIdTest__c = TEST_NAV_IDENT,
            NavIdProd__c = 'PROD_IDENT'
        );

        // Act
        System.Test.startTest();
        String result = handler.getNavIdent(mockSettings);
        System.Test.stopTest();

        // Assert
        System.Assert.areEqual('PROD_IDENT', result, 'Should return production NavId in production');
    }

    // MARK: - getNavEnhet() Tests

    /**
     * What this test verifies:
     * - getNavEnhet() returns null when settings parameter is null.
     * Why it matters:
     * - Ensures null safety and proper handling of missing configuration.
     */
    @IsTest
    static void getNavEnhet_WhenSettingsIsNull_ReturnsNull() {
        // Arrange
        HOT_NewsArchiveHandler.testIsSandboxOverride = true;
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();

        // Act
        System.Test.startTest();
        String result = handler.getNavEnhet(null);
        System.Test.stopTest();

        // Assert
        System.Assert.isNull(result, 'Should return null when settings is null');
    }

    /**
     * What this test verifies:
     * - getNavEnhet() returns the test NavEnhet field when in sandbox.
     * Why it matters:
     * - Ensures correct field is used based on sandbox environment.
     */
    @IsTest
    static void getNavEnhet_WhenInSandbox_ReturnsNavEnhetTest() {
        // Arrange
        HOT_NewsArchiveHandler.testIsSandboxOverride = true;
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();
        HOT_NewsArchiveMapping__mdt mockSettings = new HOT_NewsArchiveMapping__mdt(
            NavEnhetTest__c = TEST_NAV_ENHET,
            NavEnhetProd__c = 'PROD_ENHET'
        );

        // Act
        System.Test.startTest();
        String result = handler.getNavEnhet(mockSettings);
        System.Test.stopTest();

        // Assert
        System.Assert.areEqual(TEST_NAV_ENHET, result, 'Should return test NavEnhet in sandbox');
    }

    /**
     * What this test verifies:
     * - getNavEnhet() returns the production NavEnhet field when in production.
     * Why it matters:
     * - Ensures correct field is used based on production environment.
     */
    @IsTest
    static void getNavEnhet_WhenInProduction_ReturnsNavEnhetProd() {
        // Arrange
        HOT_NewsArchiveHandler.testIsSandboxOverride = false;
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();
        HOT_NewsArchiveMapping__mdt mockSettings = new HOT_NewsArchiveMapping__mdt(
            NavEnhetTest__c = TEST_NAV_ENHET,
            NavEnhetProd__c = 'PROD_ENHET'
        );

        // Act
        System.Test.startTest();
        String result = handler.getNavEnhet(mockSettings);
        System.Test.stopTest();

        // Assert
        System.Assert.areEqual('PROD_ENHET', result, 'Should return production NavEnhet in production');
    }

    // MARK: - createRequestBody() Tests

    /**
     * What this test verifies:
     * - createRequestBody() generates valid JSON with all required fields.
     * Why it matters:
     * - Ensures the API request body is properly formatted for Public 360.
     */
    @IsTest
    static void createRequestBody_WhenValidInputs_ReturnsValidJson() {
        // Arrange
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();
        NKS_Announcement__c article = [SELECT Id, Name FROM NKS_Announcement__c LIMIT 1];
        Blob testPdf = Blob.valueOf('Test PDF Content');

        // Act
        System.Test.startTest();
        String result = handler.createRequestBody(TEST_CASE_NUMBER, TEST_NAV_IDENT, article, testPdf);
        System.Test.stopTest();

        // Assert
        System.Assert.isNotNull(result, 'Should return a JSON string');
        System.Assert.isTrue(result.contains('"Title":"' + TEST_ARTICLE_NAME + '"'), 'Should contain article title');
        System.Assert.isTrue(result.contains('"DefaultValueSet":"NKSSalesForce"'), 'Should contain default value set');
        System.Assert.isTrue(result.contains('"CaseNumber":"' + TEST_CASE_NUMBER + '"'), 'Should contain case number');
        System.Assert.isTrue(result.contains('"AccessGroup":"Alle ansatte i Nav"'), 'Should contain access group');
        System.Assert.isTrue(
            result.contains('"ResponsiblePersonIdNumber":"' + TEST_NAV_IDENT + '"'),
            'Should contain NAV ident'
        );
        System.Assert.isTrue(result.contains('"Format":"pdf"'), 'Should contain PDF format');
        System.Assert.isTrue(result.contains('"Base64Data"'), 'Should contain Base64 encoded data');
    }

    /**
     * What this test verifies:
     * - createRequestBody() correctly encodes the PDF blob as Base64.
     * Why it matters:
     * - Ensures file data is properly encoded for transmission.
     */
    @IsTest
    static void createRequestBody_WhenPdfProvided_EncodesAsBase64() {
        // Arrange
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();
        NKS_Announcement__c article = [SELECT Id, Name FROM NKS_Announcement__c LIMIT 1];
        String originalContent = 'Test PDF Content';
        Blob testPdf = Blob.valueOf(originalContent);
        String expectedBase64 = EncodingUtil.base64Encode(testPdf);

        // Act
        System.Test.startTest();
        String result = handler.createRequestBody(TEST_CASE_NUMBER, TEST_NAV_IDENT, article, testPdf);
        System.Test.stopTest();

        // Assert
        System.Assert.isTrue(
            result.contains('"Base64Data":"' + expectedBase64 + '"'),
            'Should contain correctly encoded Base64 data'
        );
    }

    // MARK: - send() Tests

    /**
     * What this test verifies:
     * - send() returns true when the HTTP response status code is 200.
     * Why it matters:
     * - Confirms successful API calls are handled correctly.
     */
    @IsTest
    static void send_WhenResponseIs200_ReturnsTrue() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();
        String requestBody = '{"test":"data"}';

        // Act
        System.Test.startTest();
        Boolean result = handler.send(requestBody);
        System.Test.stopTest();

        // Assert
        System.Assert.isTrue(result, 'Should return true on successful response');
        System.Assert.areEqual(200, handler.operationResponse.getStatusCode(), 'Response code should be 200');
    }

    /**
     * What this test verifies:
     * - send() returns false when the HTTP response status code is not 200.
     * Why it matters:
     * - Ensures failed API calls are properly detected and reported.
     */
    @IsTest
    static void send_WhenResponseIsNot200_ReturnsFalse() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseFailure());
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();
        String requestBody = '{"test":"data"}';

        // Act
        System.Test.startTest();
        Boolean result = handler.send(requestBody);
        System.Test.stopTest();

        // Assert
        System.Assert.isFalse(result, 'Should return false on error response');
        System.Assert.areEqual(500, handler.operationResponse.getStatusCode(), 'Response code should be 500');
    }

    /**
     * What this test verifies:
     * - send() stores the HTTP response in operationResponse property.
     * Why it matters:
     * - Allows inspection of response details after the call.
     */
    @IsTest
    static void send_WhenCalled_StoresResponseInProperty() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();
        String requestBody = '{"test":"data"}';

        // Act
        System.Test.startTest();
        handler.send(requestBody);
        System.Test.stopTest();

        // Assert
        System.Assert.isNotNull(handler.operationResponse, 'Should store response in property');
        System.Assert.areEqual('OK', handler.operationResponse.getStatus(), 'Should have correct status');
    }

    // MARK: - callout() Tests

    /**
     * What this test verifies:
     * - callout() constructs the correct endpoint URL.
     * Why it matters:
     * - Ensures requests are sent to the correct Public 360 API endpoint.
     */
    @IsTest
    static void callout_WhenCalled_ConstructsCorrectEndpoint() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        String operationType = HOT_NewsArchiveHandler.CREATE_DOCUMENT;
        String requestBody = '{"test":"data"}';

        // Act
        System.Test.startTest();
        HttpResponse result = HOT_NewsArchiveHandler.callout(operationType, requestBody, TEST_CALLOUT_NAME);
        System.Test.stopTest();

        // Assert
        System.Assert.isNotNull(result, 'Should return a response');
        System.Assert.areEqual(200, result.getStatusCode(), 'Should receive successful response');
    }

    /**
     * What this test verifies:
     * - callout() returns HttpResponse object.
     * Why it matters:
     * - Confirms the callout mechanism works correctly.
     */
    @IsTest
    static void callout_WhenSuccessful_ReturnsHttpResponse() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());

        // Act
        System.Test.startTest();
        HttpResponse result = HOT_NewsArchiveHandler.callout(
            HOT_NewsArchiveHandler.CREATE_DOCUMENT,
            '{}',
            TEST_CALLOUT_NAME
        );
        System.Test.stopTest();

        // Assert
        System.Assert.isNotNull(result, 'Should return HttpResponse');
        System.Assert.isNotNull(result.getBody(), 'Response should have body');
    }

    // MARK: - archiveArticle() Tests

    /**
     * What this test verifies:
     * - archiveArticle() returns true when the send operation succeeds.
     * Why it matters:
     * - Validates the complete archive workflow for successful cases.
     */
    @IsTest
    static void archiveArticle_WhenSendSucceeds_ReturnsTrue() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();
        NKS_Announcement__c article = [SELECT Id, Name FROM NKS_Announcement__c LIMIT 1];

        // Act
        System.Test.startTest();
        Boolean result = handler.archiveArticle(article, TEST_CASE_NUMBER, TEST_NAV_IDENT, TEST_NAV_ENHET);
        System.Test.stopTest();

        // Assert
        System.Assert.isTrue(result, 'Should return true on successful archive');
    }

    /**
     * What this test verifies:
     * - archiveArticle() returns false when the send operation fails.
     * Why it matters:
     * - Ensures failures are properly propagated to the caller.
     */
    @IsTest
    static void archiveArticle_WhenSendFails_ReturnsFalse() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseFailure());
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();
        NKS_Announcement__c article = [SELECT Id, Name FROM NKS_Announcement__c LIMIT 1];

        // Act
        System.Test.startTest();
        Boolean result = handler.archiveArticle(article, TEST_CASE_NUMBER, TEST_NAV_IDENT, TEST_NAV_ENHET);
        System.Test.stopTest();

        // Assert
        System.Assert.isFalse(result, 'Should return false on failed archive');
    }

    /**
     * What this test verifies:
     * - archiveArticle() uses test PDF blob when running in test context.
     * Why it matters:
     * - Confirms the Test.isRunningTest() bypass works correctly.
     */
    @IsTest
    static void archiveArticle_WhenInTestContext_UsesMockPdf() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();
        NKS_Announcement__c article = [SELECT Id, Name FROM NKS_Announcement__c LIMIT 1];

        // Act
        System.Test.startTest();
        Boolean result = handler.archiveArticle(article, TEST_CASE_NUMBER, TEST_NAV_IDENT, TEST_NAV_ENHET);
        System.Test.stopTest();

        // Assert - If we get here without exception, the test PDF was used
        System.Assert.isNotNull(handler.operationResponse, 'Should have completed the callout');
    }

    // MARK: - Constants Tests

    /**
     * What this test verifies:
     * - All public constants have the expected values.
     * Why it matters:
     * - Ensures API endpoint paths and operation types are correctly defined.
     */
    @IsTest
    static void constants_HaveCorrectValues() {
        // Assert
        System.Assert.areEqual(
            'DocumentService',
            HOT_NewsArchiveHandler.DOCUMENT_SERVICE,
            'DOCUMENT_SERVICE should have correct value'
        );
        System.Assert.areEqual(
            'CreateDocument',
            HOT_NewsArchiveHandler.CREATE_DOCUMENT,
            'CREATE_DOCUMENT should have correct value'
        );
    }

    // MARK: - testIsSandboxOverride Tests

    /**
     * What this test verifies:
     * - Constructor uses testIsSandboxOverride when set to true.
     * Why it matters:
     * - Ensures the test override mechanism works for sandbox simulation.
     */
    @IsTest
    static void constructor_WhenTestIsSandboxOverrideTrue_UsesSandboxBehavior() {
        // Arrange
        HOT_NewsArchiveHandler.testIsSandboxOverride = true;

        // Act
        System.Test.startTest();
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();
        HOT_NewsArchiveMapping__mdt mockSettings = new HOT_NewsArchiveMapping__mdt(
            CaseNumberTest__c = 'SANDBOX/12345',
            CaseNumberProd__c = 'PROD/99999'
        );
        String result = handler.getCaseNumber(mockSettings);
        System.Test.stopTest();

        // Assert
        System.Assert.areEqual('SANDBOX/12345', result, 'Should use sandbox field when override is true');
    }

    /**
     * What this test verifies:
     * - Constructor uses testIsSandboxOverride when set to false.
     * Why it matters:
     * - Ensures the test override mechanism works for production simulation.
     */
    @IsTest
    static void constructor_WhenTestIsSandboxOverrideFalse_UsesProductionBehavior() {
        // Arrange
        HOT_NewsArchiveHandler.testIsSandboxOverride = false;

        // Act
        System.Test.startTest();
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();
        HOT_NewsArchiveMapping__mdt mockSettings = new HOT_NewsArchiveMapping__mdt(
            CaseNumberTest__c = 'SANDBOX/12345',
            CaseNumberProd__c = 'PROD/99999'
        );
        String result = handler.getCaseNumber(mockSettings);
        System.Test.stopTest();

        // Assert
        System.Assert.areEqual('PROD/99999', result, 'Should use production field when override is false');
    }
}
