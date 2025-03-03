import { LightningElement, api, wire } from 'lwc';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import CONVERSATION_NOTE_FIELD from '@salesforce/schema/Conversation_Note__c.CRM_Conversation_Note__c';
import TIMELINE_NAME_FIELD from '@salesforce/schema/Conversation_Note__c.HOT_Timeline_Name__c';

const CONVERSATION_NOTE_FIELDS = [CONVERSATION_NOTE_FIELD, TIMELINE_NAME_FIELD];

export default class HOTConversationNoteViewer extends LightningElement {
    @api recordId;
    @api objectApiName;

    conversationNote;
    timelineName;

    @wire(getRecord, { recordId: '$recordId', fields: CONVERSATION_NOTE_FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.conversationNote = getFieldValue(data, CONVERSATION_NOTE_FIELD);
            this.timelineName = getFieldValue(data, TIMELINE_NAME_FIELD);
        } else if (error) {
            console.error('Error fetching Conversation Note:', error);
        }
    }
}