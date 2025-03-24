global class HOT_CaseBotConversationHandler extends MyTriggers {
    global override void onBeforeUpdate(Map<Id, sObject> triggerOldMap) {
        for (Case casy : (List<Case>) Trigger.new) {
            Id sourceId = casy.sourceId;
            if (
                sourceId != null &&
                sourceId.getSobjectType().getDescribe().getName() == 'LiveChatTranscript' &&
                String.isBlank(casy.NKS_Conversation__c) &&
                String.isNotBlank(casy.Description)
            ) {
                handleBotConversation(casy);
            }
        }
    }

    private void handleBotConversation(Case casy) {
        //Formats the conversation and stores in the NKS_Conversation__c field
        String formattedConversation = formatBotConversation(casy.Description);
        casy.NKS_Conversation__c = formattedConversation;
        casy.NKS_Conversation_Stored__c = true;
    }

    /**
     * @description: Formats a a given bot conversation string
     * @author Stian Ruud Schikora | 10-30-2020
     * @param botConversation
     * @return String
     **/
    public static String formatBotConversation(String botConversation) {
        String returnText = '';
        String message;

        //For long conversations string.split() has a chance to encounter regex exceptions. Using custom iterator instead
        BotConversation_Iterator conversationIterator = new BotConversation_Iterator(botConversation);
        while (conversationIterator.hasNext()) {
            message = '<p>' + conversationIterator.next().replaceAll('\r', '<br>').replaceAll('\n', '') + '</p>';
            if (!conversationIterator.hasNext()) {
                message = '<br>' + message;
            }
            returnText += message;
        }

        return returnText;
    }

    private class BotConversation_Iterator implements Iterator<String> {
        private String conversation;
        private Integer messageIndex;
        private String message_rowDelimiter = '\r\n';

        public BotConversation_Iterator(String fileData) {
            conversation = fileData;
            messageIndex = fileData.length();
        }

        public Boolean hasNext() {
            return messageIndex >= 0;
        }

        public String next() {
            Integer key = conversation.lastIndexOf(message_rowDelimiter, messageIndex);
            if (key == -1)
                key = 0;

            String row = messageIndex == this.conversation.length()
                ? conversation.subString(key, messageIndex)
                : conversation.subString(key, messageIndex + 1);
            messageIndex = key - 1;
            return row;
        }
    }
}