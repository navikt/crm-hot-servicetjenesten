({
    handleChatEnded: function (component, event, helper) {
        var type = event.getParam('type');
        if (type === 'startTimer') {
            var recordId = component.get('v.recordId');
            var eventRecordId = event.getParam('recordId');
            if (recordId === eventRecordId) {
                helper.startTimer(component, eventRecordId);
            }
        }
    },

    stopTimer: function (component) {
        component.set('v.stopped', true);
        var action = component.get('c.reportThreatClick');
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var reportingId = response.getReturnValue();
                var appEvent = $A.get('e.c:hot_afterworkEvent');
                const recordId = component.get('v.recordId');
                appEvent.setParams({ reportingId: reportingId });
                appEvent.setParams({ recordId: recordId });
                appEvent.setParams({ type: 'createdThreatReport' });
                appEvent.fire();

                // You would typically fire a event here to trigger
                // client-side notification that the server-side
                // action is complete
            } else if (state === 'INCOMPLETE') {
                // do something
            } else if (state === 'ERROR') {
                var errors = response.getError();
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
    }
});
