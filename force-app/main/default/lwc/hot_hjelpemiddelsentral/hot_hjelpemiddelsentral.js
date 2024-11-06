import { LightningElement, api, wire, track } from 'lwc';

export default class hotHjelpemiddelsentral extends LightningElement {
    @api objectApiName;
    @api recordId;
    @track sectionClass = 'slds-section section slds-is-open';
    // @track sectionIconName = 'utility:chevrondown';
    @track sectionIconName = '';
    isExpanded = true;
    ariaHidden = false;

    // @wire(getOppholdsAddress, {
    //     recordId: '$recordId',
    //     objectApiName: '$objectApiName'
    // })
    // wiredAddresses({ error, data }) {
    //     if (data) {
    //         this._temporaryAddresses = data;
    //     }
    //     if (error) {
    //         this._temporaryAddresses.push('Feil under henting av oppholdsadresse.');
    //         console.error('Problem getting temporaryAddress: ' + error);
    //     }
    // }

    get temporaryAddresses() {
        return 'PLACEHOLDER X HJELPEMIDDELSENTRAL';
    }

    /* Function to handle open/close section */
    // handleOpen() {
    //     if (this.sectionClass === 'slds-section section slds-is-open') {
    //         this.sectionClass = 'slds-section section';
    //         this.sectionIconName = 'utility:chevronright';
    //         this.isExpanded = false;
    //         this.ariaHidden = true;
    //     } else {
    //         this.sectionClass = 'slds-section section slds-is-open';
    //         this.sectionIconName = 'utility:chevrondown';
    //         this.isExpanded = true;
    //         this.ariaHidden = false;
    //     }
    // }
}
