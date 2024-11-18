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

    @track bostedHjelpemiddelsentral;
    @track midlertidigBostedHjelpemiddelsentral;

    @track hjelpemiddelsentralString = '';

    getHjelpemiddelsentraler() {
        getPersonMunicipalityAndRegions({
            recordId: this.recordId,
            objectApiName: this.objectApiName
        }).then((result) => {
            this.personMunicipalityAndRegions = result;
            if (this.personMunicipalityAndRegions.length === 0) {
                this.hjelpemiddelsentralString = 'Ingen adresser registrert for å kunne finne hjelpemiddelsentral';
            } else {
                getAllHjelpemiddelSentraler({}).then((result) => {
                    this.allHjelpemiddelSentraler = result;
                    const regionNumber = this.personMunicipalityAndRegions?.INT_RegionNumber__c || null;
                    const municipalityNumber = this.personMunicipalityAndRegions?.INT_MunicipalityNumber__c || null;
                    console.log(municipalityNumber);
                    const temporaryMunicipalityNumber =
                        this.personMunicipalityAndRegions?.INT_TemporaryMunicipalityNumber__c || null;

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
                                this.hjelpemiddelsentralString =
                                    'Tilhører ' + this.bostedHjelpemiddelsentral + ' med ordinær bostedadresse.';
                                break;
                            }
                            //Sjekker deretter på region
                            if (
                                hjelpemiddelsentral.RegionNumbers__c &&
                                hjelpemiddelsentral.RegionNumbers__c.includes(regionNumber)
                            ) {
                                this.bostedHjelpemiddelsentral = hjelpemiddelsentral.Hjelpemiddelsentral_name__c;
                                this.hjelpemiddelsentralString =
                                    'Tilhører ' + this.bostedHjelpemiddelsentral + ' med ordinær bostedadresse.';
                                break;
                            }
                        }
                    }
                    if (temporaryRegionNumber) {
                        console.log('er midlertidig');
                        for (let hjelpemiddelsentral of this.allHjelpemiddelSentraler) {
                            //Sjekker først kommunenr
                            if (
                                hjelpemiddelsentral.MunicipalityNumbers__c &&
                                hjelpemiddelsentral.MunicipalityNumbers__c.includes(temporaryMunicipalityNumber)
                            ) {
                                this.midlertidigBostedHjelpemiddelsentral =
                                    hjelpemiddelsentral.Hjelpemiddelsentral_name__c;
                                this.hjelpemiddelsentralString +=
                                    '\nTilhører ' +
                                    this.midlertidigBostedHjelpemiddelsentral +
                                    ' med midlertidig bostedadresse.';
                                break;
                            }
                            //Sjekker deretter på region
                            if (
                                hjelpemiddelsentral.RegionNumbers__c &&
                                hjelpemiddelsentral.RegionNumbers__c.includes(temporaryRegionNumber)
                            ) {
                                this.midlertidigBostedHjelpemiddelsentral =
                                    hjelpemiddelsentral.Hjelpemiddelsentral_name__c;
                                this.hjelpemiddelsentralString +=
                                    '\nTilhører ' +
                                    this.midlertidigBostedHjelpemiddelsentral +
                                    ' med midlertidig bostedadresse.';
                                break;
                            }
                        }
                    }
                });
            }
        });
        if (this.hjelpemiddelsentralString == '') {
            this.hjelpemiddelsentralString = 'Kunne ikke finne hjelpemiddelsentral(er).';
        }
        return this.hjelpemiddelsentralString;
    }

    connectedCallback() {
        this.getHjelpemiddelsentraler();
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
