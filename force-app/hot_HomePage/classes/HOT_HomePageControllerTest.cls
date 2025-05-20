@isTest
private class HOT_HomePageControllerTest {
    /*@TestSetup
    static void makeData() {
        NKS_Announcement__c a = new NKS_Announcement__c();
        c.NKS_Information__c = 'test';
        c.RecordType.DeveloperName = 'test1';
        insert c;
    }*/

    @isTest
    public static void testGetField() {
        Test.startTest();
        try {
            HOT_HomePageController.getField('test1');
        } catch (AurahandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        Test.stopTest();
    }

    /*@isTest
    public static void testGetFielderr() {
        Test.startTest();
        try {
            HOT_HomePageController.getField('');
        } catch (AurahandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        Test.stopTest();
    }*/
}
