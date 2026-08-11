import { LightningElement, api, wire } from 'lwc';
import getReadyResponse from '@salesforce/apex/HOT_HomePageController.getReadyResponses';
import hasPermission from '@salesforce/apex/HOT_HomeButtonPermission.HOT_AnnouncementPermission';

export default class Hot_homePageHighlightPanelBottom extends LightningElement {
    records = [];
    @api modalTitle = '';

    isModalOpen = false;
    currentFlow;
    hasPermission = false;

    @wire(getReadyResponse)
    wiredRecords({ error, data }) {
        if (data) {
            this.records = data.length > 0 ? data : [];
        } else if (error) {
            this.records = [];
            console.error(`There was an error fetching data: ${error.body.message}`);
        }
    }

    @wire(hasPermission)
    wiredPermission({ error, data }) {
        if (data) {
            this.hasPermission = data;
        }
        if (error) {
            this.addErrorMessage('Error Checking permission set', error);
            console.error(error);
        }
    }

    get hasRecords() {
        return this.records && this.records.length > 0;
    }

    handleFlowButton(event) {
        this.currentFlow = event.target.dataset.flow;
        this.modalTitle = `Run ${this.currentFlow}`;
        this.isModalOpen = true;

        setTimeout(() => {
            const flow = this.template.querySelector('lightning-flow');
            if (flow) {
                flow.startFlow(this.currentFlow);
            }
        }, 0);
    }

    closeModal() {
        this.isModalOpen = false;
        this.currentFlow = null;
    }

    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED' || event.detail.status === 'FINISHED_SCREEN') {
            this.closeModal();
        }
    }

    get isDisabledButtons() {
        return !this.hasPermission;
    }
}
