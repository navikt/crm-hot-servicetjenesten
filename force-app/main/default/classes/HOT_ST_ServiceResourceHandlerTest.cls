@IsTest
public class HOT_ST_ServiceResourceHandlerTest {
    @testSetup
    static void setup() {
        Profile adminProfile = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
        ];
        UserRole role = [SELECT Id FROM UserRole WHERE Name = 'Default' LIMIT 1];
        User admin = HOT_ST_TestDataFactory.createUser('admin', adminProfile);
        admin.UserRoleId = role.Id;
        admin.Department = '4718';
        insert admin;
    }
    @IsTest
    static void CreateServiceResourceAutoTest() {
        Test.startTest();
        User officeUser = [
            SELECT Id, Department, LastName, UserRoleId, MiddleName, FirstName
            FROM User
            WHERE Department = '4718' AND LastName = 'admin'
            ];
            System.runAs(officeUser) {
                HOT_ST_ServiceResourceHandler.createServiceResourceFuture(new List<Id>{officeUser.Id});
            }
            
            Test.stopTest();
        List<ServiceResource> serviceResources = [SELECT Id FROM ServiceResource];
        System.assertEquals(1, serviceResources.size());
    }
}
