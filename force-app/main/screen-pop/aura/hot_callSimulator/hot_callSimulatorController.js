/* global sforce */
({
    ctiLoaded: function (component) {
        console.log('CTI LOADED!');
        component.set('v.ctiLoaded', true);
    },

    simulateCall: function (component) {
        let identifier = component.get('v.identifier');
        let session = component.get('v.session');
        let contextOverride = component.get('v.chosenContext');

        let callback = function (response) {
            console.log(JSON.stringify(response, null, 2));
        };
        sforce.opencti.screenPop({
            type: sforce.opencti.SCREENPOP_TYPE.FLOW,
            params: {
                flowDevName: 'HOT_Inbound_Call',
                flowArgs: [
                    { name: 'Search', type: 'String', value: identifier },
                    { name: 'SessionId', type: 'String', value: session },
                    { name: 'CONTEXT_OVERRIDE', type: 'String', value: contextOverride }
                ]
            },
            callback: callback
        });
    }
});
