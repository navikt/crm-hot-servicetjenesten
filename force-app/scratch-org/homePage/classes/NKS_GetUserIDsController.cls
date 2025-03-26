public with sharing class NKS_GetUserIDsController {
    private static Map<Set<Id>, Set<Id>> cachedUserIdsFromGroups = new Map<Set<Id>, Set<Id>>();

    @invocableMethod(label='Get User IDs')
    public static List<Result> getUserIdsFromGroups(List<Id> inputGroupIds) {
        Set<Id> groupIds = new Set<Id>(inputGroupIds);

        if (cachedUserIdsFromGroups.containsKey(groupIds)) {
            return getResultList(cachedUserIdsFromGroups.get(groupIds));
        }

        Set<Id> result = new Set<Id>();
        Set<Id> nestedGroupIds = new Set<Id>();

        List<GroupMember> groupMembers = [
            SELECT UserOrGroupId
            FROM GroupMember
            WHERE GroupId IN :groupIds
        ];

        List<Id> groupMemberIds = new List<Id>();
        for (GroupMember grpMember : groupMembers) {
            groupMemberIds.add(grpMember.UserOrGroupId);
        }

        Map<Id, User> activeUsersMap = new Map<Id, User>(
            [
                SELECT Id
                FROM User
                WHERE
                    IsActive = TRUE
                    AND ProfileId IN (SELECT Id FROM Profile WHERE Name LIKE 'NAV Kontaktsenter%')
                    AND Id IN :groupMemberIds
            ]
        );

        for (GroupMember member : groupMembers) {
            if (member.UserOrGroupId.getSObjectType() == Schema.Group.SObjectType) {
                nestedGroupIds.add(member.UserOrGroupId);
            } else if (activeUsersMap.get(member.UserOrGroupId) != null) {
                result.add(member.UserOrGroupId);
            }
        }

        if (!nestedGroupIds.isEmpty()) {
            List<Result> nestedGroupIdsResult = getUserIdsFromGroups(new List<Id>(nestedGroupIds));

            for (Result res : nestedGroupIdsResult) {
                for (String userId : res.userIds) {
                    result.add((Id) userId);
                }
            }
        }

        cachedUserIdsFromGroups.put(groupIds, result);
        return getResultList(result);
    }

    public static List<Result> getResultList(Set<Id> ids) {
        List<Result> results = new List<Result>();
        Result res = new Result();
        res.userIds = new List<String>();

        for (Id id : ids) {
            res.userIds.add((String) id);
        }

        results.add(res);
        return results;
    }

    public class Result {
        @InvocableVariable(label='User IDs')
        public List<String> userIds;
    }
}
