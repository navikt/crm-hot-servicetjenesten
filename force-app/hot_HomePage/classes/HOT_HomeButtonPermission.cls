public with sharing class HOT_HomeButtonPermission {
    @AuraEnabled(cacheable=true)
    public static boolean HOT_AnnouncementPermission() {
        string userId = UserInfo.getUserId();
        string permissionId = [SELECT id FROM permissionSet WHERE Name = 'HOT_Announcement_News_Editor' LIMIT 1].id;
        if (!String.isBlank(permissionID)) {
            try {
                string assignedId = [
                    SELECT id
                    FROM permissionSetAssignment
                    WHERE assigneeId = :userId AND permissionSetId = :permissionId
                    LIMIT 1
                ]
                .id;
                if (assignedId != null) {
                    return true;
                }
            } catch (exception e) {
                //Does not have permission
            }
        }
        return false;
    }
}
