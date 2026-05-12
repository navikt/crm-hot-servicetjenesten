/**
 * This class handles the archiving of HoT Servicetjenesten knowladge articles to Public 360.
 *
 * {@hidden TODO: This class will be refactored to use P360 service classes and integration in the
 * future.}
 *
 * @author Kenneth Sørensen
 * @group HOT Public 360 Integration
 * @since May 2026
 */
public with sharing class HOT_KnowledgeArchiveHandler {
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
    private HOT_KnowledgeArchiveSettings__c knowledgeArchiveSettings;

    /**
     * The Http Response object that is returned from the operation.
     */
    @TestVisible
    public HttpResponse operationResponse { get; private set; }

    /**
     * Constructor for HOT_KnowledgeArchiveHandler class.
     */
    public HOT_KnowledgeArchiveHandler() {
        this.knowledgeArchiveSettings = HOT_KnowledgeArchiveSettings__c.getOrgDefaults();
        this.isSandbox = (Test.isRunningTest() && testIsSandboxOverride != null)
            ? testIsSandboxOverride
            : [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }

    /**
     * Archives a knowledge article to Public 360.
     *
     * @param article The knowledge article to be archived.
     */
    public void execute(Knowledge__kav article) {
        LoggerUtility logger = new LoggerUtility();
        HOT_KnowledgeArchiveCaseMapping__mdt knowledgeArchiveCaseMapping = getKnowledgeArchiveCaseMapping();

        if (knowledgeArchiveCaseMapping == null) {
            logger.error('Fant ikke metadata for ' + article.Title, null, CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
            return;
        }

        String caseNumber = getCaseNumber(knowledgeArchiveCaseMapping);
        String navIdent = getNavIdent();
        String navEnhet = getNavEnhet();

        if (caseNumber == null || navIdent == null || navEnhet == null) {
            logger.error(
                'Fant ikke saksnummer/NAV-Ident/NAV-enhet for ' + article.Title,
                null,
                CRM_ApplicationDomain.Domain.HOT
            );
            logger.publish();
            return;
        }

        archiveArticle(article, caseNumber, navIdent, navEnhet);
        return;
    }

    /**
     * Gets the metadata settings for archiving knowledge articles.
     *
     * @return HOT_KnowledgeArchiveCaseMapping__mdt The metadata settings record.
     * @see HOT_KnowledgeArchiveCaseMapping__mdt
     */
    private HOT_KnowledgeArchiveCaseMapping__mdt getKnowledgeArchiveCaseMapping() {
        List<HOT_KnowledgeArchiveCaseMapping__mdt> knowledgeArchiveCaseMappingList = (List<HOT_KnowledgeArchiveCaseMapping__mdt>) new CustomMetadataDAO()
            .getCustomMetadataRecords(
                'SELECT Id, CaseNumberProd__c, CaseNumberTest__c, ActiveFrom__c, Order__c ' +
                    'FROM HOT_KnowledgeArchiveCaseMapping__mdt ' +
                    'WHERE ActiveFrom__c <= TODAY ' +
                    'ORDER BY ActiveFrom__c DESC, Order__c DESC ' +
                    'LIMIT 1'
            );

        HOT_KnowledgeArchiveCaseMapping__mdt knowledgeArchiveCaseMapping;
        if (knowledgeArchiveCaseMappingList.size() > 0) {
            knowledgeArchiveCaseMapping = knowledgeArchiveCaseMappingList[0];
        }

        return knowledgeArchiveCaseMapping;
    }

    /**
     * Gets the case number based on the environment.
     *
     * @param settings The HOT_KnowledgeArchiveCaseMapping__mdt settings record.
     * @return Case number as String
     * @see HOT_KnowledgeArchiveCaseMapping__mdt
     */
    @TestVisible
    private String getCaseNumber(HOT_KnowledgeArchiveCaseMapping__mdt settings) {
        if (settings == null) {
            return null;
        }

        return isSandbox ? settings.CaseNumberTest__c : settings.CaseNumberProd__c;
    }

    /**
     * Gets the Nav identifier based on the environment.
     *
     * @return Nav identifier as String
     * @see HOT_KnowledgeArchiveSettings__c
     */
    @TestVisible
    private String getNavIdent() {
        if (this.knowledgeArchiveSettings == null || this.knowledgeArchiveSettings.Id == null) {
            return null;
        }
        return isSandbox
            ? this.knowledgeArchiveSettings.NavIdentTest__c
            : this.knowledgeArchiveSettings.NavIdentProd__c;
    }

    /**
     * Gets the Nav unit based on the environment.
     *
     * @return Nav unit as String
     * @see HOT_KnowledgeArchiveSettings__c
     */
    @TestVisible
    private String getNavEnhet() {
        if (this.knowledgeArchiveSettings == null || this.knowledgeArchiveSettings.Id == null) {
            return null;
        }
        return isSandbox
            ? this.knowledgeArchiveSettings.NavEnhetTest__c
            : this.knowledgeArchiveSettings.NavEnhetProd__c;
    }

    @TestVisible
    private Boolean archiveArticle(Knowledge__kav article, String caseNumber, String navIdent, String navUnitId) {
        Blob articlePdf = HOT_KnowledgeArticlePdfGenerator.getPdf(article.Id);

        Boolean isSuccess = false;
        String requestBody = createRequestBody(caseNumber, navIdent, article, articlePdf);
        isSuccess = send(requestBody);

        return isSuccess;
    }

    /**
     * @description This method is used to create the request body for the Public 360 API with the given article and article PDF.
     *
     * Body:
     * {
     *     "Title":"Test Kunnskapsartikkel No. 1",
     *     "DefaultValueSet":"NKSSalesForce",
     *     "CaseNumber":"25/12742",
     *     "AccessGroup":"Alle ansatte i Nav",
     *     "ResponsiblePersonIdNumber":"Nav Ident til ansvarlig person",
     *     "Files":[
     *         {
     *             "Title": "Test Kunnskapsartikkel No. 1",
     *             "Format": "txt",
     *             "Base64Data": "RGV0dGUgZXIgYmVycmUgZWluIGVua2VsIHRlc3Q="
     *         }
     *     ]
     *  }
     *
     * @author Kenneth Soerensen <kenneth.sorensen@nav.no>, Nav
     * @since 0.1.0, March 2025
     * @param caseNumber The case number for the article.
     * @param navIdent The NAV Ident for the article.
     * @param article The article to create the request body for.
     * @param articlePdf The article PDF to include in the request body.
     * @return  `String`The request body for the Public 360 API Create Document.
     */
    @TestVisible
    private String createRequestBody(String caseNumber, String navIdent, Knowledge__kav article, Blob articlePdf) {
        JSONGenerator generator = JSON.createGenerator(false);
        generator.writeStartObject();
        generator.writeStringField('Title', article.Title);
        generator.writeStringField('DefaultValueSet', this.knowledgeArchiveSettings.P360DefaultValueSet__c);
        generator.writeStringField('CaseNumber', caseNumber);
        generator.writeStringField('AccessGroup', this.knowledgeArchiveSettings.P360AccessGroup__c);
        generator.writeStringField('ResponsiblePersonIdNumber', navIdent);
        generator.writeFieldName('Files');
        generator.writeStartArray();
        generator.writeStartObject();
        generator.writeStringField('Title', article.Title);
        generator.writeStringField('Format', 'pdf');
        generator.writeStringField('Base64Data', EncodingUtil.base64Encode(articlePdf));
        generator.writeEndObject();
        generator.writeEndArray();
        generator.writeEndObject();

        return generator.getAsString();
    }

    /**
     * @description This method is used to send the request to the Public 360 API.
     *
     * @author Kenneth Soerensen <kenneth.sorensen@nav.no>, Nav
     * @since 0.1.0, March 2025
     * @param requestBody The request body to send.
     * @return `Boolean` Indicate the status if the request was successfully sent.
     */
    public Boolean send(String requestBody) {
        String calloutName = isSandbox
            ? this.knowledgeArchiveSettings.CalloutNameTest__c
            : this.knowledgeArchiveSettings.CalloutNameProd__c;

        this.operationResponse = callout(CREATE_DOCUMENT, requestBody, calloutName);

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
     * @description This method is used to perform the callout to the Public 360 API.
     *
     * @author Kenneth Soerensen <kenneth.sorensen@nav.no>, Nav
     * @since 0.1.0, March 2025
     * @param operationType The operation type to perform.
     * @param requestBody The request body to send.
     * @param calloutName The name of the callout to use.
     * @return `HttpResponse` The response from the callout.
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
}
