import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class nksReadyResponseListEntry extends NavigationMixin(LightningElement) {
    @api record;

    get recordTitle() {
        return this.record?.Ready_Response_Title__c ? this.record.Ready_Response_Title__c : this.record.Title;
    }

    navigateToRecord(event) {
        event.preventDefault();
        event.stopPropagation();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.record.Id,
                actionName: 'view'
            }
        });
    }
}
