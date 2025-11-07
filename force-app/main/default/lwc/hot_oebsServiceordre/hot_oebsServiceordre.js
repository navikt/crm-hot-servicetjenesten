import { LightningElement, wire, track, api } from 'lwc';
import getServiceordre from '@salesforce/apex/HOT_OEBSIntegrationController.HOT_OEBS_Integration';

export default class Hot_oebsServiceordre extends LightningElement {
    @track serviceOrdre = [];
    @track error;
    @track isLoading = true;

    @api objectApiName;
    @api recordId;

    sortBy = 'opprettelsesDato';
    sortDirection = 'desc';

    columns = [
        { label: 'Serviceordrenummer', fieldName: 'serviceOrdreNummer', type: 'text', sortable: true },
        { label: 'Servicetype', fieldName: 'serviceType', type: 'text', sortable: true },
        { label: 'Artikkel', fieldName: 'artikkel', type: 'text', sortable: true },
        { label: 'Artikkelbeskrivelse', fieldName: 'artikkelBeskrivelse', type: 'text', sortable: true },
        { label: 'Status', fieldName: 'serviceOrdreStatus', type: 'text', sortable: true },
        { label: 'Opprettet dato', fieldName: 'opprettelsesDato', type: 'text', sortable: true }
    ];

    @wire(getServiceordre, { recordId: '$recordId', objectApiName: '$objectApiName', apiName: 'GET_OEBS_SO' })
    wiredServiceordre({ data, error }) {
        if (data) {
            this.error = undefined;

            const list = Array.isArray(data?.serviceOrderList) ? data.serviceOrderList : [];

            const validServiceOrders = list.filter((serviceOrdre) => serviceOrdre?.artikkel !== undefined);

            this.serviceOrdre = validServiceOrders;
            if (this.serviceOrdre.length) {
                this.sortData(this.sortBy, this.sortDirection);
            }
            this.isLoading = false;
        } else if (error) {
            this.serviceOrdre = [];
            this.error = error;
            this.isLoading = false;
        }
    }

    sortData(fieldName, sortDirection) {
        if (!this.serviceOrdre || !this.serviceOrdre.length) return;

        const toComparable = (v) => {
            if (v === null || v === undefined) return '';
            const t = Date.parse(v);
            if (!isNaN(t)) return t;
            const n = Number(v);
            if (!isNaN(n)) return n;
            return String(v).toLowerCase();
        };

        const sorted = [...this.serviceOrdre].sort((a, b) => {
            const aVal = toComparable(a[fieldName]);
            const bVal = toComparable(b[fieldName]);
            if (aVal > bVal) return sortDirection === 'asc' ? 1 : -1;
            if (aVal < bVal) return sortDirection === 'asc' ? -1 : 1;
            return 0;
        });

        this.serviceOrdre = sorted;
    }

    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortBy = sortedBy;
        this.sortDirection = sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    get hasData() {
        return !this.isLoading && !this.error && Array.isArray(this.serviceOrdre) && this.serviceOrdre.length > 0;
    }
    get noData() {
        return !this.isLoading && !this.error && Array.isArray(this.serviceOrdre) && this.serviceOrdre.length === 0;
    }
    get skeletonColumnCount() {
        return Array.isArray(this.columns) ? this.columns.length : 0;
    }
}
