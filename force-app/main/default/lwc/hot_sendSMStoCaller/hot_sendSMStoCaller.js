import { LightningElement, api } from 'lwc';

export default class Hot_sendSMStoCaller extends LightningElement {
    @api recordId;
    isSMSFlowVisible = false;
    confirmationMessage = '';
    flowSuccess = false;

    get inputVariables() {
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
        ];
    }

    // toggle brand <-> neutral
    get buttonVariant() {
        return this.isSMSFlowVisible ? 'neutral' : 'brand';
    }

    handleSMSButtonClick() {
        this.isSMSFlowVisible = !this.isSMSFlowVisible;
        // clear old message when opening
        if (this.isSMSFlowVisible) {
            this.confirmationMessage = '';
            // wait for DOM update, then scroll
            setTimeout(() => {
                const el = this.template.querySelector('.flowContainer');
                if (el) el.scrollIntoView({ behavior: 'smooth' });
            }, 0);
        }
    }

    handleSMSFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            const outputs = event.detail.outputVariables || [];
            const success = outputs.find((v) => v.name === 'flowSuccess')?.value;
            this.flowSuccess = success === true;
            this.confirmationMessage = success ? 'SMS-en ble sendt velykket.' : 'Feil ved sending av SMS.';
            this.isSMSFlowVisible = false;
        }
    }
}
