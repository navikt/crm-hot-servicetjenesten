import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Hot_sendSMStoCaller extends LightningElement {
    isSMSFlowVisible = false;
    @api recordId;

    get inputVariables() {
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
        ];
    }

    handleSMSButtonClick() {
        this.isSMSFlowVisible = true;
    }
    handleSMSFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            const outputVariables = event.detail.outputVariables || [];
            const successOutput = outputVariables.find((v) => v.name === 'flowSuccess');
            if (successOutput && successOutput.value === true) {
                // Show success message
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Suksess',
                        message: 'SMS-en ble sendt velykket.',
                        variant: 'success'
                    })
                );
            }

            this.isSMSFlowVisible = false;
        }
    }
}
