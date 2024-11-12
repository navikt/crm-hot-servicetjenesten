import { LightningElement, api, wire, track } from 'lwc';
import getPersonMunicipalityAndRegions from '@salesforce/apex/HOT_HjelpemiddelsentralController.getPersonMunicipalityAndRegions';
import getAllHjelpemiddelSentraler from '@salesforce/apex/HOT_HjelpemiddelsentralController.getAllHjelpemiddelSentraler';

export default class hotHjelpemiddelsentral extends LightningElement {
    @api objectApiName;
    @api recordId;
    @track sectionClass = 'slds-section section slds-is-open';
    personMunicipalityAndRegions = [];
    allHjelpemiddelSentraler = [];
    // @track sectionIconName = 'utility:chevrondown';
    @track sectionIconName = '';
    isExpanded = true;
    ariaHidden = false;

    @wire(getPersonMunicipalityAndRegions, {
        recordId: '$recordId',
        objectApiName: '$objectApiName'
    })
    wiredPersonData({ error, data }) {
        if (data) {
            this.personMunicipalityAndRegions = data;
            getAllHjelpemiddelSentraler({}).then((result) => {
                this.allHjelpemiddelSentraler = result;
            });
        }
        if (error) {
            this.personMunicipalityAndRegions.push('Feil under henting av persondata.');
            console.error('Problem getting data: ' + error);
        }
    }
    @track bostedHjelpemiddelsentral;
    @track midlertidigBostedHjelpemiddelsentral;

    get hjelpemiddelsentraler() {
        if (this.personMunicipalityAndRegions.length === 0) {
            return 'Ingen adresser registrert for å kunne finne hjelpemiddelsentral';
        } else {
            console.log('test');
            console.log('test1');
            const personData = this.personMunicipalityAndRegions[0];
            const regionNumber = personData?.INT_RegionNumber__c || null;
            const municipalityNumber = personData?.INT_MunicipalityNumber__c || null;
            const temporaryMunicipalityNumber = personData?.INT_TemporaryMunicipalityNumber__c || null;

            const temporaryRegionNumber = temporaryMunicipalityNumber
                ? temporaryMunicipalityNumber.substring(0, 2)
                : null;

            if (this.allHjelpemiddelSentraler && this.allHjelpemiddelSentraler.length > 0) {
                for (let hjelpemiddelsentral of this.allHjelpemiddelSentraler) {
                    //Sjekker først kommunenr
                    if (
                        hjelpemiddelsentral.MunicipalityNumbers__c &&
                        hjelpemiddelsentral.MunicipalityNumbers__c.includes(municipalityNumber)
                    ) {
                        this.bostedHjelpemiddelsentral = hjelpemiddelsentral.Hjelpemiddelsentral_name__c;
                        break;
                    }
                    //Sjekker deretter på region
                    if (
                        hjelpemiddelsentral.RegionNumbers__c &&
                        hjelpemiddelsentral.RegionNumbers__c.includes(regionNumber)
                    ) {
                        this.bostedHjelpemiddelsentral = hjelpemiddelsentral.Hjelpemiddelsentral_name__c;
                        break;
                    }
                }
            }
            if (temporaryRegionNumber) {
                for (let hjelpemiddelsentral of this.allHjelpemiddelSentraler) {
                    //Sjekker først kommunenr
                    if (
                        hjelpemiddelsentral.MunicipalityNumbers__c &&
                        hjelpemiddelsentral.MunicipalityNumbers__c.includes(temporaryMunicipalityNumber)
                    ) {
                        this.midlertidigBostedHjelpemiddelsentral = hjelpemiddelsentral.Hjelpemiddelsentral_name__c;
                        break;
                    }
                    //Sjekker deretter på region
                    if (
                        hjelpemiddelsentral.RegionNumbers__c &&
                        hjelpemiddelsentral.RegionNumbers__c.includes(temporaryRegionNumber)
                    ) {
                        this.midlertidigBostedHjelpemiddelsentral = hjelpemiddelsentral.Hjelpemiddelsentral_name__c;
                        break;
                    }
                }
            }
        }
        if (this.bostedHjelpemiddelsentral && !this.midlertidigBostedHjelpemiddelsentral) {
            return 'Tilhører ' + this.bostedHjelpemiddelsentral + ' med ordinær bostedadresse.';
        } else if (this.bostedHjelpemiddelsentral && !this.midlertidigBostedHjelpemiddelsentral) {
            return (
                'Tilhører ' +
                this.bostedHjelpemiddelsentral +
                'med ordinær bostedadresse. \nTilhører ' +
                this.midlertidigBostedHjelpemiddelsentral +
                ' med midlertidig bostedadresse.'
            );
        } else {
            return 'Noe gikk galt';
        }
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
