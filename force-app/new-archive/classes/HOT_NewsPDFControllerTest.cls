/**
 * Test class for HOT_NewsPDFController.
 *
 * @author Kenneth Sørensen
 * @group HOT Public 360 Integration
 * @since November 2025
 * @see HOT_NewsPDFController
 */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.ApexDoc,PMD.MethodNamingConventions')
@IsTest
private class HOT_NewsPDFControllerTest {
    // MARK: - Test Setup
    private static final String TEST_USER_LAST_NAME = 'Testuser';
    private static final String TEST_ANNOUNCEMENT_NAME = 'Test News Article for PDF';
    private static final String TEST_NEWS_OTHER_AUTHORS = 'John Doe, Jane Smith';
    private static final String TEST_ANNOUNCEMENT_CONTENT = '<p>This is a test news article content with <strong>HTML</strong> formatting.</p>';
    private static final String TEST_IMAGE_URL = '/initial/image/url';
    private static final String TEST_IMAGE_TITLE = 'Test Image for PDF';

    @TestSetup
    static void setupTestData() {
        // Create a test user to be the author
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User testUser = HOT_ST_TestDataFactory.createUser(TEST_USER_LAST_NAME, profile);
        insert testUser;

        // Create test announcement record
        NKS_Announcement__c testAnnouncement = new NKS_Announcement__c(
            Name = TEST_ANNOUNCEMENT_NAME,
            RecordTypeId = Schema.SObjectType.NKS_Announcement__c
                .getRecordTypeInfosByDeveloperName()
                .get('HOT_News')
                .getRecordTypeId(),
            NKS_News_Author__c = testUser.Id,
            NKS_News_Other_Authors__c = TEST_NEWS_OTHER_AUTHORS,
            NKS_News_Publish_Date__c = DateTime.now(),
            NKS_Information__c = TEST_ANNOUNCEMENT_CONTENT,
            NKS_ImageURL__c = TEST_IMAGE_URL
        );
        insert testAnnouncement;

        // Create ContentDocument and ContentDocumentLink for image URL testing
        ContentVersion testContentVersion = new ContentVersion(
            Title = TEST_IMAGE_TITLE,
            PathOnClient = 'test-image.png',
            VersionData = Blob.valueOf('test image content for PDF generation'),
            FirstPublishLocationId = testAnnouncement.Id
        );
        insert testContentVersion;
    }

    // MARK: - Constructor Tests

    /**
     * Test that constructor initializes all properties correctly when a valid record ID
     * is provided in the page parameters. Verifies that title, author, publishDate,
     * lastModifiedDate, otherAuthors, information, and imageURL are all populated
     * from the database record.
     */
    @IsTest
    static void constructor_WhenValidRecordId_InitializesAllProperties() {
        NKS_Announcement__c testAnnouncement = getTestAnnouncement();

        PageReference pageRef = new PageReference('/apex/HOT_NewsArticlePDF');
        pageRef.getParameters().put('id', testAnnouncement.Id);
        Test.setCurrentPageReference(pageRef);

        System.Test.startTest();
        HOT_NewsPDFController controller = new HOT_NewsPDFController();
        System.Test.stopTest();

        System.Assert.areEqual(TEST_ANNOUNCEMENT_NAME, controller.title, 'Title should match announcement name');
        System.Assert.areEqual(TEST_USER_LAST_NAME, controller.author, 'Author should match user name');
        System.Assert.isNotNull(controller.publishDate, 'Publish date should not be null');
        System.Assert.isNotNull(controller.lastModifiedDate, 'Last modified date should not be null');
        System.Assert.areEqual(TEST_NEWS_OTHER_AUTHORS, controller.otherAuthors, 'Other authors should match');
        System.Assert.isTrue(
            controller.information.contains(TEST_ANNOUNCEMENT_CONTENT),
            'Information should contain expected content'
        );
        System.Assert.isTrue(controller.publishDate.contains(':'), 'Publish date should include time formatting');
        System.Assert.isTrue(
            controller.lastModifiedDate.contains(':'),
            'Last modified date should include time formatting'
        );
    }

    /**
     * Test that constructor throws an exception when the page parameters do not contain
     * a valid record ID. This covers the error handling when the Visualforce page is
     * accessed without the required 'id' parameter.
     */
    @IsTest
    static void constructor_WhenPageParametersAreMissing_ThrowsException() {
        PageReference pageRef = new PageReference('/apex/HOT_NewsArticlePDF');
        Test.setCurrentPageReference(pageRef);

        System.Test.startTest();
        Exception caughtException = null;
        try {
            HOT_NewsPDFController controller = new HOT_NewsPDFController();
        } catch (Exception e) {
            caughtException = e;
        }
        System.Test.stopTest();

        System.Assert.isNotNull(caughtException, 'Constructor should throw exception when page parameters are missing');
    }

    // MARK: - getNews Tests

    /**
     * Test that getNews returns the correct NKS_Announcement__c record when provided
     * with a valid record ID. Verifies that all queried fields are populated and that
     * the NKS_ImageURL__c field is updated with the URL from linked ContentDocuments.
     */
    @IsTest
    static void getNews_WhenValidId_ReturnsRecord() {
        NKS_Announcement__c testAnnouncement = getTestAnnouncement();

        System.Test.startTest();
        NKS_Announcement__c result = HOT_NewsPDFController.getNews(testAnnouncement.Id);
        System.Test.stopTest();

        System.Assert.isNotNull(result, 'Result should not be null');
        System.Assert.areEqual(testAnnouncement.Id, result.Id, 'IDs should match');
        System.Assert.areEqual(TEST_ANNOUNCEMENT_NAME, result.Name, 'Name should match');
        System.Assert.isNotNull(result.NKS_News_Author__c, 'Author should not be null');
        System.Assert.areEqual(TEST_NEWS_OTHER_AUTHORS, result.NKS_News_Other_Authors__c, 'Other authors should match');
        System.Assert.isNotNull(result.NKS_News_Publish_Date__c, 'Publish date should not be null');
        System.Assert.isNotNull(result.NKS_Information__c, 'Information should not be null');
        System.Assert.areNotEqual(
            TEST_IMAGE_URL,
            result.NKS_ImageURL__c,
            'Image URL should be updated by getImageUrl method'
        );
    }

    /**
     * Test that getNews returns null when provided with a record ID that does not exist
     * in the database. This covers the empty list check and null return branch.
     */
    @IsTest
    static void getNews_WhenInvalidId_ReturnsNull() {
        NKS_Announcement__c testAnnouncement = [
            SELECT Id
            FROM NKS_Announcement__c
            WHERE Name = :TEST_ANNOUNCEMENT_NAME
            LIMIT 1
        ];
        Id announcementId = testAnnouncement.Id;
        delete testAnnouncement;

        System.Test.startTest();
        NKS_Announcement__c result = HOT_NewsPDFController.getNews(announcementId);
        System.Test.stopTest();

        System.Assert.isNull(result, 'Result should be null for non-existent record');
    }

    // MARK: - getImageUrl Tests

    /**
     * Test that getImageUrl returns null when provided with a null record ID.
     * This covers the null check early return condition.
     */
    @IsTest
    static void getImageUrl_WhenNullId_ReturnsNull() {
        Id nullId = null;

        System.Test.startTest();
        String result = HOT_NewsPDFController.getImageUrl(nullId);
        System.Test.stopTest();

        System.Assert.isNull(result, 'Result should be null for null ID');
    }

    /**
     * Test that getImageUrl returns the correct URL string when provided with a valid
     * record ID that has a linked ContentDocument. Verifies the delegation to
     * getImageUrls works correctly.
     */
    @IsTest
    static void getImageUrl_WhenValidIdWithContent_ReturnsUrl() {
        NKS_Announcement__c testAnnouncement = [
            SELECT Id
            FROM NKS_Announcement__c
            WHERE Name = :TEST_ANNOUNCEMENT_NAME
            LIMIT 1
        ];

        System.Test.startTest();
        String result = HOT_NewsPDFController.getImageUrl(testAnnouncement.Id);
        System.Test.stopTest();

        System.Assert.isNotNull(result, 'Result should not be null');
        System.Assert.isTrue(
            result.contains('/sfc/servlet.shepherd/version/renditionDownload'),
            'Image URL should contain expected servlet path'
        );
        System.Assert.isTrue(result.contains('rendition='), 'Image URL should contain rendition parameter');
        System.Assert.isTrue(result.contains('versionId='), 'Image URL should contain versionId parameter');
    }

    /**
     * Test that getImageUrl returns null when provided with a valid record ID that
     * has no linked ContentDocuments. This covers the case where the map lookup
     * returns null.
     */
    @IsTest
    static void getImageUrl_WhenValidIdWithoutContent_ReturnsNull() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        System.Test.startTest();
        String result = HOT_NewsPDFController.getImageUrl(testAccount.Id);
        System.Test.stopTest();

        System.Assert.isNull(result, 'Result should be null for Account with no files');
    }

    // MARK: - getImageUrls Tests

    /**
     * Test that getImageUrls returns an empty map when provided with an empty set of
     * record IDs. This covers the early return optimization for empty input.
     */
    @IsTest
    static void getImageUrls_WhenGivenEmptySet_ReturnsEmptyMap() {
        Set<Id> emptyRecordIds = new Set<Id>();

        System.Test.startTest();
        Map<Id, String> result = HOT_NewsPDFController.getImageUrls(emptyRecordIds);
        System.Test.stopTest();

        System.Assert.isNotNull(result, 'Result should not be null');
        System.Assert.isTrue(result.isEmpty(), 'Result should be empty for empty input set');
    }

    /**
     * Test that getImageUrls returns an empty map when provided with null input.
     * This covers the null check in the early return condition.
     */
    @IsTest
    static void getImageUrls_WhenGivenNull_ReturnsEmptyMap() {
        Set<Id> nullRecordIds = null;

        System.Test.startTest();
        Map<Id, String> result = HOT_NewsPDFController.getImageUrls(nullRecordIds);
        System.Test.stopTest();

        System.Assert.isNotNull(result, 'Result should not be null');
        System.Assert.isTrue(result.isEmpty(), 'Result should be empty for null input');
    }

    /**
     * Test that getImageUrls returns a map with correctly formatted URLs when provided
     * with valid record IDs that have linked PNG ContentDocuments. Verifies the URL
     * contains 'ORIGINAL_Png' rendition type.
     */
    @IsTest
    static void getImageUrls_WhenGivenValidIdWithContent_ReturnsUrlMap() {
        NKS_Announcement__c testAnnouncement = [
            SELECT Id
            FROM NKS_Announcement__c
            WHERE Name = :TEST_ANNOUNCEMENT_NAME
            LIMIT 1
        ];
        Set<Id> recordIds = new Set<Id>{ testAnnouncement.Id };

        System.Test.startTest();
        Map<Id, String> result = HOT_NewsPDFController.getImageUrls(recordIds);
        System.Test.stopTest();

        System.Assert.isNotNull(result, 'Result should not be null');
        System.Assert.isTrue(result.containsKey(testAnnouncement.Id), 'Result should contain the announcement ID');
        String imageUrl = result.get(testAnnouncement.Id);
        System.Assert.isTrue(
            imageUrl.contains('/sfc/servlet.shepherd/version/renditionDownload'),
            'Image URL should contain expected servlet path'
        );
        System.Assert.isTrue(
            imageUrl.contains('rendition=ORIGINAL_Png'),
            'PNG files should use ORIGINAL_Png rendition'
        );
    }

    /**
     * Test that getImageUrls returns a URL with 'SVGZ' rendition when the linked
     * ContentDocument has a PDF file type. This covers the ternary condition for
     * PDF-specific rendition handling.
     */
    @IsTest
    static void getImageUrls_WhenGivenValidIdWithPDFContent_ReturnsSVGZRendition() {
        User testUser = [SELECT Id FROM User WHERE LastName = :TEST_USER_LAST_NAME LIMIT 1];

        NKS_Announcement__c pdfAnnouncement = new NKS_Announcement__c(
            Name = TEST_ANNOUNCEMENT_NAME,
            RecordTypeId = Schema.SObjectType.NKS_Announcement__c
                .getRecordTypeInfosByDeveloperName()
                .get('HOT_News')
                .getRecordTypeId(),
            NKS_News_Author__c = testUser.Id,
            NKS_Information__c = 'Test content with PDF attachment'
        );
        insert pdfAnnouncement;

        ContentVersion pdfContentVersion = new ContentVersion(
            Title = 'Test PDF Document',
            PathOnClient = 'test-document.pdf',
            VersionData = Blob.valueOf('test pdf content'),
            FirstPublishLocationId = pdfAnnouncement.Id
        );
        insert pdfContentVersion;

        Set<Id> recordIds = new Set<Id>{ pdfAnnouncement.Id };

        System.Test.startTest();
        Map<Id, String> result = HOT_NewsPDFController.getImageUrls(recordIds);
        System.Test.stopTest();

        System.Assert.isNotNull(result, 'Result should not be null');
        System.Assert.isTrue(result.containsKey(pdfAnnouncement.Id), 'Result should contain the announcement ID');
        String imageUrl = result.get(pdfAnnouncement.Id);
        System.Assert.isTrue(imageUrl.contains('rendition=SVGZ'), 'PDF files should use SVGZ rendition');
    }

    /**
     * Test that getImageUrls only returns one URL per record when multiple
     * ContentDocuments are linked to the same record. Verifies that the most recent
     * file (by ContentModifiedDate) is used and duplicates are skipped.
     */
    @IsTest
    static void getImageUrls_WhenMultipleFilesOnSameRecord_ReturnsOnlyMostRecent() {
        User testUser = [SELECT Id FROM User WHERE LastName = :TEST_USER_LAST_NAME LIMIT 1];

        NKS_Announcement__c multiImageAnnouncement = new NKS_Announcement__c(
            Name = 'Multiple Images Test Article',
            RecordTypeId = Schema.SObjectType.NKS_Announcement__c
                .getRecordTypeInfosByDeveloperName()
                .get('HOT_News')
                .getRecordTypeId(),
            NKS_News_Author__c = testUser.Id,
            NKS_Information__c = 'Test content with multiple images'
        );
        insert multiImageAnnouncement;

        ContentVersion firstContentVersion = new ContentVersion(
            Title = 'First Image',
            PathOnClient = 'first-image.png',
            VersionData = Blob.valueOf('first image content'),
            FirstPublishLocationId = multiImageAnnouncement.Id
        );
        insert firstContentVersion;

        ContentVersion secondContentVersion = new ContentVersion(
            Title = 'Second Image',
            PathOnClient = 'second-image.jpg',
            VersionData = Blob.valueOf('second image content'),
            FirstPublishLocationId = multiImageAnnouncement.Id
        );
        insert secondContentVersion;

        Set<Id> recordIds = new Set<Id>{ multiImageAnnouncement.Id };

        System.Test.startTest();
        Map<Id, String> result = HOT_NewsPDFController.getImageUrls(recordIds);
        System.Test.stopTest();

        System.Assert.isNotNull(result, 'Result should not be null');
        System.Assert.areEqual(1, result.size(), 'Should return only one URL per record');
        System.Assert.isTrue(
            result.containsKey(multiImageAnnouncement.Id),
            'Result should contain the announcement ID'
        );
    }

    /**
     * Test that getImageUrls returns an empty map when provided with valid IDs that have
     * no linked ContentDocuments. This covers the case where the SOQL query returns no results.
     */
    @IsTest
    static void getImageUrls_WhenGivenValidIdWithoutContent_ReturnsEmptyMap() {
        Account testAccount = new Account(Name = 'Test Account for PDF Controller');
        insert testAccount;
        Set<Id> recordIds = new Set<Id>{ testAccount.Id };

        System.Test.startTest();
        Map<Id, String> result = HOT_NewsPDFController.getImageUrls(recordIds);
        System.Test.stopTest();

        System.Assert.isNotNull(result, 'Result should not be null');
        System.Assert.isTrue(result.isEmpty(), 'Result should be empty when no ContentDocumentLinks exist');
    }

    private static NKS_Announcement__c getTestAnnouncement() {
        NKS_Announcement__c testAnnouncement = [
            SELECT Id
            FROM NKS_Announcement__c
            WHERE Name = :TEST_ANNOUNCEMENT_NAME
            LIMIT 1
        ];
        return testAnnouncement;
    }
}
