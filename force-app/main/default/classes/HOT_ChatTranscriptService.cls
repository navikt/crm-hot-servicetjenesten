global class HOT_ChatTranscriptService {
    @TestVisible
    private static Map<String, String> authTexts = new Map<String, String>{
        'norwegian' => 'Trykk for å logge inn på nav.no og gi veilederen tilgang til saken din. ',
        'english' => 'Click to log in to nav.no and grant your advisor access to your case. '
    };

    //INITIATE INTERNAL MAP OF NAV IDENT --> User ID
    @testVisible
    private static Map<String, User> navIdentUserMap {
        get {
            if (navIdentUserMap == null) {
                navIdentUserMap = new Map<String, User>();
                for (User usr : [
                    SELECT Id, CRM_NAV_Ident__c, Department
                    FROM User
                    WHERE
                        Id IN (
                            SELECT AssigneeId
                            FROM PermissionSetAssignment
                            WHERE PermissionSetGroup.DeveloperName = 'HOT_Servicetjenesten_Gruppe'
                        )
                        AND IsActive = TRUE
                        AND CRM_NAV_Ident__c != NULL
                        AND CRM_NAV_Ident__c != ''
                ]) {
                    navIdentUserMap.put(usr.CRM_NAV_Ident__c, usr);
                }
            }
            return navIdentUserMap;
        }
        private set {
        }
    }

    private static LoggerUtility logger = new LoggerUtility('Chat');
    /**
     * @description: Handles storing the chat conversation directly to solve issue
     * with omni channel delayed transcript body generation
     * @author Stian Ruud Schikora | 10-27-2020
     * @param chatId
     * @param jsonConversation
     **/
    @AuraEnabled
    public static void storeConversation(String chatId, String jsonConversation) {
        LiveChatTranscript chatTranscript = getChatDetails(chatId);
        Thread__c chatThread;
        if (chatTranscript.NKS_Authentication_Timestamp__c == null) {
            return;
        } else {
            chatThread = getThreadDetails(chatId);
        }
        List<Message> messageList = (List<Message>) JSON.deserialize(jsonConversation, List<Message>.class);
        messageList.sort();
        if (
            (chatThread.CRM_Latest_Message_Datetime__c ==
            Datetime.newInstance(Long.valueOf(messageList[messageList.size() - 1].timestamp)))
        ) {
            //Compare last message timestamp from thread to handle issues with multiple EndEvents
            return;
        }
        List<Message__c> threadMessages = new List<Message__c>();

        try {
            threadMessages = converToThreadMessages(messageList, chatTranscript, chatThread);
            List<Message__c> existingMessages = getExistingMessages(chatThread.Id);
            if (threadMessages.size() > 0)
                insert threadMessages;
            if (existingMessages.size() > 0) {
                try {
                    //Deleting the existing messages as the Chat API does not return consistent timestamps making it difficult to match if the message is already inserted or not
                    delete existingMessages;
                } catch (Exception ex) {
                    //Pokémon catch
                    logger.exception(ex, chatThread, CRM_ApplicationDomain.Domain.HOT);
                }
            }
            updateThreadClosedate(chatThread.Id, System.now());
        } catch (Exception ex) {
            logger.exception(ex, CRM_ApplicationDomain.Domain.HOT);
        } finally {
            logger.publish();
        }
    }

    /**
     * @description: Handles conversion of a list of message wrappers into thread messages.
     * @author Stian Ruud Schikora | 02-09-2022
     * @param wrapperMessages
     * @param chatTrans
     * @return List<Message__c>
     **/
    private static List<Message__c> converToThreadMessages(
        List<Message> wrapperMessages,
        LiveChatTranscript chatTrans,
        Thread__c chatThread
    ) {
        List<Message__c> returnMessages = new List<Message__c>();
        returnMessages.add(createAuthEventMessage(chatTrans, chatThread));

        for (Integer i = wrapperMessages.size() - 1; i >= 0; i--) {
            //Adding language attribute to the message
            wrapperMessages[i].language = chatTrans.LiveChatButton?.WindowLanguage;
            //As message list is sorted we only add messages that does not already exist and stop when we hit an existing entry
            returnMessages.add(convertToThreadMessage(wrapperMessages[i], chatThread));
        }

        return returnMessages;
    }

    /**
     * @description: Returns all messages on a given thread
     * @author Stian Ruud Schikora | 02-09-2022
     * @param threadId
     * @return List<Message__c>
     **/
    private static List<Message__c> getExistingMessages(String threadId) {
        return [SELECT Id FROM Message__c WHERE CRM_Thread__c = :threadId ORDER BY CRM_Sent_date__c DESC];
    }

    /**
     * @description: Updating the thread close date. In future context to prevent issue with i.e. record lock when inserting new messages
     * @author Stian Ruud Schikora | 02-09-2022
     * @param threadId
     * @param closeDate
     **/
    @future
    private static void updateThreadClosedate(String threadId, Datetime closeDate) {
        update new Thread__c(Id = threadId, CRM_isActive__c = false, CRM_Closed_Date__c = closeDate);
    }

    /**
     * @description: Creates a message of type event to properly display the authentication event in the thread.
     * @author Stian Ruud Schikora | 02-09-2022
     * @param chatTrans
     * @return Message__c
     **/
    private static Message__c createAuthEventMessage(LiveChatTranscript chatTrans, Thread__c chatThread) {
        String authText = chatTrans.LiveChatButton?.WindowLanguage == 'en_US'
            ? 'Started authenticated chat'
            : 'Startet innlogget chat';
        return new Message__c(
            CRM_Thread__c = chatThread.Id,
            CRM_Type__c = 'Event',
            CRM_Sent_date__c = chatTrans.NKS_Authentication_Timestamp__c,
            CRM_Read__c = false,
            CRM_Message_Text__c = authText
        );
    }

    /**
     * @description: Converts a message wrapper from the LiveAgent API to a Message__c record
     * @author Stian Ruud Schikora | 01-31-2022
     * @param wrapperMessages
     * @param chatTrans
     * @return List<Message__c>
     **/
    private static Message__c convertToThreadMessage(Message wrapperMessage, Thread__c chatThread) {
        Message__c convertedMessage = new Message__c();
        convertedMessage.CRM_Thread__c = chatThread.Id;
        convertedMessage.CRM_Type__c = wrapperMessage.getThreadMessageType();
        convertedMessage.CRM_Message_Text__c = wrapperMessage.getThreadMessageType() == 'Event'
            ? wrapperMessage.getTransfertext()
            : wrapperMessage.content;
        convertedMessage.CRM_Sent_date__c = DateTime.newInstance(Long.valueOf(wrapperMessage.timestamp));
        convertedMessage.CRM_Read__c = false;
        if (wrapperMessage.isAgentMessage()) {
            //Agent name is designed to include the NAV ident in parenthesis i.e. (<NAV_IDENT>)
            String navIdent = wrapperMessage.name.substringBetween('(', ')');
            if (!navIdentUserMap.containsKey(navIdent)) {
                logger.error('Could not find user record for agent', chatThread, CRM_ApplicationDomain.Domain.HOT);
            } else {
                convertedMessage.CRM_From_User__c = navIdentUserMap.get(navIdent).Id;
                convertedMessage.CRM_From_NAV_Unit__c = navIdentUserMap.get(navIdent).Department;
            }
        } else {
            convertedMessage.CRM_From_Contact__c = chatThread.CRM_Contact__c;
        }

        return convertedMessage;
    }

    private static LiveChatTranscript getChatDetails(String chatId) {
        return [
            SELECT
                AccountId,
                ContactId,
                NKS_Agent_Greeting_Name__c,
                Body,
                NKS_Conversation__c,
                CaseId,
                Case.NKS_Conversation_Stored__c,
                Case.Description,
                NKS_Authentication_Timestamp__c,
                LiveChatButton.WindowLanguage,
                NKS_Conversation_Stored__c
            FROM LiveChatTranscript
            WHERE Id = :chatId
            FOR UPDATE
        ];
    }

    private static Thread__c getThreadDetails(String chatId) {
        Id convertedId = (Id) chatId;
        return [
            SELECT Id, CRM_Account__c, CRM_Contact__c, CRM_Latest_Message_Datetime__c, CRM_Related_Object__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :convertedId
            FOR UPDATE
        ];
    }

    @AuraEnabled
    public static LiveChatTranscript getChatTranscript(Id recordId) {
        try {
            return [
                SELECT
                    Name,
                    LiveChatButtonId,
                    LiveChatButton.MasterLabel,
                    Case.CaseNumber,
                    CRM_Authentication_Status__c,
                    Status
                FROM LiveChatTranscript
                WHERE Id = :recordId
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    global class Message implements Comparable {
        private String content;
        public String name;
        private String recordId;
        @Testvisible
        private String timestamp;
        @Testvisible
        private String type;
        public String language;

        global Integer compareTo(Object compareTo) {
            Message curMessage = (Message) compareTo;
            Long thisTimestamp = Long.valueOf(timestamp);
            Long curTimestamp = Long.valueOf(curMessage.timestamp);

            if (thisTimestamp < curTimestamp) {
                return -1;
            }
            if (thisTimestamp > curTimestamp) {
                return 1;
            }
            return 0;
        }

        public String getTransfertext() {
            String transferText = language == 'en_US' ? 'Transferred to {to}' : 'Overført til {to}';
            transferText = transferText.replace('{to}', this.name);

            return transferText;
        }

        /**
         * @description: Method to translate the live agent message type to the Message__c types
         * @author Stian Ruud Schikora | 01-31-2022
         * @return String
         **/
        public String getThreadMessageType() {
            return type.equalsIgnoreCase('OperatorTransferred') ? 'Event' : 'Message';
        }
        @TestVisible
        private boolean isAgentMessage() {
            return type.equalsIgnoreCase('agent');
        }
    }

    @AuraEnabled
    public static string generateAuthMessage(Id recordId) {
        try {
            return [SELECT Id, LiveChatButton.WindowLanguage FROM LiveChatTranscript WHERE id = :recordId LIMIT 1]
                    ?.LiveChatButton
                    ?.WindowLanguage == 'en_US'
                ? authTexts.get('english')
                : authTexts.get('norwegian');
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
