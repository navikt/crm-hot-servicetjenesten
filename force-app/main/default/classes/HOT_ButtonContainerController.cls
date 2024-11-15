public with sharing class HOT_ButtonContainerController {
    @AuraEnabled(cacheable=true)
    public static string getCommonCodeName(String id) {
        return [SELECT Id, Name FROM Common_Code__c WHERE Id = :id]?.Name;
    }
}
