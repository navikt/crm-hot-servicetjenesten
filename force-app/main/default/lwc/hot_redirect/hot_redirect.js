import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';

export default class hotRedirect extends NavigationMixin(LightningElement) {
    @api recordId;
    @api availableActions;
    @api screenHelpText;
    @api navigateFlow;
    connectedCallback() {
        this.navigateToRecord(this.recordId);
        this.dispatchEvent(new FlowNavigationFinishEvent());
    }
    navigateToRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
    }
}
