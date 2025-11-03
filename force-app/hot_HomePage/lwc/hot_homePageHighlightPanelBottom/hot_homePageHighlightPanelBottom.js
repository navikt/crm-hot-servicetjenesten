import { LightningElement, wire } from 'lwc';
import getReadyResponse from '@salesforce/apex/HOT_HomePageController.getReadyResponses';

export default class Hot_homePageHighlightPanelBottom extends LightningElement {
    records = [];

    @wire(getReadyResponse)
    wiredRecords({ error, data }) {
        if (data) {
            this.records = data.length > 0 ? data : [];
        } else if (error) {
            this.records = [];
            console.error(`There was an error fetching data: ${error.body.message}`);
        }
    }

    get hasRecords() {
        return this.records && this.records.length > 0;
    }
}
