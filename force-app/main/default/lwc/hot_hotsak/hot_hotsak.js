import { LightningElement, wire, track, api } from 'lwc';
import getCases from '@salesforce/apex/HOT_HotsakIntegrationController.getCases';

export default class Hot_hotsak extends LightningElement {
    fnrValue;
    @track saker;
    @track error;
    @track isLoading = true;
    @api objectApiName;
    @api recordId;
    sortBy = 'opprettet';
    sortDirection = 'desc'; // Note: "desc" for descending

    columns = [
        { label: 'Mottatt dato', fieldName: 'opprettet', type: 'date', sortable: true },
        { label: 'Beskrivelse', fieldName: 'beskrivelse', type: 'text', sortable: true },
        { label: 'Status', fieldName: 'saksstatus', type: 'text', sortable: true },
        { label: 'Behandlet dato', fieldName: 'endret', type: 'date', sortable: true },
        { label: 'Saksid', fieldName: 'saksid', type: 'text', sortable: true }
    ];

    @wire(getCases, { recordId: '$recordId', objectApiName: '$objectApiName' })
    wiredSaker({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.error = undefined;
            // Map the data as required
            this.saker = data.map(record => {
                return {
                    ...record,
                    beskrivelse: record.behovsmelding && record.behovsmelding.gjelder ? record.behovsmelding.gjelder : ''
                };
            });
            // Call the sort function right after the data returns
            this.sortData(this.sortBy, this.sortDirection);
        } else if (error) {
            this.saker = undefined;
            this.error = error;
            console.error(error);
        }
    }

    // Helper function for sorting
    sortData(fieldName, sortDirection) {
        const sortedData = [...this.saker].sort((a, b) => {
            const aVal = a[fieldName] ? a[fieldName] : '';
            const bVal = b[fieldName] ? b[fieldName] : '';
            if (aVal > bVal) {
                return sortDirection === 'asc' ? 1 : -1;
            } else if (aVal < bVal) {
                return sortDirection === 'asc' ? -1 : 1;
            }
            return 0;
        });
        this.saker = sortedData;
    }

    // Existing sort handler for UI interactions
    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortBy = sortedBy;
        this.sortDirection = sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    get hasData() {
        return !this.isLoading && this.saker && this.saker.length > 0;
    }
    get hasNoData() {
        return !this.isLoading && this.saker && this.saker.length === 0;
    }
}
