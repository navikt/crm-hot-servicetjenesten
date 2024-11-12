import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getPostAddress from '@salesforce/apex/HOT_PostAddressController.getPostAddress';

export default class hot_postAddress extends LightningElement {
    @api objectApiName;
    @api recordId;
    @track sectionClass = 'slds-section section';
    @track sectionIconName = 'utility:chevronright';
    postAddress;
    _address;
    isExpanded = false;
    ariaHidden = true;
    showbutton = false;

    connectedCallback() {
        this.wireFields = [this.objectApiName + '.Id'];
    }

    getAddress() {
        if (this._address?.data?.status !== '200' || this.postAddress === 'Ukjent adressetype.') {
            refreshApex(this._address);
        }
    }

    formattedAddress() {
        if (this._address.data.type.toUpperCase() === 'NORSKPOSTADRESSE') return this.formattedNorwegianAddress();
        if (this._address.data.type.toUpperCase() === 'UTENLANDSKPOSTADRESSE') return this.formattedForeignAddress();
        return 'Ukjent adressetype.';
    }

    formattedNorwegianAddress() {
        let addr = [];
        if (this._address.data.navn && this._address.data.navn.length > 0)
            addr.push(this._address.data.navn.toUpperCase());
        if (this._address.data.adresselinje1 && this._address.data.adresselinje1.length > 0)
            addr.push(this._address.data.adresselinje1.toUpperCase());
        if (this._address.data.adresselinje2 && this._address.data.adresselinje2.length > 0)
            addr.push(this._address.data.adresselinje2.toUpperCase());
        if (this._address.data.adresselinje3 && this._address.data.adresselinje3.length > 0)
            addr.push(this._address.data.adresselinje3.toUpperCase());
        let zipAndPlace = [];
        if (this._address.data.postummer && this._address.data.postummer.length > 0)
            zipAndPlace.push(this._address.data.postummer);
        if (this._address.data.poststed && this._address.data.poststed.length > 0)
            zipAndPlace.push(this._address.data.poststed.toUpperCase());
        if (zipAndPlace.length > 0) addr.push(zipAndPlace.join(' ').toUpperCase());
        let countryAndCode = [];
        if (this._address.data.land && this._address.data.land.length > 0)
            countryAndCode.push(this._address.data.land.toUpperCase());
        if (this._address.data.landkode && this._address.data.landkode.length > 0)
            countryAndCode.push(this._address.data.landkode.toUpperCase());
        if (countryAndCode.length > 0) addr.push(countryAndCode.join(' ').toUpperCase());
        return addr.join('\n');
    }

    formattedForeignAddress() {
        let addr = [];
        if (this._address.data.navn && this._address.data.navn.length > 0)
            addr.push(this._address.data.navn.toUpperCase());
        if (this._address.data.adresselinje1 && this._address.data.adresselinje1.length > 0)
            addr.push(this._address.data.adresselinje1.toUpperCase());
        if (this._address.data.adresselinje2 && this._address.data.adresselinje2.length > 0)
            addr.push(this._address.data.adresselinje2.toUpperCase());
        if (this._address.data.adresselinje3 && this._address.data.adresselinje3.length > 0)
            addr.push(this._address.data.adresselinje3.toUpperCase());
        let countryAndCode = [];
        if (this._address.data.land && this._address.data.land.length > 0)
            countryAndCode.push(this._address.data.land.toUpperCase());
        if (this._address.data.landkode && this._address.data.landkode.length > 0)
            countryAndCode.push(this._address.data.landkode.toUpperCase());
        if (countryAndCode.length > 0) addr.push(countryAndCode.join(' ').toUpperCase());
        return addr.join('\n');
    }

    copyHandler() {
        let clipboardInput = this.template.querySelector('.clipboardInput');
        clipboardInput.disabled = false;
        clipboardInput.hidden = false;
        clipboardInput.value = this.postAddress;
        clipboardInput.select();
        // eslint-disable-next-line @locker/locker/distorted-document-exec-command
        document.execCommand('copy');
        clipboardInput.hidden = true;
        clipboardInput.disabled = true;
    }
    @wire(getPostAddress, {
        recordId: '$recordId',
        objectApiName: '$objectApiName'
    })
    wiredAddress(value) {
        this._address = value;
        switch (this._address?.data?.status) {
            case '200':
                this.postAddress = this.formattedAddress();
                if (this.postAddress !== 'Ukjent adressetype.') this.showbutton = true;
                break;
            case '400':
                this.postAddress = 'Ugyldig input.';
                break;
            case '401':
                this.postAddress = 'Ingen tilgang til postadresse tjenesten.';
                break;
            case '404':
                this.postAddress = 'Person / organisasjon har ukjent adresse.';
                break;
            case '410':
                this.postAddress = 'Person er død og har ukjent adresse.';
                break;
            case '500':
                this.postAddress = 'Intern teknisk feil i postadresse tjenesten.';
                break;
            default:
                this.postAddress = 'Feil henting postadresse. StatusCode: ' + this._address?.data?.status;
        }
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
            this.getAddress();
        }
    }
}
