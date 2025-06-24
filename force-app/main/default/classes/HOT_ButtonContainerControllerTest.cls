@IsTest
public with sharing class HOT_ButtonContainerControllerTest {
    @TestSetup
    static void makeData() {
        Common_Code__c commonCode = new Common_Code__c(Name = 'Oslo', CRM_Code_Set__c = 'Fylke', CRM_Code__c = '03');
        insert commonCode;
    }
    @IsTest
    static void testGetCommonCodeName() {
        Common_Code__c commonCode = [SELECT Id FROM Common_Code__c LIMIT 1];

        Test.startTest();
        String result = HOT_ButtonContainerController.getCommonCodeName(commonCode.Id);
        Test.stopTest();

        Assert.areEqual('Oslo', result, 'The name should match the inserted Common_Code__c record');
    }
    @IsTest
    static void testGetLabel() {
        Test.startTest();
        String testLabel = HOT_ButtonContainerController.getLabel('HOT_Create_NAV_Task');
        Test.stopTest();
        Assert.areEqual('Opprett oppgave', testLabel);
    }
    @IsTest
    static void testGetLabels() {
        List<String> labelList = new List<String>{ 'HOT_Create_NAV_Task', 'HOT_Journal' };
        Test.startTest();
        List<String> testLabels = HOT_ButtonContainerController.getLabels(labelList);
        Test.stopTest();
        Assert.areEqual(2, testLabels.size());
    }
}
