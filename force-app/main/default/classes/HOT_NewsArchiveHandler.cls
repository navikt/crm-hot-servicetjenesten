/**
 * This class handles the archiving of HoT Servicetjenesten news articles to Public 360.
 *
 * {@hidden TODO: This class will be refactored to use P360 service classes and integration in the
 * future.}
 *
 * @author Kenneth Sørensen
 * @group HOT Public 360 Integration
 * @since November 2025
 */
public with sharing class HOT_NewsArchiveHandler {
    /**
     * This constant is used to define the document service in the Public 360 API.
     */
    public static final String DOCUMENT_SERVICE = 'DocumentService';

    /**
     * The operation type for creating a document in Public 360.
     */
    public static final String CREATE_DOCUMENT = 'CreateDocument';

    /**
     * Indicates whether the current environment is a sandbox.
     */
    private Boolean isSandbox;

    /**
     * Test-only override for the isSandbox flag. Set this in tests to control
     * sandbox vs production code paths without querying Organization.
     */
    @TestVisible
    private static Boolean testIsSandboxOverride = null;

    /**
     * The news archive settings for the organization.
     */
    private HOT_NewsArchiveSettings__c newsArchiveSettings;

    /**
     * The Http Response object that is returned from the operation.
     */
    @TestVisible
    public HttpResponse operationResponse { get; private set; }

    /**
     * Constructor for HOT_NewsArchiveHandler class.
     */
    public HOT_NewsArchiveHandler() {
        this.newsArchiveSettings = HOT_NewsArchiveSettings__c.getOrgDefaults();
        this.isSandbox = (Test.isRunningTest() && testIsSandboxOverride != null)
            ? testIsSandboxOverride
            : [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }

    /**
     * Archives a news article to Public 360.
     *
     * @param article The news article to be archived.
     */
    public void execute(NKS_Announcement__c article) {
        LoggerUtility logger = new LoggerUtility();
        HOT_NewsArchiveMapping__mdt newsArchiveMappingSettings = getNewsArchiveMappingSettings();

        if (newsArchiveMappingSettings == null) {
            logger.error('Fant ikke metadata for ' + article.Name, null, CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
            return;
        }

        String caseNumber = getCaseNumber(newsArchiveMappingSettings);
        String navIdent = getNavIdent(newsArchiveMappingSettings);
        String navEnhet = getNavEnhet(newsArchiveMappingSettings);

        if (caseNumber == null || navIdent == null || navEnhet == null) {
            logger.error(
                'Fant ikke saksnummer/NAV-Ident/NAV-enhet for ' + article.Name,
                null,
                CRM_ApplicationDomain.Domain.HOT
            );
            logger.publish();
            return;
        }
    }

    /**
     * Gets the metadata settings for archiving news articles based on the environment.
     *
     * @return HOT_NewsArchiveMapping__mdt The metadata settings record.
     * @see HOT_NewsArchiveMapping__mdt
     */
    private HOT_NewsArchiveMapping__mdt getNewsArchiveMappingSettings() {
        string env = isSandbox ? 'Test' : 'Prod';

        List<HOT_NewsArchiveMapping__mdt> newsArchiveMappingList = (List<HOT_NewsArchiveMapping__mdt>) new CustomMetadataDAO()
            .getCustomMetadataRecords(
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
                    'LIMIT 1'
            );

        HOT_NewsArchiveMapping__mdt newsArchiveMapping;
        if (newsArchiveMappingList.size() > 0) {
            newsArchiveMapping = newsArchiveMappingList[0];
        }
        return newsArchiveMapping;
    }

    /**
     * Gets the case number based on the environment.
     *
     * @param settings The HOT_NewsArchiveMapping__mdt settings record.
     * @return Case number as String
     * @see HOT_NewsArchiveMapping__mdt
     */
    @TestVisible
    private String getCaseNumber(HOT_NewsArchiveMapping__mdt settings) {
        if (settings == null) {
            return null;
        }

        return isSandbox ? settings.CaseNumberTest__c : settings.CaseNumberProd__c;
    }

    /**
     * Gets the Nav identifier based on the environment.
     *
     * @param settings The HOT_NewsArchiveMapping__mdt settings record.
     * @return Nav identifier as String
     * @see HOT_NewsArchiveMapping__mdt
     */
    @TestVisible
    private String getNavIdent(HOT_NewsArchiveMapping__mdt settings) {
        if (settings == null) {
            return null;
        }
        return isSandbox ? settings.NavIdTest__c : settings.NavIdProd__c;
    }

    /**
     * Gets the Nav unit based on the environment.
     *
     * @param settings The HOT_NewsArchiveMapping__mdt settings record.
     * @return Nav unit as String
     * @see HOT_NewsArchiveMapping__mdt
     */
    @TestVisible
    private String getNavEnhet(HOT_NewsArchiveMapping__mdt settings) {
        if (settings == null) {
            return null;
        }
        return isSandbox ? settings.NavEnhetTest__c : settings.NavEnhetProd__c;
    }

    /**
     * This method is used to create the request body for the Public 360 API with the given article
     * and article PDF.
     *
     * Body:
     * {@code
     * {
     *     "Title":"Test Nyhetsartikkel No. 1",
     *     "DefaultValueSet":"NKSSalesForce",
     *     "CaseNumber":"25/12742",
     *     "AccessGroup":"Alle ansatte i Nav",
     *     "ResponsiblePersonIdNumber":"A133191",
     *     "Files":[
     *         {
     *             "Title": "Test Nyhetsartikkel No. 1",
     *             "Format": "txt",
     *             "Base64Data": "RGV0dGUgZXIgYmVycmUgZWluIGVua2VsIHRlc3Q="
     *         }
     *     ]
     * }
     * }
     *
     * @param caseNumber The case number for the article.
     * @param navIdent The Nav Ident for the article.
     * @param article The article to create the request body for.
     * @param articlePdf The article PDF to include in the request body.
     * @return  `String`The request body for the Public 360 API Create Document.
     */
    @TestVisible
    private String createRequestBody(String caseNumber, String navIdent, NKS_Announcement__c article, Blob articlePdf) {
        JSONGenerator generator = JSON.createGenerator(false);
        generator.writeStartObject();
        generator.writeStringField('Title', article.Name);
        generator.writeStringField('DefaultValueSet', 'NKSSalesForce');
        generator.writeStringField('CaseNumber', caseNumber);
        generator.writeStringField('AccessGroup', 'Alle ansatte i Nav');
        generator.writeStringField('ResponsiblePersonIdNumber', navIdent);
        generator.writeFieldName('Files');
        generator.writeStartArray();
        generator.writeStartObject();
        generator.writeStringField('Title', article.Name);
        generator.writeStringField('Format', 'pdf');
        generator.writeStringField('Base64Data', EncodingUtil.base64Encode(articlePdf));
        generator.writeEndObject();
        generator.writeEndArray();
        generator.writeEndObject();

        return generator.getAsString();
    }

    /**
     * This method is used to send the request to the Public 360 API.
     *
     * @param requestBody The request body to send.
     * @return Boolean indicating success or failure of the operation.
     */
    public Boolean send(String requestBody) {
        this.operationResponse = callout(CREATE_DOCUMENT, requestBody, this.newsArchiveSettings.CalloutName__c);

        if (this.operationResponse.getStatusCode() != 200) {
            LoggerUtility logger = new LoggerUtility();
            logger.error(
                'Error: ' + this.operationResponse.getStatusCode() + ' - ' + this.operationResponse.getStatus(),
                null,
                CRM_ApplicationDomain.Domain.HOT
            );
            logger.publish();
            return false;
        }

        return true;
    }

    /**
     * This method is used to perform the callout to the Public 360 API.
     *
     * @param operationType The operation type to perform.
     * @param requestBody The request body to send.
     * @param calloutName The name of the callout to use.
     */
    @TestVisible
    private static HttpResponse callout(String operationType, String requestBody, String calloutName) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + calloutName + '/' + DOCUMENT_SERVICE + '/' + operationType);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(requestBody);

        Http http = new Http();
        HttpResponse response = http.send(request);

        return response;
    }

    /**
     * This method is used to archive the article to Public 360.
     *
     * @param article Article to archive
     * @param caseNumber Case number
     * @param navIdent Nav ident
     * @param navEnhet Nav enhet
     * @return Boolean indicating success or failure of the operation.
     */
    @TestVisible
    private Boolean archiveArticle(NKS_Announcement__c article, String caseNumber, String navIdent, String navEnhet) {
        Blob articlePdf;
        if (Test.isRunningTest()) {
            articlePdf = blob.valueOf('Unit.Test');
        } else {
            articlePdf = HOT_NewsArticlePdfGenerator.getPdf(article.Id);
        }

        Map<String, Blob> filesToSend = new Map<String, Blob>();
        Map<String, String> fileNameFormatMap = new Map<String, String>();
        String manifestName;
        Boolean isSuccess = false;

        String requestBody = createRequestBody(caseNumber, navIdent, article, articlePdf);
        isSuccess = send(requestBody);

        return isSuccess;
    }
}
