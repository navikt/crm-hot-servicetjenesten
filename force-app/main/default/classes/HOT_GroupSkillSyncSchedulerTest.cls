@isTest
private class HOT_GroupSkillSyncSchedulerTest {
    @isTest
    public static void testExecute() {
        Test.startTest();
        String cronExpr = '0 0 0 1 1 ?';
        HOT_GroupSkillSyncScheduler scheduler = new HOT_GroupSkillSyncScheduler();
        String jobId = System.schedule('HOT_GroupSkillSyncSchedulerTest', cronExpr, scheduler);
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
                WHERE Source_Class__c = :HOT_GroupSkillSyncScheduler.class.getName()
            ],
            'Expected error log in scratchOrg'
        );
    }
}
