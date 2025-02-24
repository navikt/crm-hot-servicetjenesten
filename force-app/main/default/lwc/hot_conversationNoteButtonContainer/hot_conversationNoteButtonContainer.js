import { LightningElement, api, wire } from 'lwc';
//import CONVERSATION_NOTE_NOTIFICATIONS_CHANNEL from '@salesforce/messageChannel/conversationNoteNotifications__c';
import { publish, MessageContext } from 'lightning/messageService';
import { getOutputVariableValue } from 'c/hot_componentsUtils';
import { FlowNavigationBackEvent, FlowNavigationNextEvent, FlowNavigationFinishEvent } from 'lightning/flowSupport';

const JOURNAL_FLOW_API_NAME = 'HOT_Conversation_Note_Journal_Case';
const NAV_TASK_FLOW_API_NAME = 'HOT_Case_Send_NAV_Task';

export default class Hot_ConversationNoteButtonContainer extends LightningElement {
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

    /**
     * Helper to dispatch a navigation event.
     * @param {string} action - 'NEXT', 'BACK', or 'FINISH'
     */
    handleNavigation(action) {
        let flowEvent;
        switch (action) {
            case 'NEXT':
                flowEvent = new FlowNavigationNextEvent();
                break;
            case 'BACK':
                flowEvent = new FlowNavigationBackEvent();
                break;
            case 'FINISH':
                flowEvent = new FlowNavigationFinishEvent();
                break;
            default:
                console.error('Invalid action:', action);
                return;
        }
        this.dispatchEvent(flowEvent);
    }

    /**
     * Handles the Next button click.
     * Determines the proper flow to start and dispatches a NEXT navigation event.
     */
    handleNext() {
        const flowApiName = this.conversationNoteButtonLabel === this.labels.newConversationNote
            ? JOURNAL_FLOW_API_NAME
            : NAV_TASK_FLOW_API_NAME;
            
        if (this.journalAndShare && flowApiName === JOURNAL_FLOW_API_NAME) {
            this.journalConversation = true;
        }

        const flow = this.template.querySelector('lightning-flow');
        if (flow) {
            flow.startFlow(flowApiName, [{ name: 'recordId', type: 'String', value: this.recordId }]);
        }
        // Dispatch NEXT navigation event
        this.handleNavigation('NEXT');
    }

    /**
     * Handles the Back button click and dispatches a BACK navigation event.
     */
    handleBack() {
        console.log('Back button clicked');
        this.handleNavigation('BACK');
    }

    /**
     * Listens for status change events from the lightning-flow component.
     * When the flow finishes, processes output variables, publishes a message,
     * and optionally dispatches a FINISH navigation event.
     */
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
                //publish(this.messageContext, CONVERSATION_NOTE_NOTIFICATIONS_CHANNEL, payload);
            } catch (error) {
                console.error('Error publishing message on conversation note message channel: ', error);
            }
            // Optionally dispatch a FINISH navigation event if required
            this.handleNavigation('FINISH');
        }
    }

    /**
     * For journal conversation navigation. Dispatches a NEXT navigation event.
     */
    handleJournalNext() {
        console.log('Navigating to next screen in journal conversation');
        this.handleNavigation('NEXT');
    }
}
