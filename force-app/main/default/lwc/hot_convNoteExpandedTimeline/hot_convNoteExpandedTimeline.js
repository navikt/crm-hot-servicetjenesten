import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

export default class ConvNoteExpandedTimeline extends NavigationMixin(LightningElement) {
    @api recordId;
    @api logEvent;
    conversationNote;
    error = false;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [
            'Conversation_note__c.Id',
            'Conversation_note__c.CRM_Conversation_Note__c',
            'Conversation_note__c.CRM_Created_By_Ident__c',
            'Conversation_note__c.CreatedDate',
            'Conversation_note__c.CRM_Journal_Status_Formula__c',
            'Conversation_note__c.CRM_Read_Date__c'
        ]
    })
    wiredConversationNote(result) {
        if (result.error) {
            this.error = true;
            console.log('Error: ' + JSON.stringify(result.error, null, 2));
        } else if (result.data) {
            const formattedCNote = {};
            Object.keys(result.data.fields).forEach((field) => {
                formattedCNote[field] = result.data.fields[field].value;
            });
            this.conversationNote = formattedCNote;
        }
    }

    openRecord(event) {
        event.stopPropagation();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Conversation_note__c',
                actionName: 'view'
            }
        });
    }

    get isLoading() {
        return !this.conversationNote && this.error === false;
    }
}
