import { LightningElement, api, wire } from 'lwc';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import CONVERSATION_NOTE_FIELD from '@salesforce/schema/Conversation_Note__c.CRM_Conversation_Note__c';
import TIMELINE_NAME_FIELD from '@salesforce/schema/Conversation_Note__c.NKS_Timeline_Name__c';

const CONVERSATION_NOTE_FIELDS = [CONVERSATION_NOTE_FIELD, TIMELINE_NAME_FIELD];

export default class Hot_conversationNoteViewer extends LightningElement {
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

    //endre navn her når flow blir laget
    handleJournal() {
        this.startFlow('NKS_Conversation_Note_Journal_Case_v_2');
    }

    //endre navn her også
    handleSetToRedaction() {
        this.startFlow('NKS_Conversation_Note_Set_Redaction_v_2');
    }

    handleCreateNavTask() {
        this.startFlow('HOT_Conversation_Note_Send_Nav_Task');
    }

    startFlow(flowName) {
        const flow = this.template.querySelector('lightning-flow');
        if (flow) {
            const inputVariables = [
                {
                    name: 'recordId',
                    type: 'String',
                    value: this.recordId
                }
            ];
            flow.startFlow(flowName, inputVariables);
        }
    }
}
