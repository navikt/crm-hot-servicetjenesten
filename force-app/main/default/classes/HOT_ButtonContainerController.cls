public with sharing class HOT_ButtonContainerController {
    @AuraEnabled(cacheable=true)
    public static String getLabel(String label) {
        return System.Label.get('', label);
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getLabels(List<String> labels) {
        List<String> labelList = new List<String>();
        for (String label : labels) {
            labelList.add(getLabel(label));
        }
        return labelList;
    }

    @AuraEnabled(cacheable=true)
    public static string getCommonCodeName(String id) {
        return [SELECT Id, Name FROM Common_Code__c WHERE Id = :id]?.Name;
    }
}
