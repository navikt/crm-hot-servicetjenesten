public with sharing class HOT_ChatAfterWork {
    @AuraEnabled
    public static Id reportThreatClick() {
        try {
            ReportingData__c rData = new ReportingData__c();
            rData.CRM_Category__c = 'Chat Threat';
            insert rData;
            return rData.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateThreatClickValue(Id rDataId, Integer value) {
        try {
            ReportingData__c rData = new ReportingData__c(Id = rDataId);
            rData.CRM_Value__c = value;
            update rData;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
