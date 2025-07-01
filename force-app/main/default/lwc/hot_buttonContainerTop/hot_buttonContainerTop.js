import { LightningElement, api, wire } from 'lwc';
import BUTTON_CONTAINER_NOTIFICATIONS_CHANNEL from '@salesforce/messageChannel/hotNotifications__c';
import { publish, MessageContext } from 'lightning/messageService';

export default class hotButtonContainerTop extends LightningElement {
    @api recordId;
    @api flowButtonLabel;
    @api flowApiName;
    @api channelName;

    showFlow = false;
    redactLabel = 'Send til sladding';

    @wire(MessageContext)
    messageContext;

    get inputVariables() {
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
        ];
    }

    get buttonExpanded() {
        return this.showFlow.toString();
    }

    toggleFlow() {
        this.showFlow = !this.showFlow;
    }

    handleStatusChange(event) {
        const { status, outputVariables } = event.detail;
        if ((status === 'FINISHED' || status === 'FINISHED_SCREEN') && outputVariables != null) {
            this.showFlow = false;
            this.publishMessage(outputVariables);
        }
    }

    publishMessage(outputVariables) {
        const payload = {
            type: 'BUTTON_CONTAINER_NOTIFICATIONS',
            recordId: this.recordId,
            flowApiName: this.flowApiName,
            outputVariables: outputVariables
        };
        try {
            publish(this.messageContext, BUTTON_CONTAINER_NOTIFICATIONS_CHANNEL, payload);
        } catch (error) {
            console.error('Error publishing message on button container message channel: ', error);
        }
    }
}
