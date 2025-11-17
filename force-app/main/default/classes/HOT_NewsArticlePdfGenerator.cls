/**
 * This class is used to generate a PDF for a News Article.
 *
 * {@hidden TODO: Move the PDF generation to OpenText Exstream in the future.}
 *
 * @author Kenneth Sørensen
 * @group HOT Public 360 Integration
 * @since November 2025
 */
public with sharing class HOT_NewsArticlePdfGenerator {
    public static Blob getPdf(Id articleId) {
        PageReference PDf = Page.HOT_NewsArticlePDF;
        PDf.getParameters().put('id', articleId);
        PDf.setRedirect(true);

        Blob b;
        b = Test.isRunningTest() ? Blob.valueOf('Unit.Test') : PDf.getContent();
        return b;
    }
}
