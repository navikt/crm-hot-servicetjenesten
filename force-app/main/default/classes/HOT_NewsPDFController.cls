/**
 * This class is used as the controller for the HOT_NewsArticlePDF Visualforce page.
 *
 * @author Kenneth Sørensen
 * @group HOT Public 360 Integration
 * @since November 2025
 */
public with sharing class HOT_NewsPDFController {
    /**
     * The title of the news article.
     */
    public string title { get; set; }
    /**
     * The author of the news article.
     */
    public string author { get; set; }
    /**
     * The publish date of the news article.
     */
    public String publishDate { get; set; }
    /**
     * The last modified date of the news article.
     */
    public string lastModifiedDate { get; set; }
    /**
     * The other authors of the news article.
     */
    public string otherAuthors { get; set; }
    /**
     * The information content of the news article.
     */
    public string information { get; set; }
    /**
     * The URL of the image associated with the news article.
     */
    public string imageURL { get; set; }

    /**
     * Constructor for HOT_NewsPDFController class.
     */
    public HOT_NewsPDFController() {
        string recordId = ApexPages.CurrentPage().getparameters().get('id');
        NKS_Announcement__c news = getNews(recordId);
        string userId = news.NKS_News_Author__c;

        title = news.Name;
        author = [SELECT Name FROM User WHERE Id = :userId].Name;
        publishDate = news.NKS_News_Publish_Date__c.format('dd. MMMMM yyyy, HH:mm');
        lastModifiedDate = news.LastModifiedDate.format('dd. MMMMM yyyy, HH:mm');
        otherAuthors = news.NKS_News_Other_Authors__c;
        information = news.NKS_Information__c;
        imageURL = news.NKS_ImageURL__c;
    }

    /**
     * Retrieves the news article record by its ID.
     *
     * @param recordId The ID of the news article.
     * @return The NKS_Announcement__c record.
     */
    public static NKS_Announcement__c getNews(Id recordId) {
        List<NKS_Announcement__c> news = [
            SELECT
                Id,
                Name,
                NKS_News_Author__c,
                NKS_News_Other_Authors__c,
                NKS_News_Publish_Date__c,
                NKS_News_Update_Date__c,
                LastModifiedDate,
                NKS_Information__c,
                NKS_ImageURL__c
            FROM NKS_Announcement__c
            WHERE Id = :recordId
        ];
        if (news.isEmpty()) {
            return null;
        }
        news[0].NKS_ImageURL__c = getImageUrl(news[0].Id);
        return news[0];
    }

    /**
     * Retrieves the image URL for a given record ID.
     *
     * @param recordId The ID of the record.
     * @return The image URL as a string.
     */
    public static Map<Id, String> getImageUrls(Set<Id> recordIds) {
        Map<Id, String> urlMap = new Map<Id, String>();
        for (ContentDocumentLink cdl : [
            SELECT
                Id,
                ContentDocumentId,
                ContentDocument.LatestPublishedVersionId,
                ContentDocument.ContentModifiedDate,
                ContentDocument.FileType,
                LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :recordIds
            ORDER BY ContentDocument.ContentModifiedDate DESC
        ]) {
            if (urlMap.containsKey(cdl.LinkedEntityId)) {
                continue;
            }

            String urlString =
                '/sfc/servlet.shepherd/version/renditionDownload?rendition=' +
                (cdl.ContentDocument?.FileType == 'PDF' ? 'SVGZ' : 'ORIGINAL_Png') +
                '&versionId=' +
                cdl.ContentDocument?.LatestPublishedVersionId;

            urlMap.put(cdl.LinkedEntityId, urlString);
        }
        return urlMap;
    }

    /**
     * Retrieves the image URL for a specific record ID.
     *
     * @param recordId The ID of the record.
     * @return The image URL as a string.
     */
    public static String getImageUrl(Id recordId) {
        return getImageUrls(new Set<Id>{ recordId }).get(recordId);
    }
}
