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
    public static HOT_BilsenterMapping__mdt getBilsenter(String accountId) {
        Set<Integer> splitRegionNumbers = new Set<Integer>{ 32, 34 };

        List<Account> accounts = [
            SELECT CRM_Person__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
        if (accounts.isEmpty() || accounts[0].CRM_Person__c == null) {
            return null;
        }

        List<Person__c> persons = [
            SELECT Id, INT_MunicipalityNumber__c, INT_RegionNumber__c
            FROM Person__c
            WHERE Id = :accounts[0].CRM_Person__c
            LIMIT 1
        ];
        if (persons.isEmpty()) {
            return null;
        }
        Person__c person = persons[0];

        String fylkeStr = person.INT_RegionNumber__c;
        String kommuneStr = person.INT_MunicipalityNumber__c;

        if (String.isBlank(fylkeStr) && String.isNotBlank(kommuneStr) && kommuneStr.length() >= 2) {
            fylkeStr = kommuneStr.substring(0, 2);
        }

        if (String.isBlank(fylkeStr)) {
            return null;
        }

        Integer fylkeInt = Integer.valueOf(fylkeStr);

        List<HOT_BilsenterMapping__mdt> bilsenterMapping = [
            SELECT BilsenterNavn__c, BilsenterUrl__c, Fylkenummer__c, Kommunenummer__c
            FROM HOT_BilsenterMapping__mdt
            WHERE Fylkenummer__c = :fylkeInt
        ];
        if (bilsenterMapping.isEmpty()) {
            return null;
        }

        if (splitRegionNumbers.contains(fylkeInt)) {
            for (HOT_BilsenterMapping__mdt mapping : bilsenterMapping) {
                if (String.isNotBlank(mapping.Kommunenummer__c)) {
                    List<String> validKommuner = mapping.Kommunenummer__c.split(',');
                    if (validKommuner.contains(kommuneStr)) {
                        return mapping;
                    }
                }
            }
            return null;
        } else {
            return bilsenterMapping[0];
        }
    }
}
