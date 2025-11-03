public with sharing class HOT_HomePageController {
    @AuraEnabled(cacheable=true)
    public static String getField(String type) {
        try {
            List<SObject> announcement;
            announcement = Database.query(
                'SELECT NKS_Information__c FROM NKS_Announcement__c WHERE RecordType.DeveloperName = ' +
                    '\'' +
                    type +
                    '\' ' +
                    'ORDER BY CreatedDate DESC LIMIT 1'
            );

            if (announcement.size() > 0 || String.isNotBlank((String) announcement[0].get('NKS_Information__c'))) {
                return ((String) announcement[0].get('NKS_Information__c'))
                    .replace('<img', '<img style="max-height: 100px"');
            }
            return '';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Knowledge__kav> getReadyResponses() {
        List<Knowledge__kav> readyResponses = [
            SELECT Id, Title, Ready_Response_Title__c
            FROM Knowledge__kav
            WHERE
                RecordType.DeveloperName = 'Response_Readiness'
                AND NKS_Publish_On_Home_Page__c = TRUE
                AND PublishStatus = 'Online'
            ORDER BY LastModifiedDate DESC
            LIMIT 5
        ];
        return readyResponses.isEmpty() ? null : readyResponses;
    }

    /* @AuraEnabled
    public static void updateNksStatus(Map<String, String> fields) {
        if (fields == null || !fields.containsKey('Id')) {
            throw new AuraHandledException('Record ID is required');
        }

        NKS_Announcement__c status = new NKS_Announcement__c(Id = fields.get('Id'));

        if (fields.containsKey('NKS_Information__c')) {
            status.NKS_Information__c = fields.get('NKS_Information__c');
        }

        try {
            Database.SaveResult result = Database.update(status, false);

            if (result.isSuccess()) {
                NKS_Home_Page_Event__e event = new NKS_Home_Page_Event__e(RecordId__c = status.Id);
                EventBus.publish(event);
            } else {
                throw new AuraHandledException('Failed to update the NKS status.');
            }
        } catch (DmlException e) {
            throw new AuraHandledException('Update failed: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static NKS_Announcement__c getNksStatus(String title) {
        try {
            NKS_Announcement__c status = [
                SELECT Id, Name, NKS_Information__c
                FROM NKS_Announcement__c
                WHERE Name = :title AND RecordType.DeveloperName = 'NKS_Status'
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            return status;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving NKS status: ' + e.getMessage());
        }
    }*/
}
