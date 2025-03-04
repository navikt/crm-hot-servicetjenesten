import { LightningElement, api } from 'lwc';

export default class Hot_Header extends LightningElement {
    @api input;
    @api headertag;
    @api center = false; //If true the header is centered in its container
    h1 = false;
    h2 = false;
    h3 = false;
    h4 = false;
    h5 = false;
    h6 = false;

    get headerClass() {
        let headerClass = '';
        switch (this.headertag) {
            case 'h1':
                headerClass = 'slds-text-heading_large';
                break;
            case 'h2':
                headerClass = 'slds-text-heading_medium';
                break;
            case 'h3':
                headerClass = 'slds-text-heading_small';
                break;
            case 'h4':
                headerClass = 'slds-text-title_bold slds-p-horizontal_medium';
                break;
            default:
                break;
        }

        if (this.center === true) {
            headerClass += ' slds-align_absolute-center';
        }

        return headerClass;
    }

    connectedCallback() {
        if (this.headertag === 'h1') this.h1 = true;
        if (this.headertag === 'h2') this.h2 = true;
        if (this.headertag === 'h3') this.h3 = true;
        if (this.headertag === 'h4') this.h4 = true;
        if (this.headertag === 'h5') this.h5 = true;
        if (this.headertag === 'h6') this.h6 = true;
    }
}
