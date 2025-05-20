@isTest
private class HOT_UpdateExistingRecordSTTest {
    @isTest
    public static void BatchTest() {
        Person__c p = (Person__c) HOT_ST_TestDataFactory.createRecord(
            new Person__c(
                INT_ActorId__c = '100003000120',
                INT_Confidential__c = 'FORTROLIG',
                INT_FirstName__c = 'Harry',
                INT_IsNavEmployee__c = true,
                INT_LastName__c = 'Potter',
                INT_DistrictNumber__c = '2',
                INT_MunicipalityNumber__c = '3',
                INT_IsHasTombstone__c = false
            ),
            true
        );

        Test.startTest();
        HOT_UpdateExistingRecordsST b = new HOT_UpdateExistingRecordsST();
        ID batchprocessid = Database.executeBatch(b);
        Test.stopTest();
    }
}
