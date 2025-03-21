public with sharing class NKS_GetUserSkillsController {
    @TestVisible
    private static Map<Id, Set<String>> userSkillsCache = new Map<Id, Set<String>>();

    // Used to send notification to supervisors when news is published
    // Notifies users with skills equal to Announcement skill
    @InvocableMethod(label='Get User IDs Filtered By Skill')
    public static List<Result> getUsersToNotify(List<Request> requests) {
        Set<Id> usersToNotify = new Set<Id>();

        for (Request request : requests) {
            Set<Id> userIds = new Set<Id>(request.userIds);

            if (String.isBlank(request.newsSkills)) {
                return createResultList(userIds);
            }

            Set<String> newsSkillsSet = new Set<String>(request.newsSkills.split(';'));
            usersToNotify.addAll(getUsersWithMatchingSkills(userIds, newsSkillsSet));
        }

        return createResultList(usersToNotify);
    }

    public static Set<Id> getUsersWithMatchingSkills(Set<Id> userIds, Set<String> newsSkills) {
        // Check if cached data is available
        if (userSkillsCache.isEmpty()) {
            populateUserSkillsCache(userIds);
        }

        // Filter the cached map to get the relevant user IDs
        Set<Id> matchingUserIds = new Set<Id>();
        for (Id userId : userIds) {
            Set<String> userSkills = userSkillsCache.get(userId) ?? new Set<String>();
            // If user has no skill they should have access to all news -> send notification
            if (userSkills.isEmpty() || hasMatchingNewsSkill(newsSkills, userSkills)) {
                matchingUserIds.add(userId);
            }
        }

        return matchingUserIds;
    }

    @TestVisible
    private static void populateUserSkillsCache(Set<Id> userIds) {
        Map<Id, Set<String>> userSkillsMap = new Map<Id, Set<String>>();

        for (Id userId : userIds) {
            userSkillsMap.put(userId, new Set<String>());
        }

        // Fetch users and their skills from ServiceResourceSkill (ServiceResources are used for STO/BTO)
        for (ServiceResourceSkill srSkill : [
            SELECT ServiceResource.RelatedRecordId, Skill.DeveloperName
            FROM ServiceResourceSkill
            WHERE ServiceResource.RelatedRecordId IN :userIds
        ]) {
            userSkillsMap.get(srSkill.ServiceResource.RelatedRecordId).add(srSkill.Skill.DeveloperName);
        }

        // Transform user skills to match the Group naming convention: 'NKS_Skill_<SkillName>'
        Set<String> groupSkillNames = new Set<String>();
        for (Id userId : userSkillsMap.keySet()) {
            for (String skill : userSkillsMap.get(userId)) {
                groupSkillNames.add('NKS_Skill_' + skill);
            }
        }

        Map<Id, String> groupIdToSkillMap = new Map<Id, String>();
        for (Group grp : [
            SELECT Id, DeveloperName
            FROM Group
            WHERE DeveloperName IN :groupSkillNames AND Type = 'Regular'
        ]) {
            String skillName = grp.DeveloperName.replace('NKS_Skill_', '');
            groupIdToSkillMap.put(grp.Id, skillName);
        }

        // Add all skills for all Group Memberships (Groups are used for chat)
        for (GroupMember grpMember : [
            SELECT UserOrGroupId, GroupId
            FROM GroupMember
            WHERE UserOrGroupId IN :userIds AND GroupId IN :groupIdToSkillMap.keySet()
        ]) {
            String skillName = groupIdToSkillMap.get(grpMember.GroupId);
            userSkillsMap.get(grpMember.UserOrGroupId).add(skillName);
        }

        userSkillsCache = userSkillsMap;
    }

    public static Boolean hasMatchingNewsSkill(Set<String> newsSkills, Set<String> userSkills) {
        for (String skill : newsSkills) {
            if (userSkills.contains(skill)) {
                return true;
            }
        }
        return false;
    }

    public static List<Result> createResultList(Set<Id> ids) {
        List<Result> results = new List<Result>();
        Result res = new Result();
        res.userIds = new List<String>();

        for (Id id : ids) {
            res.userIds.add((String) id);
        }

        results.add(res);
        return results;
    }

    public class Request {
        @InvocableVariable(required=true)
        public List<Id> userIds;

        @InvocableVariable
        public String newsSkills;
    }

    public class Result {
        @InvocableVariable(label='User IDs')
        public List<String> userIds;
    }
}
