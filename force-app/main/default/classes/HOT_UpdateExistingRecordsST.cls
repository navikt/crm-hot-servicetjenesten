public with sharing class HOT_UpdateExistingRecordsST implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'Select Id,INT_Municipality__c,INT_MunicipalityNumber__c FROM Person__c WHERE (INT_MunicipalityNumber__c != null OR INT_RegionNumber__c != null) AND (INT_Municipality__c = null OR INT_Region__c = null) AND INT_IsHasTombstone__c = false'
        );
    }

    public void execute(Database.BatchableContext bc, List<Person__c> records) {
        Set<String> municipalityCodes = new Set<String>();
        Set<String> regionCodes = new Set<String>();
        for (Person__c p : records) {
            municipalityCodes.add(p.INT_MunicipalityNumber__c);
            regionCodes.add(p.INT_RegionNumber__c);
        }
        List<Common_Code__c> validMunicipalityCodes = [
            SELECT Id, CRM_Code__c, CRM_Code_Set__c, Name
            FROM Common_Code__c
            WHERE CRM_Code_Set__c = 'Kommune' AND CRM_Active__c = TRUE AND CRM_Code__c IN :municipalityCodes
        ];
        List<Common_Code__c> validRegionCodes = [
            SELECT Id, CRM_Code__c, CRM_Code_Set__c, Name
            FROM Common_Code__c
            WHERE CRM_Code_Set__c = 'Fylke' AND CRM_Active__c = TRUE AND CRM_Code__c IN :regionCodesCodes
        ];
        Map<String, Id> municipalityAssociations = new Map<String, Id>();
        Map<String, Id> regionAssociations = new Map<String, Id>();
        for (Common_Code__c validMunicipalityCode : validMunicipalityCodes) {
            municipalityAssociations.put(validMunicipalityCode.CRM_Code__c, validMunicipalityCode.Id);
        }
        for (Common_Code__c validRegionCode : validRegionCodes) {
            regionAssociations.put(validRegionCode.CRM_Code__c, validRegionCode.Id);
        }
        List<Person__c> personsToUpdate = new List<Person__c>();
        for (Person__c p : records) {
            if (municipalityAssociations.containsKey(p.INT_MunicipalityNumber__c)) {
                p.INT_Municipality__c = municipalityAssociations.get(p.INT_MunicipalityNumber__c);
            } else {
                p.INT_Municipality__c = null;
            }
            if (regionAssociations.containsKey(p.INT_RegionNumber__c)) {
                p.INT_Region__c = regionAssociations.get(p.INT_RegionNumber__c);
            } else {
                p.INT_Region__c = null;
            }
        }
        update records;
    }
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}
