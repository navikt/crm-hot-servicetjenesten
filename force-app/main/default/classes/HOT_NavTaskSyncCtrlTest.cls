@isTest
public class HOT_NavTaskSyncCtrlTest {
    @isTest
    static void testSyncOpenAndAssigned() {
        ApiMock.setTestMock('GET_OPPGAVE', 200, 'OK');

        Test.startTest();
        HOT_NavTaskSyncCtrl.syncOpenAndAssigned();
        Test.stopTest();
    }
}
