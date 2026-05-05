import { LightningElement, api, wire } from 'lwc';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { publish, MessageContext } from 'lightning/messageService';
import DATA_SYNC_CHANNEL from '@salesforce/messageChannel/hotDataSyncChannel__c';
import syncOpenAndAssigned from '@salesforce/apex/HOT_NavTaskSyncCtrl.syncOpenAndAssigned';

export default class HotNavTaskRecordSyncer extends LightningElement {
    @api recordId;

    hasSynced = false;

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        if (!this.hasSynced) {
            this.syncRecordContext();
        }
    }

    async syncRecordContext() {
        this.hasSynced = true;
        try {
            await syncOpenAndAssigned();
            if (this.recordId) {
                getRecordNotifyChange([{ recordId: this.recordId }]);
            }
            publish(this.messageContext, DATA_SYNC_CHANNEL, { status: 'SYNC_COMPLETE' });
        } catch (error) {
            console.error('Problem syncing NAV tasks on dialog task page:', this.normalizeError(error), error);
        }
    }

    normalizeError(error) {
        if (!error) {
            return 'Unknown error';
        }

        if (Array.isArray(error.body)) {
            return error.body.map((item) => item.message).join(', ');
        }

        if (error.body?.message) {
            return error.body.message;
        }

        if (error.message) {
            return error.message;
        }

        try {
            return JSON.stringify(error);
        } catch (serializationError) {
            return 'Unable to serialize error';
        }
    }
}
