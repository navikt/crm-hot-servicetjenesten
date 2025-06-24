({
    //Called when the component loads
    onInit: function (component, event, helper) {
        // Get the empApi component
        const empApi = component.find('empApi');

        // Uncomment below line to enable debug logging (optional)
        // empApi.setDebugFlag(true);

        // Register error listener and pass in the error handler function
        empApi.onError(
            $A.getCallback((error) => {
                // Error can be any type of error (subscribe, unsubscribe...)
                console.error('EMP API error: ', JSON.stringify(error));
            })
        );

        //Subscribe to empApi events
        helper.subscribeEmpApi(component);
    },

    //Handles event from LWC to init the auth process using the conversation toolkit API
    requestAuthentication: function (component, event) {
        const chatToolkit = component.find('chatToolkit');
        const recordId = component.get('v.recordId');
        const authInfoCmp = component.find('chatAuthInfo');
        let authUrl = event.getParam('authUrl');

        const action = component.get('c.generateAuthMessage');
        action.setParams({ recordId });
        action.setCallback(this, function (response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                chatToolkit
                    .sendMessage({
                        recordId: recordId,
                        message: {
                            text: response.getReturnValue() + authUrl + recordId
                        }
                    })
                    .then(function (result) {
                        //Call child to handle message result
                        authInfoCmp.authRequestHandling(result);
                    });
            } else if (state === 'INCOMPLETE') {
                // do something
            } else if (state === 'ERROR') {
                const errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log('Error message: ' + errors[0].message);
                    }
                } else {
                    console.log('Unknown error');
                }
            }
        });
        $A.enqueueAction(action);
    },

    handleAuthCompleted: function (component, event, helper) {
        helper.showLoginMsg(component, event);
    }
});
