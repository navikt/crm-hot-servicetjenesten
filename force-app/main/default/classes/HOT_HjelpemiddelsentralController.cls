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
    @AuraEnabled(cacheable=true)
    public static HOT_Bilsenter_Mapping__mdt getBilsenter(String accountId) {
        Account account = [
            SELECT CRM_Person__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        Id personId = account.CRM_Person__c;

        Person__c person = [
            SELECT Id, CRM_Municipality__r.CRM_Code__c, CRM_Municipality__r.Name, INT_RegionNumber__c
            FROM Person__c
            WHERE Id = :personId
            LIMIT 1
        ];

        HOT_Bilsenter_Mapping__mdt bilsenterMapping = [
            SELECT Bilsenter_Navn__c, Bilsenter_Url__c, Fylkenummer__c, Kommunenummer__c
            FROM HOT_Bilsenter_Mapping__mdt
            WHERE Fylkenummer__c = :Integer.valueOf(person.INT_RegionNumber__c)
            LIMIT 1
        ];

        return bilsenterMapping;
    }
}
