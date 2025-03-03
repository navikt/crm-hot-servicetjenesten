import { LightningElement, api, wire } from 'lwc';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

import { publish, MessageContext } from 'lightning/messageService';
import hotRefreshRecord from '@salesforce/messageChannel/hotNotifications__c';

export default class HotRecordRefresher extends LightningElement {
    @api recordId;

    @wire(MessageContext)
    messageContext;

    renderedCallback() {
        this.handleRefresh();
        this.publishRefreshMessage();
    }

    //Published message for custom components to trigger refresh
    publishRefreshMessage() {
        const payload = { recordId: this.recordId, type: 'RECORD_REFRESH' };
        publish(this.messageContext, hotRefreshRecord, payload);
    }

    async handleRefresh() {
        // Notify LDS that you've changed the record outside its mechanisms.
        getRecordNotifyChange([{ recordId: this.recordId }]); //Triggers refresh of standard components
    }
}
