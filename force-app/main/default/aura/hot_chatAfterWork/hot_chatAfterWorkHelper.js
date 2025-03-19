({
    startTimer: function (component, event) {
        const showTimer = component.get('v.showTimer');
        if (!showTimer) {
            component.set('v.showTimer', true);
            component.set('v.maxTimer', component.get('v.timer'));
            // eslint-disable-next-line @locker/locker/distorted-window-set-interval, @lwc/lwc/no-async-operation
            const intervalId = setInterval(() => {
                if (component.get('v.stopped')) clearInterval(intervalId);
                let tempTimer = component.get('v.timer') - 1;
                component.set('v.timer', tempTimer);
                component.set('v.percentageTimer', (tempTimer * 100) / component.get('v.maxTimer'));
                if (tempTimer <= 0) {
                    clearInterval(intervalId);
                    this.closeTab(component, event);
                }
            }, 1000);
        }
    },
    closeTab: function (component, eventRecordId) {
        const workspaceAPI = component.find('workspace');
        workspaceAPI
            .getAllTabInfo()
            .then((res) => {
                const eventTab = res.find((content) => content.recordId === eventRecordId);
                if (!eventTab) return;
                workspaceAPI.closeTab({ tabId: eventTab.tabId });
            })
            .catch(() => {
                //Errors require manual handling.
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
