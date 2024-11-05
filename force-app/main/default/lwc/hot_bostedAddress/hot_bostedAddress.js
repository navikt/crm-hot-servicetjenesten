import { LightningElement, api, wire, track } from 'lwc';
import getResidentialAddress from '@salesforce/apex/HOT_AddressController.getBostedAddress';
export default class hotBostedAddress extends LightningElement {
    @api objectApiName;
    @api recordId;
    @track sectionClass = 'slds-section section';
    @track sectionIconName = 'utility:chevronright';
    _residentialAddresses = [];
    isExpanded = false;
    ariaHidden = true;
    showCopyButton = false;

    @wire(getResidentialAddress, {
        recordId: '$recordId',
        objectApiName: '$objectApiName'
    })
    wiredAddresses({ error, data }) {
        if (data) {
            this._residentialAddresses = data;
        }
        if (error) {
            this._residentialAddresses.push('Feil under henting av bostedsadresse.');
            console.error('Problem getting residentialAddress: ' + error);
        }
    }

    get residentialAddresses() {
        if (this._residentialAddresses.length === 0) {
            return [];
        }

        this.showCopyButton = true;
        const addressesToReturn = this._residentialAddresses.map((element) => {
            const type = element.type ? 'Type: ' + element.type : '';
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

            return [type, fullName, addressLine, postInfo, region || 'NORGE NO'].join('\n').trim();
        });
        return addressesToReturn.join('\n\n').trim();
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

    copyHandler() {
        let clipboardInput = this.template.querySelector('.clipboardInput');
        clipboardInput.disabled = false;
        clipboardInput.hidden = false;
        clipboardInput.value = this.residentialAddresses;
        clipboardInput.select();
        // eslint-disable-next-line @locker/locker/distorted-document-exec-command
        document.execCommand('copy');
        clipboardInput.hidden = true;
        clipboardInput.disabled = true;
    }
}
