/**
 * This class is used to generate a PDF for a HOT Knowledge Article.
 *
 * {@hidden TODO: Move the PDF generation to OpenText Exstream or another solution to generate PDF in the future.}
 *
 * @author Kenneth Sørensen
 * @group HOT Public 360 Integration
 * @since May 2026
 */
public with sharing class HOT_KnowledgeArticlePdfGenerator {
    /**
     * Generates a PDF for a HOT Knowledge Article based on the provided article ID.
     *
     * @param articleId The ID of the knowledge article for which to generate the PDF.
     * @return A Blob representing the generated PDF content.
     */
    public static Blob getPdf(Id articleId) {
        PageReference PDf = Page.HOT_KnowledgeArticlePdf;
        PDf.getParameters().put('id', articleId);
        PDf.setRedirect(true);

        Blob b;
        b = Test.isRunningTest() ? Blob.valueOf('Unit.Test') : PDf.getContent();
        return b;
    }
}
