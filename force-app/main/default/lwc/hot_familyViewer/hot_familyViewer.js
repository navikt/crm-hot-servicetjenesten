import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getRelations from '@salesforce/apex/HOT_FamilyViewController.getRelations';

export default class hotFamilyViewer extends LightningElement {
    @api objectApiName;
    @api recordId;
    wireFields;
    isLoaded = false;

    connectedCallback() {
        this.wireFields = [this.objectApiName + '.Id'];
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$wireFields'
    })
    wiredRecordInfo({ data }) {
        if (data) {
            refreshApex(this.relations).then(() => {
                this.isLoaded = true;
            });
        }
    }

    @wire(getRelations, {
        recordId: '$recordId',
        objectApiName: '$objectApiName'
    })
    relations;
}
