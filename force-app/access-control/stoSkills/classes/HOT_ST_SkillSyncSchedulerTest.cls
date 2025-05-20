@isTest
private class HOT_ST_SkillSyncSchedulerTest {
    @isTest
    public static void testExecute() {
        Test.startTest();
        HOT_ST_SkillSyncScheduler job = new HOT_ST_SkillSyncScheduler();
        String cronExpr = '0 0 0 1 1 ?';
        String jobId = System.schedule('HOT_ST_SkillSyncSchedulerTest', cronExpr, job);
        Test.stopTest();

        CronTrigger cronTrigger = [
            SELECT CronExpression, State, TimesTriggered, NextFireTime
            FROM CronTrigger
            WHERE Id = :jobId
        ];

        System.assertEquals(cronExpr, cronTrigger.CronExpression, 'Cron expression should match');
        System.assertEquals('WAITING', cronTrigger.State, 'Job should be in waiting state');

        System.assert(
            1 ==
            [
                SELECT COUNT()
                FROM Application_Log__c
                WHERE Source_Class__c = :HOT_ST_SkillSyncScheduler.class.getName()
            ],
            'Expected error log in scratchOrg'
        );
    }
}
