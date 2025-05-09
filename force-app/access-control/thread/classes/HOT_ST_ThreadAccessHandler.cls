global class HOT_ST_ThreadAccessHandler extends MyTriggers {
    private static final List<String> THREAD_TYPES_OF_INTEREST = new List<String>{ 'STO', 'STB', 'BTO', 'CHAT' };
    private static final List<String> CATEGORY_OF_INTEREST = new List<String>{ 'Hjelpemidler' };
    /**
     * @description On update of Thread record, share it with Servicetjenesten.
     * This trigger fires after trigger from NKS, so we do not need to delete other shares
     * @param triggerOldMap `Map<Id, sObject>`
     */
    global override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        List<String> fieldNamesToCheck = new List<String>{
            'STO_Category__c',
            'CRM_Theme__c',
            'CRM_Theme_Group_Name__c'
        };
        List<Thread__c> threadsWithNewSharing = new List<Thread__c>();
        List<Id> threadIdsToRevokeSharing = new List<Id>();

        for (Thread__c thread : (List<Thread__c>) records) {
            if (!THREAD_TYPES_OF_INTEREST.contains(thread.CRM_Thread_Type__c)) {
                continue;
            }
            if (
                (CATEGORY_OF_INTEREST.contains(thread.STO_Category__c) ||
                CATEGORY_OF_INTEREST.contains(thread.CRM_Theme_Group_Name__c)) &&
                MyTriggers.hasChangedFields(fieldNamesToCheck, thread, triggerOldMap.get(thread.Id))
            ) {
                threadsWithNewSharing.add(thread);
            } else if (
                (CATEGORY_OF_INTEREST.contains(((Thread__c) triggerOldMap.get(thread.Id)).STO_Category__c) &&
                !CATEGORY_OF_INTEREST.contains(thread.STO_Category__c)) ||
                (CATEGORY_OF_INTEREST.contains(((Thread__c) triggerOldMap.get(thread.Id)).CRM_Theme_Group_Name__c) &&
                !CATEGORY_OF_INTEREST.contains(thread.CRM_Theme_Group_Name__c))
            ) {
                threadIdsToRevokeSharing.add(thread.Id);
            }
        }
        if (threadIdsToRevokeSharing.size() > 0) {
            new HOT_ST_ThreadAccessService().revokeAccess(threadIdsToRevokeSharing);
        }
        if (threadsWithNewSharing.size() > 0) {
            new HOT_ST_ThreadAccessService().grantAccess(threadsWithNewSharing, getPersons(threadsWithNewSharing));
        }
    }

    global override void onAfterInsert() {
        List<RecordSharingEvent__e> events = new List<RecordSharingEvent__e>();
        //run sharing in a platform event

        for (Thread__c thread : (List<Thread__c>) records) {
            if (
                THREAD_TYPES_OF_INTEREST.contains(thread.CRM_Thread_Type__c) &&
                (CATEGORY_OF_INTEREST.contains(thread.STO_Category__c) ||
                CATEGORY_OF_INTEREST.contains(thread.CRM_Theme_Group_Name__c))
            ) {
                RecordSharingEvent__e event = new RecordSharingEvent__e();
                event.RecordId__c = thread.Id;
                event.ObjectType__c = 'HOT_ST_Thread__c';
                events.add(event);
            }
        }

        if (events.size() > 0) {
            EventBus.publish(events);
        }
    }

    public void grantAccessToNewThreads(List<Thread__c> threads) {
        new HOT_ST_ThreadAccessService().grantAccess(threads, getPersons(threads));
    }

    private List<Person__c> getPersons(List<Thread__c> threads) {
        Set<Id> accountIds = new Set<id>();
        for (Thread__c thread : threads) {
            accountIds.add(thread.CRM_Account__c);
        }

        return [
            SELECT Id, INT_Confidential__c, INT_IsNavEmployee__c, CRM_Account__c
            FROM Person__C
            WHERE CRM_Account__c IN :accountIds
        ];
    }
}
