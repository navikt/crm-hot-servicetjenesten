import { LightningElement, api, wire } from 'lwc';
import CONVERSATION_NOTE_NOTIFICATIONS_CHANNEL from '@salesforce/messageChannel/conversationNoteNotifications__c';
import { publish, MessageContext } from 'lightning/messageService';
import { getOutputVariableValue } from 'c/hot_componentsUtils';

const JOURNAL_FLOW_API_NAME = 'HOT_Conversation_Note_Journal_Case';
const NAV_TASK_FLOW_API_NAME = 'HOT_Case_Send_NAV_Task';

export default class HOT_ConversationNoteButtonContainer extends LightningElement {
    @api recordId;
    @api conversationNoteButtonLabel;
    @api journalAndShare = false;
    @api showBackButton = false;

    _journalConversation = false;
    _navTasks = [];

    labels = {
        newConversationNote: 'Nytt samtalereferat',
        back: 'Tilbake'
    };

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

    // Handle clicking the Next button by starting the appropriate flow.
    handleNext() {
        const flowApiName =
            this.conversationNoteButtonLabel === this.labels.newConversationNote
                ? JOURNAL_FLOW_API_NAME
                : NAV_TASK_FLOW_API_NAME;

        if (this.journalAndShare && flowApiName === JOURNAL_FLOW_API_NAME) {
            this.journalConversation = true;
        }

        const flow = this.template.querySelector('lightning-flow');
        if (flow) {
            flow.startFlow(flowApiName, [{ name: 'recordId', type: 'String', value: this.recordId }]);
        }
    }

    // Handle Back button click – adjust as needed.
    handleBack() {
        console.log('Back button clicked');
        // Implement your back navigation logic here.
    }

    // Handle status change events from the lightning-flow component.
    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            const flowApiName = event.detail.flowApiName;
            const outputVariables = event.detail.outputVariables;
            const navTask = getOutputVariableValue(outputVariables, 'navTaskOutput');
            if (navTask) {
                this._navTasks = [...this._navTasks, navTask];
            }
            const payload = {
                recordId: this.recordId,
                flowApiName: flowApiName,
                outputVariables: outputVariables
            };
            try {
                publish(this.messageContext, CONVERSATION_NOTE_NOTIFICATIONS_CHANNEL, payload);
            } catch (error) {
                console.error('Error publishing message on conversation note message channel: ', error);
            }
        }
    }

    // If journalConversation is true, allow user to navigate to the next screen.
    handleJournalNext() {
        console.log('Navigating to next screen in journal conversation');
        // Implement any additional navigation logic as needed.
    }
}
