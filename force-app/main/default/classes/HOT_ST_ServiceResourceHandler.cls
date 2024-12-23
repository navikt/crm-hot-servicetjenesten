public without sharing class HOT_ST_ServiceResourceHandler {
    //Metode som lager tjenesteressurs på brukere som ikke har noe fra før, og setter på nødvendige skills for Servicetjenesten
    @Future
    public static void createServiceResourceFuture(List<Id> userIds) {
        List<User> users = [
            SELECT Id, Name, FirstName, MiddleName, LastName, ProfileId, Department
            FROM User
            WHERE Id IN :userIds
        ];
        createServiceResource(users);
    }

    public static List<Skill> getSkills() {
        List<Skill> skills = [
            SELECT Id, MasterLabel
            FROM Skill
            WHERE MasterLabel = 'STO' OR MasterLabel = 'Hjelpemidler' OR MasterLabel = 'BTO'
        ];
        return skills;
    }

    //Oppretter Tjenesteressurser
    public static void createServiceResource(List<User> users) {
        users = removeUsersWithServiceResource(users);

        List<ServiceResource> serviceResources = new List<ServiceResource>();
        for (User user : users) {
            ServiceResource serviceResource = new ServiceResource();
            serviceResource.RelatedRecordId = Test.isRunningTest() ? UserInfo.getUserId() : user.Id;
            serviceResource.Name = user.MiddleName != null
                ? (user.Firstname + ' ' + user.MiddleName + ' ' + user.LastName)
                : (user.Firstname + ' ' + user.LastName);
            serviceResource.ResourceType = 'T';
            serviceResource.IsActive = true;
            serviceResource.CRM_Domain__c = 'HOT';
            serviceResource.CRM_Subdomain__c = 'Servicetjenesten';

            serviceResources.add(serviceResource);
        }
        insert serviceResources;

        Datetime startDate = Datetime.valueOf('2024-01-01 00:00:00');

        List<Skill> skills = getSkills();
        List<ServiceResourceSkill> serviceResourceSkills = new List<ServiceResourceSkill>();
        for (ServiceResource serviceResource : serviceResources) {
            for (Skill skill : skills) {
                ServiceResourceSkill serviceResourceSkill = new ServiceResourceSkill(
                    ServiceResourceId = serviceResource.Id,
                    SkillId = skill.Id,
                    EffectiveStartDate = startDate
                );
                serviceResourceSkills.add(serviceResourceSkill);
            }
        }
        insert serviceResourceSkills;
    }

    //Filtrerer ut brukere som allerede har en Tjenesteressurs koblet til dem
    static List<User> removeUsersWithServiceResource(List<User> users) {
        List<User> filteredUsers = new List<User>();
        List<Id> userIds = new List<Id>();
        for (User user : users) {
            userIds.add(user.Id);
        }

        List<Id> userIdsWithExistingServiceResources = new List<Id>();
        for (ServiceResource serviceResource : [
            SELECT RelatedRecordId
            FROM ServiceResource
            WHERE RelatedRecordId IN :userIds
        ]) {
            userIdsWithExistingServiceResources.add(serviceResource.RelatedRecordId);
        }

        for (User user : users) {
            if (!userIdsWithExistingServiceResources.contains(user.Id)) {
                filteredUsers.add(user);
            }
        }
        return filteredUsers;
    }
}
