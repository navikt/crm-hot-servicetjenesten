import { LightningElement, wire, track, api } from 'lwc';
import getServiceforesporsels from '@salesforce/apex/HOT_OEBSIntegrationController.HOT_OEBS_Integration';

export default class Hot_oebsServiceforesporsel extends LightningElement {
    // state
    serviceforesporsels = [];
    notaterFlat = [];
    filteredNotes = [];
    error;
    isLoading = true;

    // inputs
    @api objectApiName;
    @api recordId;

    // sorting (match actual field name)
    sortBy = 'sfNummer';
    sortDirection = 'desc';

    // serviceforespørsel table columns
    columns = [
        { label: 'SF Nummer', fieldName: 'sfNummer', type: 'text', sortable: true },
        { label: 'SF Type', fieldName: 'sfType', type: 'text', sortable: true },
        { label: 'Problemsammendrag', fieldName: 'problemSammendrag', type: 'text', wrapText: true },
        { label: 'Løsningssammendrag', fieldName: 'losningSammendrag', type: 'text', wrapText: true },
        { label: 'Henvendelse dato', fieldName: 'sfOpprettetDato', type: 'text', sortable: true }
    ];

    // notes table columns
    notatColumns = [
        { label: 'SF Nummer', fieldName: 'sfNummer', type: 'text' },
        { label: 'Notat', fieldName: 'notat', type: 'text', wrapText: true },
        { label: 'Opprettet dato', fieldName: 'opprettetDato', type: 'text' },
        { label: 'Opprettet av navn', fieldName: 'opprettetAvNavn', type: 'text' },
        { label: 'Opprettet av ident', fieldName: 'opprettetAvIdent', type: 'text' }
    ];

    @wire(getServiceforesporsels, { recordId: '$recordId', objectApiName: '$objectApiName', apiName: 'GET_OEBS_SF' })
    wiredServiceordre({ data, error }) {
        if (!data && !error) return;

        if (error) {
            this.error = error;
            this.serviceforesporsels = [];
            this.notaterFlat = [];
            this.isLoading = false;
            return;
        }

        this.error = undefined;

        const list = Array.isArray(data?.serviceRequestList) ? data.serviceRequestList : [];

        const keyed = list.map((r, i) => ({ __key: r.sfNummer ?? `row-${i}`, ...r }));

        this.serviceforesporsels = keyed.length ? this.sortedCopy(keyed, this.sortBy, this.sortDirection) : [];

        this.notaterFlat = this.serviceforesporsels.flatMap((row) =>
            (row.sfNotater ?? []).map((n, nIdx) => ({
                __key: `${row.__key}-${nIdx}`,
                sfNummer: row.sfNummer ?? '',
                notat: n.notat ?? '',
                opprettetDato: n.opprettetDato ?? '',
                opprettetAvNavn: n.opprettetAvNavn ?? '',
                opprettetAvIdent: n.opprettetAvIdent ?? ''
            }))
        );
        console.log('notaterFlat: ', this.notaterFlat);
        this.isLoading = false;
    }

    // --- Helpers ---

    toComparable(v) {
        if (v === null || v === undefined) return '';
        const t = Date.parse(v);
        if (!Number.isNaN(t)) return t;
        const n = Number(v);
        if (!Number.isNaN(n)) return n;
        return String(v).toLowerCase();
    }

    sortedCopy(arr, fieldName, dir) {
        const copy = [...arr];
        copy.sort((a, b) => {
            const aVal = this.toComparable(a?.[fieldName]);
            const bVal = this.toComparable(b?.[fieldName]);
            if (aVal > bVal) return dir === 'asc' ? 1 : -1;
            if (aVal < bVal) return dir === 'asc' ? -1 : 1;
            return 0;
        });
        return copy;
    }

    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortBy = sortedBy;
        this.sortDirection = sortDirection;
        if (this.serviceforesporsels.length) {
            this.serviceforesporsels = this.sortedCopy(this.serviceforesporsels, this.sortBy, this.sortDirection);
        }
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 0) {
            const selectedSfNummer = selectedRows[0].sfNummer;
            console.log('Selected Service: ', selectedSfNummer);
            this.filteredNotes = this.notaterFlat.filter((note) => note.sfNummer === selectedSfNummer);
        } else {
            this.filteredNotes = [];
        }
        console.log('Filtered lines: ', this.filteredNotes);
    }

    // template getters
    get hasData() {
        return (
            !this.isLoading &&
            !this.error &&
            Array.isArray(this.serviceforesporsels) &&
            this.serviceforesporsels.length > 0
        );
    }
    get hasFilteredNotes() {
        return !this.isLoading && !this.error && Array.isArray(this.filteredNotes) && this.filteredNotes.length > 0;
    }
    get hasNoData() {
        return (
            !this.isLoading &&
            !this.error &&
            Array.isArray(this.serviceforesporsels) &&
            this.serviceforesporsels.length === 0
        );
    }
}
