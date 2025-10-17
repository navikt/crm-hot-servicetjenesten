import { LightningElement, wire, track, api } from 'lwc';
import getOrder from '@salesforce/apex/HOT_OEBSIntegrationController.HOT_OEBS_Integration';

export default class Hot_oebsOrdrelinjer extends LightningElement {
    @api objectApiName;
    @api recordId;

    // state
    order = [];
    ordreLinjer = [];
    filteredlines = [];
    error;
    isLoading = true;

    // sorting
    sortBy = 'ordreNummer';
    sortDirection = 'asc';

    // Order table columns
    ordreColumns = [
        { label: 'Ordre', fieldName: 'ordreNummer', type: 'text', sortable: true },
        { label: 'Fødselsnummer', fieldName: 'fnr', type: 'text', sortable: false },
        { label: 'Brukernummer', fieldName: 'brukerNummer', type: 'text', sortable: false },
        { label: 'Ordre Dato', fieldName: 'ordreDato', type: 'text', sortable: true },
        { label: 'Status', fieldName: 'status', type: 'text', sortable: true }
        //{ label: 'orgId', fieldName: 'orgId', type: 'text', sortable: true },
    ];
    // OrderLine table columns
    linjeColumns = [
        { label: 'Linje', fieldName: 'ordreLinjeNummer', type: 'text' },
        { label: 'Ordre', fieldName: 'ordreNummer', type: 'text' },
        { label: 'Best.Nr', fieldName: 'bestillingsNummer', type: 'text' },
        { label: 'Anmod.Nr', fieldName: 'anmodningsNummer', type: 'text' },
        { label: 'Artikkel', fieldName: 'artikkel', type: 'text' },
        { label: 'Beskrivelse', fieldName: 'artikkelBeskrivelse', type: 'text' },
        { label: 'Antall', fieldName: 'antall', type: 'text' },
        { label: 'Lovet dato', fieldName: 'lovetDato', type: 'text' },
        { label: 'Planl. skipning', fieldName: 'planlagtSkipningsDato', type: 'text' },
        { label: 'Leveringsadresse', fieldName: 'leveringsadresse', type: 'text' }
        //{ label: 'leveringsadresse', fieldName: 'leveringsadresse', type: 'text' },
        //{ label: 'city', fieldName: 'city', type: 'text' },
        //{ label: 'postNummer', fieldName: 'postNummer', type: 'text'},
        //{ label: 'kommune', fieldName: 'kommune', type: 'text' },
        //{ label: 'bydel', fieldName: 'bydel', type: 'text' },
    ];

    @wire(getOrder, {
        recordId: '$recordId',
        objectApiName: '$objectApiName',
        apiName: 'GET_OEBS_Ordre'
    })
    wiredOrdre({ data, error }) {
        if (!data && !error) return;

        if (error) {
            this.error = error;
            this.order = [];
            this.ordrelinjer = [];
            this.filteredlines = [];
            this.isLoading = false;
            return;
        }
        this.error = undefined;

        const list = Array.isArray(data?.orderList) ? data.orderList : [];

        const keyed = list.map((r, i) => ({ __key: r.ordreNummer ?? `row-${i}`, ...r }));

        this.order = keyed.length ? this.sortedCopy(keyed, this.sortBy, this.sortDirection) : [];

        this.ordreLinjer = this.order.flatMap((row) =>
            (row.ordreLinjer ?? []).map((n, nIdx) => ({
                __key: `${row.__key}-${nIdx}`,
                ordreNummer: row.ordreNummer ?? '',
                ordreLinjeNummer: n.ordreLinjeNummer ?? '',
                artikkel: n.artikkel ?? '',
                artikkelBeskrivelse: n.artikkelBeskrivelse ?? '',
                antall: n.antall ?? '',
                lovetDato: n.lovetDato ?? '',
                planlagtSkipningsDato: n.planlagtSkipningsDato ?? '',
                leveringsadresse: n.leveringsadresse ?? ''
                //anmodningsNummer: n.anmodningsNummer ?? '',
                //bestillingsNummer: n.bestillingsNummer ?? '',
                //city: n.city ?? '',
                //postNummer: n.postNummer ?? '',
                //kommune: n.kommune ?? '',
                //bydel: n.bydel ?? ''
            }))
        );
        console.log('Ordrelinjer: ', this.ordreLinjer);
        this.isLoading = false;
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
        if (this.order?.length) {
            this.order = this.sortedCopy(this.order, this.sortBy, this.sortDirection);
        }
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 0) {
            const selectedOrderLine = selectedRows[0].ordreNummer;
            console.log('Selected ordrenummer: ', selectedOrderLine);
            this.filteredlines = this.ordreLinjer.filter((o) => o.ordreNummer === selectedOrderLine);
        } else {
            this.filteredlines = [];
        }
        console.log('Filtered lines: ', this.filteredlines);
    }

    // template helpers
    get hasOrder() {
        return !this.isLoading && !this.error && Array.isArray(this.order) && this.order.length > 0;
    }
    get hasNoOrder() {
        return !this.isLoading && !this.error && Array.isArray(this.order) && this.order.length === 0;
    }

    get hasFilteredLines() {
        return !this.isLoading && !this.error && Array.isArray(this.filteredlines) && this.filteredlines.length > 0;
    }

    get hasOrder() {
        return Array.isArray(this.order) && this.order.length > 0;
    }
}
