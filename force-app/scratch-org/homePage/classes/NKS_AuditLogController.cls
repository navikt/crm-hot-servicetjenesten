public with sharing class NKS_AuditLogController {
    private static final Id USERID = UserInfo.getUserId();
    private static final String KNOWLEDGE_LOOKUP_FIELD = 'Knowledge__c';
    private static final String ANNOUNCEMENT_LOOKUP_FIELD = 'Announcement__c';
    private static final String KNOWLEDGE_AUDIT_LOG = 'Knowledge Audit Log';
    private static final String ANNOUNCEMENT_AUDIT_LOG = 'Announcement Audit Log';
    private static final String STATUS_DRAFT = 'Draft';
    private static LoggerUtility logger = new LoggerUtility('NKS Audit Log');

    @AuraEnabled
    public static void createAuditLog(Id recordId, String lookupField) {
        if (recordId == null || lookupField == null) {
            return;
        }

        if (lookupField == KNOWLEDGE_LOOKUP_FIELD) {
            Knowledge__kav kav = [
                SELECT Id, PublishStatus, KnowledgeArticleId
                FROM Knowledge__kav
                WHERE Id = :recordId
                LIMIT 1
            ];
            if (kav.PublishStatus != STATUS_DRAFT) {
                createAuditLogRecord(recordId, KNOWLEDGE_AUDIT_LOG, kav.KnowledgeArticleId);
            }
        } else if (lookupField == ANNOUNCEMENT_LOOKUP_FIELD) {
            NKS_Announcement__c announcement = [
                SELECT Id, NKS_News_Status__c
                FROM NKS_Announcement__c
                WHERE Id = :recordId
                LIMIT 1
            ];
            if (announcement.NKS_News_Status__c != STATUS_DRAFT) {
                createAuditLogRecord(recordId, ANNOUNCEMENT_AUDIT_LOG, null);
            }
        }
    }

    private static void createAuditLogRecord(Id recordId, String lookupField, String knowledgeArticleId) {
        try {
            NKS_Audit_Log__c auditLog = new NKS_Audit_Log__c();
            auditLog.RecordTypeId = getRecordTypeId(lookupField);
            auditLog.User__c = USERID;
            auditLog.Operation__c = 'View';

            if (lookupField == KNOWLEDGE_AUDIT_LOG) {
                auditLog.Knowledge__c = recordId;
                auditLog.Knowledge_Id__c = recordId;
                auditLog.Knowledge_Article_Id__c = knowledgeArticleId;
            } else if (lookupField == ANNOUNCEMENT_AUDIT_LOG) {
                auditLog.Announcement__c = recordId;
                auditLog.Announcement_Id__c = recordId;
            }

            Database.SaveResult sr = Database.insert(auditLog, false);
            if (!sr.isSuccess()) {
                logErrorMessage(sr);
            }
        } catch (Exception e) {
            logger.error(
                'Failed to create Audit Log record: ' + e.getMessage(),
                null,
                CRM_ApplicationDomain.Domain.NKS
            );
        } finally {
            logger.publish();
        }
    }

    @AuraEnabled(cacheable=true)
    public static Integer countViews(Id recordId, String lookupField) {
        List<Id> originalList = new List<Id>();
        Set<Id> resultList = new Set<Id>();
        Map<String, Object> bindParams = new Map<String, Object>{ 'recordId' => recordId };
        String query =
            'SELECT COUNT_DISTINCT(User__c) nmbOfUniqueViews FROM NKS_Audit_Log__c WHERE ' +
            lookupField +
            ' = :recordId';

        try {
            AggregateResult[] countResult = Database.queryWithBinds(query, bindParams, AccessLevel.SYSTEM_MODE);
            return Integer.valueOf(countResult[0].get('nmbOfUniqueViews'));
        } catch (Exception ex) {
            throw new AuraHandledException('Problem counting article veiws: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Boolean isKnowledgeUser() {
        try {
            return [SELECT Id FROM User WHERE UserPermissionsKnowledgeUser = TRUE AND Id = :USERID]?.Id != null;
        } catch (Exception e) {
            throw new AuraHandledException('Problem checking knowledge user: ' + e.getMessage());
        }
    }

    @TestVisible
    private static String getRecordTypeId(String recordTypeName) {
        return Schema.SObjectType.NKS_Audit_Log__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
    }

    @TestVisible
    private static void logErrorMessage(Database.SaveResult sr) {
        String errorMessage = 'The following error has occurred under creation of Audit Log record:\n';
        for (Database.Error error : sr.getErrors()) {
            errorMessage += error.getStatusCode() + ': ' + error.getMessage() + '\n';
        }
        logger.error(errorMessage, null, CRM_ApplicationDomain.Domain.NKS);
    }
}
