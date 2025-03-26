public with sharing class NKS_CustomNotificationController {
    private static LoggerUtility logger = new LoggerUtility();
    private static Integer max = 500;

    @invocableMethod(label='Send Notification')
    public static void sendNotification(List<Request> requests) {
        for (Request request : requests) {
            if (request.userIds != null && !request.userIds.isEmpty()) {
                Set<Id> userIds = new Set<Id>(request.userIds);

                // Convert Set to List for indexing
                List<Id> userIdList = new List<Id>(userIds);

                // Check if the size exceeds limit'
                Integer localLimit = Test.isRunningTest() ? 50 : max;
                if (userIdList.size() > localLimit) {
                    List<Set<Id>> res = new List<Set<Id>>();

                    // Split List of Ids into smaller sets based on the limit
                    for (Integer i = 0; i < (userIdList.size() / localLimit) + 1; i++) {
                        Set<Id> tempList = new Set<Id>();
                        for (Integer j = i * localLimit; j < (i + 1) * localLimit && j < userIdList.size(); j++) {
                            tempList.add(userIdList[j]);
                        }
                        res.add(tempList);
                    }

                    for (Set<Id> ids : res) {
                        sendNotificationToUsers(
                            ids,
                            request.notificationTypeId,
                            request.notificationTitle,
                            request.notificationBody,
                            request.targetId,
                            request.pageRef
                        );
                    }
                } else {
                    sendNotificationToUsers(
                        userIds,
                        request.notificationTypeId,
                        request.notificationTitle,
                        request.notificationBody,
                        request.targetId,
                        request.pageRef
                    );
                }
            }
        }
    }

    private static void sendNotificationToUsers(
        Set<Id> userIds,
        String notificationTypeId,
        String notificationTitle,
        String notificationBody,
        Id targetId,
        String pageRef
    ) {
        Set<String> recipientIds = new Set<String>();
        for (Id id : userIds) {
            recipientIds.add(id.toString());
        }

        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setNotificationTypeId(notificationTypeId);
        notification.setTitle(notificationTitle);
        notification.setBody(notificationBody);
        notification.setTargetId(targetId);
        notification.setTargetPageRef(pageRef);

        try {
            notification.send(recipientIds);
        } catch (Exception ex) {
            logger.error(
                'Failed to send notification to users: ' + ex.getMessage(),
                null,
                CRM_ApplicationDomain.Domain.NKS
            );
            logger.publish();
        }
    }

    public class Request {
        @InvocableVariable(required=true)
        public List<Id> userIds;

        @InvocableVariable(required=true)
        public String notificationTypeId;

        @InvocableVariable(required=true)
        public String notificationTitle;

        @InvocableVariable(required=true)
        public String notificationBody;

        @InvocableVariable
        public Id targetId;

        @InvocableVariable
        public String pageRef;
    }
}
