import { LightningElement, api } from 'lwc';

export default class hotCreateCaseAndRedirect extends LightningElement {
    @api recordId;
    runFlow = false;

    get inputVariables() {
        return [
            {
                name: 'accountId',
                type: 'String',
                value: this.recordId
            }
        ];
    }
    handleOnClick() {
        this.runFlow = true;
    }
    handleStatusChange(event) {
        if (['FINISHED', 'FINISHED_SCREEN', 'ERROR'].includes(event.detail.status)) {
            this.runFlow = false;
        }
    }
}
