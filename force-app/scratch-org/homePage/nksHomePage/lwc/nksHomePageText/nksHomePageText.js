import { LightningElement, api, wire } from 'lwc';
import getField from '@salesforce/apex/NKS_HomePageController.getField';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

export default class NksHomePageText extends NavigationMixin(LightningElement) {
    @api cardTitle;
    @api iconName;
    @api type;
    @api listViewName;
    @api enableRefresh = false;

    text;
    pageUrl;
    wiredField;
    showSpinner = false;
    recordTypeName = '';

    recordTypeMap = {
        Nyhet: 'News',
        Kampanje: 'Campaign',
        'Teknisk og drift': 'Operational',
        'Salesforce oppdatering': 'Salesforce_Update',
        Trafikk: 'Traffic'
    };

    @wire(getField, {
        type: '$recordTypeName'
    })
    wiredData(result) {
        this.wiredField = result;
        this.loadField();
    }

    connectedCallback() {
        this.recordTypeName = this.recordTypeMap[this.type] || this.type;
        this.generatePageUrl();
    }

    loadField() {
        const { error, data } = this.wiredField;
        if (data) {
            this.text = data?.length > 0 ? data : null;
        } else if (error) {
            console.error('An error occurred:', error);
        }
    }

    refreshField() {
        this.showSpinner = true;
        refreshApex(this.wiredField)
            .then(() => this.loadField())
            .finally(() => (this.showSpinner = false));
    }

    navigateToList() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'NKS_Announcement__c',
                actionName: 'list'
            },
            state: {
                filterName: this.listViewName
            }
        });
    }

    generatePageUrl() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'NKS_Announcement__c',
                actionName: 'list'
            },
            state: {
                filterName: this.listViewName
            }
        }).then((url) => {
            this.pageUrl = url;
        });
    }

    get isSalesforceUpdate() {
        return this.type === 'Salesforce oppdatering';
    }

    get isTraffic() {
        return this.type === 'Trafikk';
    }

    get icon() {
        return this.iconName && this.iconName.trim() !== '' ? this.iconName : null;
    }

    get showOperational() {
        return this.isOperational && this.text;
    }

    get isOperational() {
        return this.type === 'Teknisk og drift';
    }

    get showSalesforceUpdate() {
        return this.isSalesforceUpdate && this.text;
    }
}
