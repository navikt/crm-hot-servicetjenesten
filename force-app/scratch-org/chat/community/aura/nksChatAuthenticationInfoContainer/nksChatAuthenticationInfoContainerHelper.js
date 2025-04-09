({
    showLoginMsg: function (component, event) {
        const chatToolkit = component.find('chatToolkit');
        const recordId = component.get('v.recordId');
        const loginMsg = event.getParam('loginMessage');

        chatToolkit
            .sendMessage({
                recordId: recordId,
                message: {
                    text: loginMsg
                }
            })
            .then(function () {
                //Message success
            });
    },

    //Set icon om console tab
    setTabIcon: function (component, newTabId, iconName, iconAlt) {
        let workspace = component.find('workspace');
        workspace.setTabIcon({
            tabId: newTabId,
            icon: iconName,
            iconAlt: iconAlt
        });
    },

    // Invokes the subscribe method on the empApi component
    subscribeEmpApi: function (component) {
        // Get the empApi component
        const empApi = component.find('empApi');
        // Get the channel
        const channel = '/topic/Chat_Auth_Status_Changed';
        // Replay option to get new events
        const replayId = -1;

        // Subscribe to an event
        empApi
            .subscribe(
                channel,
                replayId,
                $A.getCallback((eventReceived) => {
                    this.onEmpApiEvent(component, eventReceived);
                })
            )
            .then((subscription) => {
                // Save subscription to unsubscribe later
                component.set('v.subscription', subscription);
            });
    },

    // Invokes the unsubscribe method on the empApi component
    unsubscribeEmpApi: function (component) {
        // Get the empApi component
        const empApi = component.find('empApi');
        // Get the subscription that we saved when subscribing
        const subscription = component.get('v.subscription');

        // Unsubscribe from event
        empApi.unsubscribe(
            subscription,
            $A.getCallback(() => {
                // Confirm that we have unsubscribed from the event channel
                component.set('v.subscription', null);
            })
        );
    },

    //When auth status changes update the tab icon
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
