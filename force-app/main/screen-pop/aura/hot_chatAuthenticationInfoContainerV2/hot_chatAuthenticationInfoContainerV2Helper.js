({
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
    },

    showLoginMsg: function (component, event) {
        const chatToolkit = component.find('chatToolkit');
        const recordId = component.get('v.recordId');
        const loginMsg = event.getParam('loginMessage');

        if (component.get('v.authCompletedHandled')) {
            chatToolkit
                .sendMessage({
                    recordId: recordId,
                    message: {
                        text: loginMsg
                    }
                })
                .then(function () {
                    console.log('Succesfully sent login message to chat');
                })
                .catch(function (error) {
                    console.error('Error sending login message:', error);
                });
        }
    },

    setTabIcon: function (component, newTabId, iconName, iconAlt) {
        let workspace = component.find('workspace');
        workspace.setTabIcon({
            tabId: newTabId,
            icon: iconName,
            iconAlt: iconAlt
        });
    },

    subscribeEmpApi: function (component) {
        const empApi = component.find('empApi');
        const channel = '/topic/Chat_Auth_Status_Changed';
        const replayId = -1;

        empApi
            .subscribe(
                channel,
                replayId,
                $A.getCallback((eventReceived) => {
                    this.onEmpApiEvent(component, eventReceived);
                })
            )
            .then((subscription) => {
                component.set('v.subscription', subscription);
            });
    },

    unsubscribeEmpApi: function (component) {
        const empApi = component.find('empApi');
        const subscription = component.get('v.subscription');

        empApi.unsubscribe(
            subscription,
            $A.getCallback(() => {
                component.set('v.subscription', null);
            })
        );
    },

    onEmpApiEvent: function (component, eventReceived) {
        const authStatus = eventReceived.data.sobject.CRM_Authentication_Status__c;
        const changedRecordId = eventReceived.data.sobject.Id;
        const recordId = component.get('v.recordId');

        if (changedRecordId === recordId) {
            component
                .find('workspace')
                .getEnclosingTabId()
                .then((tabId) => {
                    if (authStatus === 'Completed') {
                        this.setTabIcon(component, tabId, 'utility:lock', 'Innlogget chat');
                    } else {
                        this.setTabIcon(component, tabId, 'standard:live_chat', 'Uinnlogget chat');
                    }
                });
        }
    }
});
