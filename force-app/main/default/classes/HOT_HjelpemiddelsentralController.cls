public with sharing class HOT_HjelpemiddelsentralController {
    @AuraEnabled(cacheable=true)
    public static Person__c getPersonMunicipalityAndRegions(Id recordId, String objectApiName) {
        Person__c person;
        if (objectApiName == 'Account') {
            person = [
                SELECT Id, INT_RegionNumber__c, INT_MunicipalityNumber__c, INT_TemporaryMunicipalityNumber__c
                FROM Person__c
                WHERE Id IN (SELECT CRM_Person__c FROM Account WHERE Id = :recordId)
            ];
        }
        if (objectApiName == 'Case') {
            Case caseRecord = [
                SELECT AccountId
                FROM Case
                WHERE Id = :recordId
            ];
            if (caseRecord.AccountId != null) {
                person = [
                    SELECT Id, INT_RegionNumber__c, INT_MunicipalityNumber__c, INT_TemporaryMunicipalityNumber__c
                    FROM Person__c
                    WHERE
                        Id IN (
                            SELECT CRM_Person__c
                            FROM Account
                            WHERE Id = :caseRecord.AccountId
                        )
                ];
            }
        }

        return person;
    }
    @AuraEnabled(cacheable=true)
    public static List<HOT_HjelpemiddelsentralMapping__mdt> getAllHjelpemiddelSentraler() {
        List<HOT_HjelpemiddelsentralMapping__mdt> allHjelpemiddelSentraler = [
            SELECT Hjelpemiddelsentral_name__c, MunicipalityNumbers__c, RegionNumbers__c, NAVurl__c
            FROM HOT_HjelpemiddelsentralMapping__mdt
        ];
        return allHjelpemiddelSentraler;
    }
}
