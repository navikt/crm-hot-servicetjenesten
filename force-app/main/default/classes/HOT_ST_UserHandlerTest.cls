@IsTest
public class HOT_ST_UserHandlerTest {
    @IsTest
    static void createServicetjenestenSR() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'HOT Servicetjenesten'];
        if (profiles.size() > 0) {
            Profile profileId = profiles[0];
            User user = HOT_ST_TestDataFactory.createUser('Testing', profileId);

            Test.startTest();
            insert user;
            Test.stopTest();

            List<ServiceResource> serviceResources = [SELECT Id, Name, RelatedRecordId FROM ServiceResource];
            System.debug(serviceResources);
            System.assertEquals(1, serviceResources.size());
        }
    }
}
