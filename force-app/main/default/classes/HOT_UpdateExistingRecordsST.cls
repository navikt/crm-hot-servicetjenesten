public with sharing class HOT_UpdateExistingRecordsST implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'Select Id,CRM_District__c, INT_DistrictNumber__c, INT_MunicipalityNumber__c, CRM_Municipality__c FROM Person__c WHERE (INT_MunicipalityNumber__c != null OR INT_DistrictNumber__c != null) AND INT_IsHasTombstone__c = false'
        );
    }

    public void execute(Database.BatchableContext bc, List<Person__c> records) {
        Set<String> municipalityCodes = new Set<String>();
        Set<String> districtCodes = new Set<String>();
        for (Person__c p : records) {
            municipalityCodes.add(p.INT_MunicipalityNumber__c);
            districtCodes.add(p.INT_DistrictNumber__c);
        }
        List<Common_Code__c> validMunicipalityCodes = [
            SELECT Id, CRM_Code__c, CRM_Code_Set__c, Name
            FROM Common_Code__c
            WHERE CRM_Code_Set__c = 'Kommune' AND CRM_Active__c = TRUE AND CRM_Code__c IN :municipalityCodes
        ];
        List<Common_Code__c> validDistrictCodes = [
            SELECT Id, CRM_Code__c, CRM_Code_Set__c, Name
            FROM Common_Code__c
            WHERE CRM_Code_Set__c = 'Bydel' AND CRM_Active__c = TRUE AND CRM_Code__c IN :districtCodes
        ];

        Map<String, Id> municipalityAssociations = new Map<String, Id>();
        Map<String, Id> districtAssociations = new Map<String, Id>();
        for (Common_Code__c validMunicipalityCode : validMunicipalityCodes) {
            municipalityAssociations.put(validMunicipalityCode.CRM_Code__c, validMunicipalityCode.Id);
        }
        for (Common_Code__c validDistrictCode : validDistrictCodes) {
            districtAssociations.put(validDistrictCode.CRM_Code__c, validDistrictCode.Id);
        }
        List<Person__c> personsToUpdate = new List<Person__c>();
        for (Person__c p : records) {
            if (municipalityAssociations.containsKey(p.INT_MunicipalityNumber__c)) {
                p.CRM_Municipality__c = municipalityAssociations.get(p.INT_MunicipalityNumber__c);
            } else {
                p.CRM_Municipality__c = null;
            }
            if (districtAssociations.containsKey(p.INT_DistrictNumber__c)) {
                p.CRM_District__c = districtAssociations.get(p.INT_DistrictNumber__c);
            } else {
                p.CRM_District__c = null;
            }
        }
        update records;
    }
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}
