public with sharing class HOT_GroupSkillSyncScheduler implements Schedulable {
    public void execute(SchedulableContext context) {
        try {
            Callable syncService = (Callable) Type.forName('STO_GroupMemberSkillService').newInstance();
            syncService.call(
                'handleGroupAndSkillSync',
                new Map<String, Object>{
                    'domain' => 'HOT',
                    'subdomain' => 'Servicetjenesten',
                    'permsetgroup' => 'HOT_Servicetjenesten_Group',
                    'fortroliggroup' => 'group_AD_Fortrolig_Adresse',
                    'skjermedegroup' => 'Skjermede_Personer_AD',
                    'resourcetype' => 'T'
                }
            );
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility('HOT_Skill_Sync');
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
        }
    }
}
