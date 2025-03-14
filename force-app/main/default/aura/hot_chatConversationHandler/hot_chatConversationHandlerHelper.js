({
    callStoreConversation: function (component, conversation, recordId) {
        let storeAction = component.get('c.storeConversation');

        storeAction.setParams({
            chatId: recordId,
            jsonConversation: JSON.stringify(conversation)
        });

        storeAction.setCallback(this, function (response) {
            let state = response.getState();
            if (state === 'SUCCESS') {
                //Conversation stored successfully
            } else {
                //Error handling
            }
        });

        $A.enqueueAction(storeAction);
    },

    setTabLabelAndIcon: function (component, tabId, recordId) {
        var workspace = component.find('workspace');
        var action = component.get('c.getChatTranscript');

        action.setParams({ recordId: recordId });
        action.setCallback(this, function (data) {
            if (data.getReturnValue()) {
                //Set icon based on auth status
                if (data.getReturnValue().CRM_Authentication_Status__c === 'Completed') {
                    this.setTabIcon(workspace, tabId, 'utility:lock', 'Innlogget chat');
                } else {
                    this.setTabIcon(workspace, tabId, 'standard:live_chat', 'Uinnlogget chat');
                }

                //Set tab label
                if (data.getReturnValue().LiveChatButton && data.getReturnValue().LiveChatButton.MasterLabel) {
                    let label = data.getReturnValue().LiveChatButton.MasterLabel.replace('_', ' ');
                    let caseNumber = '';
                    if (data.getReturnValue().Case && data.getReturnValue().Case.CaseNumber) {
                        caseNumber = data
                            .getReturnValue()
                            .Case.CaseNumber.substring(data.getReturnValue().Case.CaseNumber.length - 2);
                    }

                    workspace.setTabLabel({
                        tabId: tabId,
                        label: `${label}${caseNumber ? ` ${caseNumber}` : ''}`
                    });
                }
                //Set tab color
                if (data.getReturnValue().Status === 'Completed') {
                    this.setTabColor(workspace, tabId, 'success');
                }
            }
        });
        $A.enqueueAction(action);
    },

    setTabIcon: function (workspace, newTabId, iconName, iconAlt) {
        workspace.setTabIcon({
            tabId: newTabId,
            icon: iconName,
            iconAlt: iconAlt
        });
    },

    setTabColor: function (workspace, tabId, state) {
        workspace.setTabHighlighted({
            tabId: tabId,
            highlighted: true,
            options: { state: state }
        });
    },

    convertId15To18: function (Id) {
        if (Id.length === 15) {
            var addon = '';
            for (var block = 0; block < 3; block++) {
                var loop = 0;
                for (var position = 0; position < 5; position++) {
                    var current = Id.charAt(block * 5 + position);
                    if (current >= 'A' && current <= 'Z') loop += 1 << position;
                }
                addon += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ012345'.charAt(loop);
            }
            return Id + addon;
        }
        return Id;
    }
});
