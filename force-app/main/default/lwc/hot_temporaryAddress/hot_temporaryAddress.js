import { LightningElement, api, wire, track } from 'lwc';
import getOppholdsAddress from '@salesforce/apex/HOT_AddressController.getOppholdsAddress';

export default class hotBostedAddress extends LightningElement {
    @api objectApiName;
    @api recordId;
    @track sectionClass = 'slds-section section';
    @track sectionIconName = 'utility:chevronright';
    _temporaryAddresses = [];
    isExpanded = false;
    ariaHidden = true;

    @wire(getOppholdsAddress, {
        recordId: '$recordId',
        objectApiName: '$objectApiName'
    })
    wiredAddresses({ error, data }) {
        if (data) {
            this._temporaryAddresses = data;
        }
        if (error) {
            this._temporaryAddresses.push('Feil under henting av oppholdsadresse.');
            console.error('Problem getting temporaryAddress: ' + error);
        }
    }

    get temporaryAddresses() {
        const addressesToReturn = this._temporaryAddresses.map((element) => {
            const fullName = element.fullName ? element.fullName : '';
            const addressLine = [
                element.address ? element.address : '',
                element.houseNumber ? ' ' + element.houseNumber : '',
                element.houseLetter ? ' ' + element.houseLetter : ''
            ]
                .join('')
                .trim();
            const postInfo = [element.zipCode ? element.zipCode : '', element.city ? ' ' + element.city : '']
                .join('')
                .trim();
            const region = [element.region ? element.region : '', element.countryCode ? ' ' + element.countryCode : '']
                .join('')
                .trim();

            return [fullName, addressLine, postInfo, region || 'NORGE NO'].join('\n').trim();
        });
        return addressesToReturn.join('\n\n').trim();
    }

    get hasRecords() {
        return this.temporaryAddresses.length > 0;
    }

    /* Function to handle open/close section */
    handleOpen() {
        if (this.sectionClass === 'slds-section section slds-is-open') {
            this.sectionClass = 'slds-section section';
            this.sectionIconName = 'utility:chevronright';
            this.isExpanded = false;
            this.ariaHidden = true;
        } else {
            this.sectionClass = 'slds-section section slds-is-open';
            this.sectionIconName = 'utility:chevrondown';
            this.isExpanded = true;
            this.ariaHidden = false;
        }
    }
}
