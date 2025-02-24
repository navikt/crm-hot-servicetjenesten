import { LightningElement, api, wire } from 'lwc';
import { publishToAmplitude } from 'c/amplitude';
//import REDACT_LABEL from '@salesforce/label/c.NKS_Set_To_Redaction';
import BUTTON_CONTAINER_NOTIFICATIONS_CHANNEL from '@salesforce/messageChannel/hotNotifications__c';
import { publish, MessageContext } from 'lightning/messageService';

export default class hotButtonContainerTop extends LightningElement {
    @api recordId;
    @api flowButtonLabel;
    @api flowApiName;
    @api channelName;

    showFlow = false;
    //redactLabel = REDACT_LABEL;
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

    get flowButtonStyling() {
        return this.flowButtonLabel === this.redactLabel ? 'redact' : '';
    }

    toggleFlow() {
        this.showFlow = !this.showFlow;
    }

    handleStatusChange(event) {
        const { status, outputVariables } = event.detail;
        if (status === 'FINISHED' || status === 'FINISHED_SCREEN') {
            this.showFlow = false;
            publishToAmplitude(this.channelName, { type: this.flowButtonLabel + ' finished' });
            this.publishMessage(outputVariables);
        }
    }

    publishMessage(outputVariables) {
        const payload = {
            recordId: this.recordId,
            flowApiName: this.flowApiName,
            outputVariables
        };
        try {
            publish(this.messageContext, BUTTON_CONTAINER_NOTIFICATIONS_CHANNEL, payload);
        } catch (error) {
            console.error('Error publishing message on button container message channel: ', error);
        }
    }
}
