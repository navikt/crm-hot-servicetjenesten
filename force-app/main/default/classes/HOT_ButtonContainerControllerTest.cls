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
}
