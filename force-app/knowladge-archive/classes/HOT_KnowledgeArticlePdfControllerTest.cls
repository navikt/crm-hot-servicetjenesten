/**
 * Test class for HOT_KnowledgeArticlePdfController.
 *
 * @author Kenneth Sørensen
 * @group HOT Public 360 Integration
 * @see HOT_KnowledgeArticlePdfController
 * @since May 2026
 */
@IsTest
private class HOT_KnowledgeArticlePdfControllerTest {
    /**
     * What this test verifies:
     * - The controller constructor correctly fetches and populates all properties from a Knowledge__kav record.
     * Why it matters:
     * - Ensures the Visualforce page displays accurate knowledge article data for PDF generation.
     *
     * @see HOT_KnowledgeArticlePdfController
     */
    @IsTest
    static void constructor_withValidArticleId_populatesAllProperties() {
        // Arrange
        Knowledge__kav article = new Knowledge__kav(
            Title = 'Test Article Title',
            UrlName = 'Test-Article-Title',
            NKS_Summary__c = 'Test Summary',
            NKS_UserInformation__c = 'User Info',
            Article__c = 'Article Content',
            NKS_Nynorsk__c = 'Nynorsk Content',
            NKS_English__c = 'English Content',
            EmployerInformation__c = 'Employer Info',
            EmployerInformationInternal__c = 'Employer Info Internal',
            InternationalInformation__c = 'International Info',
            InternationalInformationInternal__c = 'International Info Internal',
            AdvisorInformation__c = 'Advisor Info',
            AdvisorInformationInternal__c = 'Advisor Info Internal',
            NKS_Nav_no__c = 'Nav.no Content',
            NKS_Legislation__c = 'Legislation Content',
            NKS_Resources__c = 'Resources Content',
            WhoDoesWhat__c = 'Who Does What Content'
        );
        insert article;

        PageReference pageRef = Page.HOT_KnowledgeArticlePdf;
        pageRef.getParameters().put('id', article.Id);
        Test.setCurrentPage(pageRef);

        // Act
        Test.startTest();
        HOT_KnowledgeArticlePdfController controller = new HOT_KnowledgeArticlePdfController();
        Test.stopTest();

        // Assert
        System.Assert.areEqual('Test Article Title', controller.title, 'Title should match');
        System.Assert.areEqual('Test Summary', controller.summary, 'Summary should match');
        System.Assert.areEqual('User Info', controller.userInformation, 'User information should match');
        System.Assert.areEqual('Article Content', controller.article, 'Article should match');
        System.Assert.areEqual('Nynorsk Content', controller.nynorsk, 'Nynorsk should match');
        System.Assert.areEqual('English Content', controller.english, 'English should match');
        System.Assert.areEqual('Employer Info', controller.employerInformation, 'Employer information should match');
        System.Assert.areEqual(
            'Employer Info Internal',
            controller.employerInformationInternal,
            'Employer information internal should match'
        );
        System.Assert.areEqual(
            'International Info',
            controller.internationalInformation,
            'International information should match'
        );
        System.Assert.areEqual(
            'International Info Internal',
            controller.internationalInformationInternal,
            'International information internal should match'
        );
        System.Assert.areEqual('Advisor Info', controller.advisorInformation, 'Advisor information should match');
        System.Assert.areEqual(
            'Advisor Info Internal',
            controller.advisorInformationInternal,
            'Advisor information internal should match'
        );
        System.Assert.areEqual('Nav.no Content', controller.navno, 'Nav.no should match');
        System.Assert.areEqual('Legislation Content', controller.legislation, 'Legislation should match');
        System.Assert.areEqual('Resources Content', controller.resources, 'Resources should match');
        System.Assert.areEqual('Who Does What Content', controller.whoDoesWhat, 'Who does what should match');
    }
}
