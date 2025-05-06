public without sharing class HOT_ST_ThreadSharingEventHandler extends RecordSharingEvent {
    private static LoggerUtility logger = new LoggerUtility('HOT ST STO');
    List<Id> recordIds = new List<Id>();

    public override void execute(List<RecordSharingEvent__e> recordSharingEvents) {
        try {
            for (RecordSharingEvent__e sharingEvent : recordSharingEvents) {
                if (sharingEvent.ObjectType__c != 'HOT_ST_Thread__c') {
                    continue;
                }
                recordIds.add(sharingEvent.RecordId__c);
            }

            List<Thread__c> threads = [
                SELECT
                    Id,
                    CRM_Account__c,
                    CRM_Henvendelse_BehandlingsId__c,
                    CRM_Office_Restriction__c,
                    CRM_Theme_Code__c,
                    CRM_Theme_Group_Name__c,
                    CRM_Thread_Type__c,
                    STO_Category__c
                FROM Thread__c
                WHERE Id IN :recordIds
            ];
            if (threads.size() > 0) {
                new HOT_ST_ThreadAccessHandler().grantAccessToNewThreads(threads);
            } else {
                logger.critical(
                    'Recieved Record Sharing event but found no Threads: \n' + String.join(recordIds, ', '),
                    null,
                    CRM_ApplicationDomain.Domain.HOT
                );
            }
        } catch (Exception ex) {
            String recordIdsString = String.join(recordIds, ', ');
            logger.error(
                'Failed to share records: ' +
                    recordIdsString +
                    '\n' +
                    ex.getMessage() +
                    '\n' +
                    ex.getStackTraceString(),
                null,
                CRM_ApplicationDomain.Domain.HOT,
                null
            );
        } finally {
            logger.publish();
        }
    }
}
