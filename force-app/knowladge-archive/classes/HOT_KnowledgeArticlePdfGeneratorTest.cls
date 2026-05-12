/**
 * Test class for HOT_KnowledgeArticlePdfGenerator.
 *
 * @author Kenneth Sørensen
 * @group HOT Public 360 Integration
 * @see HOT_KnowledgeArticlePdfGenerator
 * @since May 2026
 */
@IsTest
private class HOT_KnowledgeArticlePdfGeneratorTest {
    /**
     * What this test verifies:
     * - getPdf() returns a valid Blob when given a valid article ID.
     * Why it matters:
     * - Ensures PDF generation works correctly for knowledge articles to be archived.
     *
     * @see HOT_KnowledgeArticlePdfGenerator.getPdf
     */
    @IsTest
    static void getPdf_withValidArticleId_returnsBlob() {
        Knowledge__kav article = new Knowledge__kav(
            Title = 'Test Article',
            UrlName = 'Test-Article',
            Summary = 'Test Summary'
        );
        insert article;

        System.Test.startTest();
        Blob result = HOT_KnowledgeArticlePdfGenerator.getPdf(article.Id);
        System.Test.stopTest();

        System.Assert.isNotNull(result, 'PDF blob should not be null');
        System.Assert.areEqual('Unit.Test', result.toString(), 'PDF blob should contain test content');
    }
}
