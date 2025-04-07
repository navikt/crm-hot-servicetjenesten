import { LightningElement, api, wire } from 'lwc';
import getField from '@salesforce/apex/HOT_HomePageController.getField';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

export default class hot_homePageText extends NavigationMixin(LightningElement) {
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
        HOT_SF_Update: 'HOT_SF_Update',
        HOT_Info: 'HOT_Info'
    };

    @wire(getField, {
        //type: '$recordTypeName'
        type: '$type'
    })
    wiredData(result) {
        this.wiredField = result;
        this.loadField();
    }

    connectedCallback() {
        //this.recordTypeName = this.type;
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
        return this.type === 'HOT_SF_Update';
    }

    get isInfo() {
        return this.type === 'HOT_Info';
    }

    get icon() {
        return this.iconName && this.iconName.trim() !== '' ? this.iconName : null;
    }

    get showSalesforceUpdate() {
        return this.isSalesforceUpdate && this.text;
    }
}
