import { LightningElement, wire, track, api } from 'lwc';
import getCases from '@salesforce/apex/HOT_HotsakIntegrationController.getCases';

export default class Hot_hotsak extends LightningElement {
    fnrValue = '15084300133';
    @track saker;
    @track error;
    @track isLoading = true;
    @api objectApiName;
    @api recordId;

    columns = [
        { label: 'Mottatt dato', fieldName: 'opprettet', type: 'date' },
        { label: 'Beskrivelse', fieldName: 'beskrivelse', type: 'text' },
        { label: 'Status', fieldName: 'saksstatus', type: 'text' },
        { label: 'Behandlet dato', fieldName: 'endret', type: 'date' },
        { label: 'Saksid', fieldName: 'saksid', type: 'text' }
    ];

    @wire(getCases, { recordId: '$recordId', objectApiName: '$objectApiName' })
    wiredSaker({ data, error }) {
        this.isLoading = false;

        if (data) {
            this.error = undefined;

            // må flytte beskrivelse/gjelder til top level for at det skal fungere med lightning table
            this.saker = data.map((record) => {
                return {
                    ...record,
                    beskrivelse:
                        record.behovsmelding && record.behovsmelding.gjelder ? record.behovsmelding.gjelder : ''
                };
            });
        } else if (error) {
            this.saker = undefined;
            this.error = error;
            console.error(error);
        }
    }

    get hasData() {
        return !this.isLoading && this.saker && this.saker.length > 0;
    }
    get hasNoData() {
        return !this.isLoading && this.saker && this.saker.length === 0;
    }
}
