import { LightningElement, wire, track, api } from 'lwc';
import getOEBS from '@salesforce/apex/HOT_OEBSIntegrationController.HOT_OEBS_Integration';

export default class Hot_oebsOrdrelinjer extends LightningElement {
    @api objectApiName;
    @api recordId;

    // state
    @track ordrelinjer = [];
    @track error;
    @track isLoading = true;

    // sorting
    sortBy = 'ordreLinjeNummer';
    sortDirection = 'asc';

    columns = [
        { label: 'OrdrelinjeNr', fieldName: 'ordreLinjeNummer', type: 'text', sortable: true },
        { label: 'Ordrenummer', fieldName: 'ordreNummer', type: 'text', sortable: true },
        { label: 'Status', fieldName: 'statusOrdreLinje', type: 'text', sortable: true },
        { label: 'Artikkel', fieldName: 'artikkel', type: 'text', sortable: true },
        { label: 'ArtikkelBeskrivelse', fieldName: 'artikkelBeskrivelse', type: 'text', sortable: true },
        { label: 'AnmodningsNr', fieldName: 'anmodningsNummer', type: 'text', sortable: true },
        { label: 'BestillingsNr', fieldName: 'bestillingsNummer', type: 'text', sortable: true },
        { label: 'Leveringsadresse', fieldName: 'leveringsadresse', type: 'text', sortable: true }
        // { label: 'Lovet dato',        fieldName: 'lovetDato',          type: 'text', sortable: true },
        // { label: 'Planl. skipning',   fieldName: 'planlagtSkipningsDato', type: 'text', sortable: true },
    ];

    @wire(getOEBS, {
        recordId: '$recordId',
        objectApiName: '$objectApiName',
        apiName: 'GET_OEBS_Ordre'
    })
    wiredOrdre({ data, error }) {
        if (!data && !error) return;
        this.isLoading = false;

        if (error) {
            this.error = error;
            this.ordrelinjer = [];
            return;
        }
        this.error = undefined;

        const orders = Array.isArray(data?.orderList) ? data.orderList : [];

        const flat = [];
        orders.forEach((o, oi) => {
            const lines = Array.isArray(o?.orderLineList) ? o.orderLineList : [];
            lines.forEach((l, li) => {
                flat.push({
                    __key: `${o.ordreNummer || 'ord'}-${l.ordreLinjeNummer || li}-${oi}-${li}`,
                    ordreNummer: o.ordreNummer,
                    ...l
                });
            });
        });

        this.ordrelinjer = flat.length ? this.sortedCopy(flat, this.sortBy, this.sortDirection) : [];
    }

    toComparable(v) {
        if (v === null || v === undefined) return '';
        const ts = Date.parse(v);
        if (!Number.isNaN(ts)) return ts;
        const num = Number(v);
        if (!Number.isNaN(num)) return num;
        return String(v).toLowerCase();
    }

    sortedCopy(arr, field, dir) {
        const out = [...arr];
        out.sort((a, b) => {
            const av = this.toComparable(a?.[field]);
            const bv = this.toComparable(b?.[field]);
            if (av > bv) return dir === 'asc' ? 1 : -1;
            if (av < bv) return dir === 'asc' ? -1 : 1;
            return 0;
        });
        return out;
    }

    handleSort(event) {
        const { fieldName, sortDirection } = event.detail;
        this.sortBy = fieldName;
        this.sortDirection = sortDirection;
        if (this.ordrelinjer?.length) {
            this.ordrelinjer = this.sortedCopy(this.ordrelinjer, this.sortBy, this.sortDirection);
        }
    }

    // template helpers
    get hasData() {
        return !this.isLoading && this.ordrelinjer.length > 0;
    }
    get hasNoData() {
        return !this.isLoading && this.ordrelinjer.length === 0;
    }
}
