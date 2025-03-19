public with sharing class HOT_ChatAuthController {
    @AuraEnabled
    public static void setStatus(Id chatTranscriptId, String status) {
        List<SObject> recordsToUpdate = new List<SObject>();

        try {
            LiveChatTranscript lct = getChatTranscript(chatTranscriptId);
            lct.CRM_Authentication_Status__c = status;
            recordsToUpdate.add(lct);

            if (status == 'Completed' && String.isBlank(lct.AccountId)) {
                handleChatAuthentication(lct);

                if (String.isNotBlank(lct.CaseId)) {
                    Case casy = new Case(Id = lct.CaseId, AccountId = lct.accountId, ContactId = lct.contactId);
                    recordsToUpdate.add(casy);
                }
            }
            update recordsToUpdate;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getTypeName() + ' : ' + 'Failed to update authentication status');
        }
    }

    private static void handleChatAuthentication(LiveChatTranscript chatTrans) {
        Id accountId = getPersonAccountId();
        Id contactId = getPersonContactId();
        chatTrans.AccountId = accountId;
        chatTrans.ContactId = contactId;
        chatTrans.NKS_Authentication_Timestamp__c = DateTime.now();
        createChatThread(chatTrans);

        if (String.isNotBlank(accountId)) {
            Account personAcc = getPersonAccount(accountId);
            if (
                !personAcc.CRM_Person__r.INT_Confidential__c.equalsIgnoreCase('UGRADERT') ||
                personAcc.CRM_Person__r.INT_IsNavEmployee__c
            )
                //Persons tagged as confidential or is NAV employees cannot be journaled - NKS-430
                chatTrans.NKS_Journal_Entry_Status__c = 'Completed';
        }
    }

    private static void createChatThread(LiveChatTranscript chatTrans) {
        Thread__c chatThread = new Thread__c(
            CRM_Thread_Type__c = 'CHAT',
            CRM_Account__c = chatTrans.AccountId,
            CRM_Contact__c = chatTrans.ContactId,
            CRM_isActive__c = true,
            CRM_Related_Object__c = chatTrans.Id,
            CRM_Theme_Group__c = chatTrans.NKS_Theme_Group__c
        );
        insert chatThread;
    }

    private static LiveChatTranscript getChatTranscript(Id chatTranscriptId) {
        return [SELECT Id, CaseId, AccountId, NKS_Theme_Group__c FROM LiveChatTranscript WHERE Id = :chatTranscriptId];
    }

    @AuraEnabled
    public static string getCommunityAuthUrl() {
        List<Network> community = [SELECT Id FROM Network WHERE Name = 'nks'];
        String communityUrl = community.isEmpty() ? '' : Network.getLoginUrl(community[0].Id);
        communityUrl = communityUrl.removeEnd(communityUrl.substringAfterLast('/'));
        communityUrl += 's/identity-verified?ctid=';

        return communityUrl;
    }

    @AuraEnabled(Cacheable=true)
    public static Map<String, String> getChatInfo(String chatTranscriptId) {
        Map<String, String> chatInfo;
        try {
            LiveChatTranscript trans = [
                SELECT
                    Id,
                    CRM_Authentication_Status__c,
                    AccountId,
                    Account.CRM_Person__c,
                    Account.CRM_Person__r.INT_Confidential__c,
                    Account.CRM_Person__r.INT_IsNavEmployee__c,
                    CaseId,
                    LiveChatButton.WindowLanguage,
                    Status,
                    EndTime
                FROM LiveChatTranscript
                WHERE Id = :chatTranscriptId
            ];
            chatInfo = new Map<String, String>{
                'AUTH_STATUS' => trans.CRM_Authentication_Status__c,
                'CONVERSATION_STATUS' => trans.Status,
                'ACCOUNTID' => trans.accountId,
                'CASEID' => trans.CaseId,
                'PERSONID' => trans.Account.CRM_Person__c,
                'IS_NAV_EMPLOYEE' => isNavEmployee(trans),
                'IS_CONFIDENTIAL' => '' + personIsConfidential(trans),
                //'NMB_SECURITY_MEASURES' => numberOfSecurityMeasures(trans),
                'CHAT_LANGUAGE' => String.isNotBlank(trans.LiveChatButton.WindowLanguage)
                    ? trans.LiveChatButton.WindowLanguage
                    : 'no',
                'END_TIME' => string.valueOf(trans.EndTime)
            };
            return chatInfo;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getTypeName() + ' : ' + 'Could not retrieve authentication status');
        }
    }

    private static String personIsConfidential(LiveChatTranscript trans) {
        if (String.isNotBlank(trans.AccountId)) {
            return trans.Account.CRM_Person__r.INT_Confidential__c.equalsIgnoreCase('UGRADERT') ? 'false' : 'true';
        }
        return 'false';
    }

    private static String isNavEmployee(LiveChatTranscript trans) {
        if (String.isNotBlank(trans.AccountId)) {
            return trans.Account.CRM_Person__r.INT_IsNavEmployee__c ? 'true' : 'false';
        }
        return 'false';
    }

    // private static String numberOfSecurityMeasures(LiveChatTranscript trans) {
    //     if (String.isNotBlank(trans.AccountId)) {
    //         return '' + trans.Account.CRM_Person__r.NKS_NumberOfSecurityMeasures__c;
    //     }

    //     return '0';
    // }

    @AuraEnabled
    public static void setStatusRequested(Id chatTranscriptId) {
        setStatus(chatTranscriptId, 'Authentication Requested');
    }

    @AuraEnabled
    public static void setStatusCompleted(Id chatTranscriptId) {
        setStatus(chatTranscriptId, 'Completed');
    }

    private static Id getPersonAccountId() {
        return [
            SELECT AccountId
            FROM User
            WHERE
                IsPortalEnabled = TRUE
                AND Id = :UserInfo.getUserId()
                AND AccountId != NULL
                AND Account.IsPersonAccount = TRUE
        ]
        ?.AccountId;
    }

    private static Account getPersonAccount(String accountId) {
        return [
            SELECT Id, CRM_Person__c, CRM_Person__r.INT_Confidential__c, CRM_Person__r.INT_IsNavEmployee__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
    }

    private static Id getPersonContactId() {
        return [
            SELECT ContactId
            FROM User
            WHERE
                IsPortalEnabled = TRUE
                AND Id = :UserInfo.getUserId()
                AND ContactId != NULL
                AND Account.IsPersonAccount = TRUE
        ]
        ?.ContactId;
    }

    @AuraEnabled
    public static string getCounselorName(String recordId) {
        Id ownerId = [SELECT OwnerId FROM LiveChatTranscript WHERE Id = :recordId LIMIT 1]?.OwnerId;
        String fullname = [SELECT NKS_FullName__c FROM User WHERE Id = :ownerId LIMIT 1]?.NKS_FullName__c;
        return fullname;
    }
}
