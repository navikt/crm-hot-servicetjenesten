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

    @track hjelpemiddelsentralError;
    @track bostedHjelpemiddelsentralString = '';
    @track midlertidigHjelpemiddelsentralString = '';
    @track bostedHjelpemiddelsentralUrl;
    @track midlertidigBostedHjelpemiddelsentralUrl;

    getHjelpemiddelsentraler() {
        getPersonMunicipalityAndRegions({
            recordId: this.recordId,
            objectApiName: this.objectApiName
        }).then((result) => {
            this.personMunicipalityAndRegions = result;
            if (
                // Sjekker om en person ble returnert
                !this.personMunicipalityAndRegions ||
                // OR sjekker om alle kommune/fylke felter er null
                (
                    !this.personMunicipalityAndRegions.INT_RegionNumber__c &&
                    !this.personMunicipalityAndRegions.INT_MunicipalityNumber__c &&
                    !this.personMunicipalityAndRegions.INT_TemporaryMunicipalityNumber__c
                )
            ) {
                this.hjelpemiddelsentralError =
                    'Ingen adresser registrert for å kunne finne hjelpemiddelsentral';
            }  else {
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
                                this.setBostedHjelpemiddelsentral(hjelpemiddelsentral);
                                break;
                            }
                            //Sjekker deretter på region
                            if (
                                hjelpemiddelsentral.RegionNumbers__c &&
                                hjelpemiddelsentral.RegionNumbers__c.includes(regionNumber)
                            ) {
                                this.setBostedHjelpemiddelsentral(hjelpemiddelsentral);
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
                                this.setMidlertidigBostedHjelpemiddelsentral(hjelpemiddelsentral);
                                break;
                            }
                            //Sjekker deretter på region
                            if (
                                hjelpemiddelsentral.RegionNumbers__c &&
                                hjelpemiddelsentral.RegionNumbers__c.includes(temporaryRegionNumber)
                            ) {
                                this.setMidlertidigBostedHjelpemiddelsentral(hjelpemiddelsentral);
                                break;
                            }
                        }
                    }
                });
            }
        });
    }
    setBostedHjelpemiddelsentral(hjelpemiddelsentral) {
        this.bostedHjelpemiddelsentralString = hjelpemiddelsentral.Hjelpemiddelsentral_name__c;
        this.bostedHjelpemiddelsentralUrl = hjelpemiddelsentral.NAVurl__c;
    }
    setMidlertidigBostedHjelpemiddelsentral(hjelpemiddelsentral) {
        this.midlertidigHjelpemiddelsentralString = hjelpemiddelsentral.Hjelpemiddelsentral_name__c;
        this.midlertidigBostedHjelpemiddelsentralUrl = hjelpemiddelsentral.NAVurl__c;
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
