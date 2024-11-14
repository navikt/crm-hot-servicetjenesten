public with sharing class HOT_UpdateExistingRecordsST implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'Select Id,INT_Municipality__c,INT_MunicipalityNumber__c FROM Person__c WHERE INT_MunicipalityNumber__c != null'
        );
    }

    public void execute(Database.BatchableContext bc, List<Person__c> records) {
        Set<String> municipalityCodes = new Set<String>();
        for (Person__c p : records) {
            municipalityCodes.add(p.INT_MunicipalityNumber__c);
        }
        List<Common_Code__c> validMunicipalityCodes = [
            SELECT Id, CRM_Code__c, CRM_Code_Set__c, Name
            FROM Common_Code__c
            WHERE CRM_Code_Set__c = 'Kommune' AND CRM_Active__c = TRUE AND CRM_Code__c IN :municipalityCodes
        ];
        Map<String, Id> municipalityAssociations = new Map<String, Id>();
        for (Common_Code__c validMunicipalityCode : validMunicipalityCodes) {
            municipalityAssociations.put(validMunicipalityCode.CRM_Code__c, validMunicipalityCode.Id);
        }
        List<Person__c> personsToUpdate = new List<Person__c>();
        for (Person__c p : records) {
            if (municipalityAssociations.containsKey(p.INT_MunicipalityNumber__c)) {
                p.INT_Municipality__c = municipalityAssociations.get(p.INT_MunicipalityNumber__c);
            } else {
                p.INT_Municipality__c = null;
            }
        }
    }
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}
