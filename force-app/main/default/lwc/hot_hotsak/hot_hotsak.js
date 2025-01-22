import { LightningElement, wire } from 'lwc';
import getSaker from '@salesforce/apex/HOT_HotsakIntegrationController.getSaker';

export default class hot_hotsak extends LightningElement {
    fnrValue = '15084300133';
    saker;

    @wire(getSaker, { fnr: '$fnrValue' })
    wiredSaker({ data, error }) {
        if (data) {
            console.log('Saker data: ', data);
            this.saker = data; // lagre i `saker`
        } else if (error) {
            console.error('Saker error: ', error);
            this.saker = undefined;
        }
    }
}
