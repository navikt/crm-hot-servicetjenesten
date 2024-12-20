global class HOT_ST_ThreadPersonAccessHandler extends MyTriggers {
    private static final List<String> threadTypesOfInterest = new List<String>{ 'STO', 'STB', 'BTO' };

    /**
     * @description trigger to add thread shares on change of restrictions field
     * should be fired after NKS trigger, wich deletes all old shares
     * @param triggerOldMap `Map<Id, sObject>`
     */
    global override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        List<String> fieldNamesToCheck = new List<String>{
            'INT_Confidential__c',
            'INT_IsNavEmployee__c',
            'CRM_ManuallyRecalculatedSharing__c'
        };
        Set<Id> personIdsWithNewSharing = new Set<Id>();

        for (Person__c person : (List<Person__c>) records) {
            Person__c oldRecord = (Person__c) triggerOldMap.get(person.Id);
            if (MyTriggers.hasChangedFields(fieldNamesToCheck, person, oldRecord)) {
                personIdsWithNewSharing.add(person.Id);
            }
        }

        List<Thread__c> threads = getThreadsFromPersonIds(personIdsWithNewSharing);
        Set<Id> threadIds = new Set<Id>();
        for (Thread__c thread : threads) {
            threadIds.add(thread.Id);
        }

        if (personIdsWithNewSharing.size() > 0) {
            new HOT_ST_ThreadAccessService().grantAccess(threads, records);
        }
    }

    private List<Thread__c> getThreadsFromPersonIds(Set<Id> personIds) {
        return [
            SELECT
                Id,
                CRM_Account__c,
                CRM_Henvendelse_BehandlingsId__c,
                CRM_Office_Restriction__c,
                CRM_Theme_Code__c,
                STO_Category__c
            FROM Thread__c
            WHERE CRM_Account__r.CRM_Person__c IN :personIds AND CRM_Thread_Type__c IN :threadTypesOfInterest
        ];
    }
}
