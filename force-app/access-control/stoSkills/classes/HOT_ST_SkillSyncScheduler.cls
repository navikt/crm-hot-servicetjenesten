public with sharing class HOT_ST_SkillSyncScheduler implements Schedulable {
    LoggerUtility logger = new LoggerUtility('Servicetjenesten');
    public void execute(SchedulableContext context) {
        try {
            Callable syncService = (Callable) Type.forName('STO_GroupMemberSkillService').newInstance();
            syncService.call(
                'handleGroupAndSkillSync',
                new Map<String, Object>{
                    'domain' => 'HOT',
                    'subdomain' => 'Servicetjenesten',
                    'permsetgroup' => 'HOT_Servicetjenesten_Gruppe',
                    'fortroliggroup' => 'group_AD_Fortrolig_Adresse',
                    'skjermedegroup' => 'Skjermede_Personer_AD',
                    'resourcetype' => 'T'
                }
            );
        } catch (Exception e) {
            logger.Exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
        }
    }
}
