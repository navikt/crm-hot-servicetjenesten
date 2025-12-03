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
        Set<Decimal> SPLIT_REGION_NUMBERS = new Set<Decimal>{ 32, 34 };
        List<Account> account = [
            SELECT CRM_Person__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        if (account[0].CRM_Person__c == null) {
            return null;
        }

        List<Person__c> person = [
            SELECT Id, INT_MunicipalityNumber__c, INT_RegionNumber__c
            FROM Person__c
            WHERE Id = :account[0].CRM_Person__c
            LIMIT 1
        ];

        List<HOT_Bilsenter_Mapping__mdt> bilsenterMapping = [
            SELECT Bilsenter_Navn__c, Bilsenter_Url__c, Fylkenummer__c, Kommunenummer__c
            FROM HOT_Bilsenter_Mapping__mdt
            WHERE Fylkenummer__c = :Integer.valueOf(person[0].INT_RegionNumber__c)
            LIMIT 2
        ];
        if (bilsenterMapping.size() == 0) {
            return null;
        }
        System.debug('mathias bilsenterMapping fylkenummer >>' + bilsenterMapping[0].Fylkenummer__c);
        System.debug('mathias bilsenterMapping kommunenummer >>' + bilsenterMapping[0].Kommunenummer__c);
        System.debug('mathias bilsenterMapping fylkenummer >>' + bilsenterMapping[0].Fylkenummer__c.intValue());
        System.debug('mathias mapping >>' + bilsenterMapping);
        if (!SPLIT_REGION_NUMBERS.contains(bilsenterMapping[0].Fylkenummer__c.intValue())) {
            return bilsenterMapping[0];
        } else {
            for (HOT_Bilsenter_Mapping__mdt mapping : bilsenterMapping) {
                if (mapping.Kommunenummer__c.contains(person[0].INT_MunicipalityNumber__c)) {
                    return mapping;
                }
            }
            return null;
        }
    }
}
