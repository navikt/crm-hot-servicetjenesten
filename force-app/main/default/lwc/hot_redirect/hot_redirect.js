import { LightningElement, api, wire } from 'lwc';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';
import { EnclosingTabId, openSubtab, openTab, closeTab } from 'lightning/platformWorkspaceApi';

export default class hotRedirect extends LightningElement {
    @api recordId;
    @api availableActions;
    @api screenHelpText;
    @api navigateFlow;
    @api openAsSubtab = false;
    @api closeCurrentTab = false;

    connectedCallback() {
        this.navigateToRecord(this.recordId);
        this.dispatchEvent(new FlowNavigationFinishEvent());
    }

    @wire(EnclosingTabId) currentTabId;

    navigateToRecord() {
        if (this.openAsSubtab) {
            openSubtab(this.currentTabId, { recordId: this.recordId, focus: true })
                .then(() => {
                    /*nothing to do*/
                })
                .catch((error) => {
                    console.log('Error opening subtab: ' + error);
                });
        } else {
            openTab({ recordId: this.recordId, focus: true })
                .then(() => {
                    if (this.closeCurrentTab) {
                        closeTab(this.currentTabId)
                            .then(() => {
                                /*nothing to do*/
                            })
                            .catch((error) => {
                                console.log('Error closing tab: ' + error);
                            });
                    }
                }, this)
                .catch((error) => {
                    console.log('Error opening tab: ' + error);
                });
        }
    }
}
