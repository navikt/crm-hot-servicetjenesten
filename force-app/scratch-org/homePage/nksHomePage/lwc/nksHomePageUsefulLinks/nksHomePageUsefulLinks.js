import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getReadyResponse from '@salesforce/apex/NKS_HomePageController.getReadyResponses';

export default class NksHomePageUsefulLinks extends NavigationMixin(LightningElement) {
    @track records = [];

    className;
    showReadyResponse = false;

    @wire(getReadyResponse) wiredRecords({ error, data }) {
        if (data) {
            this.records = data;
            this.checkResult();
        } else if (error) {
            console.log(`Det har oppstått en feil ved å hente svarberedskaper: ${error}`);
        }
    }

    checkResult() {
        if (this.records == null) {
            this.showReadyResponse = false;
            this.className = 'slds-size_12-of-12';
        } else {
            this.showReadyResponse = true;
            this.className = 'slds-size_7-of-12 slds-var-p-left_large';
        }
    }

    navigateToKnowledge() {
        this[NavigationMixin.Navigate]({
            type: 'standard__knowledgeArticlePage',
            attributes: {
                actionName: 'view',
                articleType: 'Knowledge',
                urlName: encodeURIComponent('Felles-Trussel-trakassering-og-sjikane')
            }
        });
    }
}
