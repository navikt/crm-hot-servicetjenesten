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
}
