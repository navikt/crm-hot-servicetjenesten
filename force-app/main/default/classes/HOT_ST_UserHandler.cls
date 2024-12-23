public without sharing class HOT_ST_UserHandler extends MyTriggers {
    //Skal opprettes en tjenesteressurs når bruker opprettes.
    public override void onAfterInsert() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'HOT Servicetjenesten'];

        if (profiles.size() > 0) {
            List<Id> userIds = new List<Id>();
            for (User user : (List<User>) records) {
                if (user.ProfileId == profiles[0].Id) {
                    userIds.add(user.Id);
                }
            }
            if (userIds.size() > 0) {
                HOT_ST_ServiceResourceHandler.createServiceResourceFuture(userIds);
            }
        }
    }

    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        List<Profile> servicetjenestenProfile = [SELECT Id, Name FROM Profile WHERE Name = 'HOT Servicetjenesten'];
        Set<Id> usersWithChangedProfile = new Set<Id>();

        if (!servicetjenestenProfile.isEmpty()) {
            for (User user : (List<User>) records) {
                User oldUser = (User) triggerOldMap.get(user.Id);

                if (
                    oldUser.ProfileId != servicetjenestenProfile[0].Id &&
                    user.ProfileId == servicetjenestenProfile[0].Id
                ) {
                    usersWithChangedProfile.add(user.Id);
                }
            }
        }

        if (!usersWithChangedProfile.isEmpty()) {
            HOT_ST_ServiceResourceHandler.createServiceResourceFuture(new List<Id>(usersWithChangedProfile));
        }
    }
}
