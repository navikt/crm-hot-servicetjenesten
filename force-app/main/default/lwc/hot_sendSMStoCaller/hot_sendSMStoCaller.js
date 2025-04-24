import { LightningElement, api } from 'lwc';

export default class Hot_sendSMStoCaller extends LightningElement {
    @api recordId;
    isSMSFlowVisible = false;
    confirmationMessage = '';
    flowSuccess = false;
    hasScrolled = false;

    get inputVariables() {
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
        ];
    }

    get buttonVariant() {
        return this.isSMSFlowVisible ? 'neutral' : 'brand';
    }

    handleSMSButtonClick() {
        this.isSMSFlowVisible = !this.isSMSFlowVisible;
        if (this.isSMSFlowVisible) {
            // reset state for a fresh render
            this.confirmationMessage = '';
            this.flowSuccess = false;
            this.hasScrolled = false;
        }
    }

    renderedCallback() {
        // scroll only once after flow appears
        if (this.isSMSFlowVisible && !this.hasScrolled) {
            const el = this.template.querySelector('.flowContainer');
            if (el) {
                el.scrollIntoView({ behavior: 'smooth' });
                this.hasScrolled = true;
            }
        }
    }

    handleSMSFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            const outputs = event.detail.outputVariables || [];
            const success = outputs.find((v) => v.name === 'flowSuccess')?.value;
            this.flowSuccess = success === true;
            this.confirmationMessage = this.flowSuccess ? 'SMS-en ble sendt velykket.' : 'Feil ved sending av SMS.';
            this.isSMSFlowVisible = false;
        }
    }
}
