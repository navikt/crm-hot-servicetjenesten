import { LightningElement, api, wire } from 'lwc';
import hasPermission from '@salesforce/customPermission/NKS_Communication';
import createNksCurrent from '@salesforce/apex/NKS_HomePageController.createNksCurrent';
import getNksCurrents from '@salesforce/apex/NKS_HomePageController.getNksCurrents';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';

export default class NksHomePageCurrent extends NavigationMixin(LightningElement) {
    @api cardLabel;

    showDropdown = false;
    records = [];
    showModal = false;
    wiredRecords;
    title = '';
    url = '';

    @wire(getNksCurrents)
    wiredCurrents(result) {
        this.wiredRecords = result;
        const { data, error } = result;
        if (data) {
            this.records = data;
        } else if (error) {
            console.error(`Problem getting currents: ${error}`);
        }
    }

    get buttonClass() {
        return `slds-dropdown-trigger slds-dropdown-trigger_click ${
            this.showDropdown ? 'slds-is-open' : 'slds-is-close'
        }`;
    }

    get hasRecords() {
        return this.records.length > 0;
    }

    get modalClass() {
        return `slds-modal slds-modal_prompt ${this.showModal ? 'slds-fade-in-open' : 'slds-fade-in-close'}`;
    }

    get hasPermission() {
        return hasPermission;
    }

    toggleDropdown() {
        this.showDropdown = !this.showDropdown;
    }

    refreshData() {
        if (this.wiredRecords) {
            refreshApex(this.wiredRecords);
        }
    }

    handleAddLink() {
        this.showModal = true;
        this.showDropdown = false;
    }

    handleCancel() {
        this.showModal = false;
    }

    handleInputChange(event) {
        const { name, value } = event.target;
        this[name] = value;
    }

    handleSubmit(event) {
        event.preventDefault();

        createNksCurrent({ title: this.title, URL: this.url })
            .then(() => {
                this.refreshData();
                console.log('NKS current created successfully');
            })
            .catch((error) => {
                const errorMessage = error.body?.message || 'Unknown error occurred';
                console.error(`Error creating NKS current: ${errorMessage}`);
            });

        this.showModal = false;
        this.showDropdown = false;
    }

    navigateToListView() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'NKS_Announcement__c',
                actionName: 'list'
            },
            state: {
                filterName: 'Current_From_NAV'
            }
        });
        this.showDropdown = false;
    }
}
