import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getDialogByRef from '@salesforce/apex/HOT_DialogueViewController.getDialogueByApiReference';
import NAV_TASK_API_REF_FIELD from '@salesforce/schema/NavTask__c.NKS_Henvendelse_BehandlingsId__c';

const THREAD_TYPE = 'Thread__c';
const CONV_NOTE_TYPE = 'Conversation_Note__c';

export default class NksDialogueViewer extends LightningElement {
    @api recordId;
    @api objectApiName;

    threadId;
    convNoteId;
    navTaskId;
    apiReference;
    error = false;

    get isLoading() {
        return !this.threadId && !this.convNoteId && !this.navTaskId && this.error === false;
    }

    connectedCallback() {
        this.getRelatedDialogue();
    }

    getRelatedDialogue() {
        if (this.objectApiName === 'NavTask__c') {
            this.navTaskId = this.recordId;
        } else if (this.objectApiName === THREAD_TYPE) {
            this.threadId = this.recordId;
        } else if (this.objectApiName === CONV_NOTE_TYPE) {
            this.convNoteId = this.recordId;
        } else {
            //Fallback will try to find a thread related to this record
            this.threadId = this.recordId;
        }
    }

    @wire(getDialogByRef, { reference: '$apiReference' })
    wiredResp({ error, data }) {
        if (error) {
            //Something went wrong
            console.log('ERROR! ' + JSON.stringify(error, null, 2));
            this.error = true;
        } else if (data) {
            const dialog = JSON.parse(data);
            if (dialog.attributes.type === THREAD_TYPE) this.threadId = dialog.Id;
            if (dialog.attributes.type === CONV_NOTE_TYPE) this.convNoteId = dialog.Id;
        }
    }

    @wire(getRecord, { recordId: '$navTaskId', fields: [NAV_TASK_API_REF_FIELD] })
    wiredNavTask({ error, data }) {
        if (error) {
            //Something went wrong
            this.error = true;
            console.log('Error: ' + JSON.stringify(error, null, 2));
        } else if (data) {
            this.apiReference = getFieldValue(data, NAV_TASK_API_REF_FIELD);
        }
    }
}
