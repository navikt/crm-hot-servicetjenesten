import { LightningElement, wire, track } from 'lwc';
import getSaker from '@salesforce/apex/HOT_HotsakIntegrationController.getSaker';

export default class Hot_hotsak extends LightningElement {
    fnrValue = '15084300133';
    @track saker; // data
    @track error; // store error object or message
    @track isLoading = true; // start true until data/error returns

    @wire(getSaker, { fnr: '$fnrValue' })
    wiredSaker({ data, error }) {
        // Once the wire returns, we're no longer "loading"
        this.isLoading = false;

        if (data) {
            this.error = undefined; // clear any old error
            this.saker = data;      // store data
        } else if (error) {
            this.saker = undefined; // clear data
            this.error = error;     // store error info
        }
    }

    // Optional getters for clarity in the template
    get hasData() {
        return !this.isLoading && this.saker && this.saker.length > 0;
    }
    get hasNoData() {
        return !this.isLoading && this.saker && this.saker.length === 0;
    }
}
