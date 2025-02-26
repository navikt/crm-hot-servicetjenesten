import { LightningElement, api, wire } from 'lwc';
//import CONVERSATION_NOTE_NEW_LABEL from '@salesforce/label/c.NKS_New_Conversation_Note';
//import BACK_LABEL from '@salesforce/label/c.fbc_Back';
import CONVERSATION_NOTE_NOTIFICATIONS_CHANNEL from '@salesforce/messageChannel/hotNotifications__c';
import { publish, MessageContext } from 'lightning/messageService';
import { getOutputVariableValue } from 'c/hot_componentsUtils';

const JOURNAL_FLOW_API_NAME = 'HOT_Conversation_Note_Journal_Case_v_2';

export default class Hot_ConversationNoteButtonContainer extends LightningElement {
    @api recordId;
    @api conversationNoteButtonLabel;
    @api journalAndShare = false;
    @api showBackButton = false;

    _journalConversation;
    labels = {
        newConversationNote: 'Nytt samtalereferat',
        back: 'Tilbake'
    };
    _navTasks = [];

    @api
    get navTasks() {
        return this._navTasks;
    }

    set navTasks(value) {
        this._navTasks = value;
    }

    @api
    get journalConversation() {
        return this._journalConversation;
    }

    set journalConversation(value) {
        this._journalConversation = value;
    }

    get conversationNoteButtonVariant() {
        return this.conversationNoteButtonLabel === this.labels.newConversationNote ? 'brand-outline' : 'brand';
    }

    @wire(MessageContext)
    messageContext;

    handleFlowButtonClicked(event) {
        if (this.journalAndShare && event.detail === JOURNAL_FLOW_API_NAME) {
            this._journalConversation = true;
        }
    }

    handleFlowSucceeded(event) {
        const flowApiName = event.detail?.flowName;
        const outputVariables = event.detail?.flowOutput;
        const navTask = getOutputVariableValue(outputVariables, 'navTaskOutput');
        if (navTask) {
            this._navTasks.push(navTask);
        }

        try {
            const payload = {
                recordId: this.recordId,
                flowApiName: flowApiName,
                outputVariables: outputVariables
            };
            publish(this.messageContext, CONVERSATION_NOTE_NOTIFICATIONS_CHANNEL, payload);
        } catch (error) {
            console.error('Error publishing message on conversation note message channel: ', error);
        }
    }
}