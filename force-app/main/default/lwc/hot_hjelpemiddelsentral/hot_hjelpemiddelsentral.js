import { LightningElement, api, wire, track } from 'lwc';
import getPersonMunicipalityAndRegions from '@salesforce/apex/HOT_HjelpemiddelsentralController.getPersonMunicipalityAndRegions';
import getAllHjelpemiddelSentraler from '@salesforce/apex/HOT_HjelpemiddelsentralController.getAllHjelpemiddelSentraler';
import getBilsenter from '@salesforce/apex/HOT_HjelpemiddelsentralController.getBilsenter';
export default class hotHjelpemiddelsentral extends LightningElement {
    @api objectApiName;
    @api recordId;
    sectionClass = 'slds-section section slds-is-open';
    personMunicipalityAndRegions = [];
    allHjelpemiddelSentraler = [];
    isExpanded = true;
    ariaHidden = true;

    hjelpemiddelsentralError;
    bostedHjelpemiddelsentralString = '';
    midlertidigHjelpemiddelsentralString = '';
    bostedHjelpemiddelsentralUrl;
    midlertidigBostedHjelpemiddelsentralUrl;
    bilsenterString = '';
    bilsenterUrl = '';

    getHjelpemiddelsentralerAndBilsenter() {
        getPersonMunicipalityAndRegions({
            recordId: this.recordId,
            objectApiName: this.objectApiName
        }).then((result) => {
            this.personMunicipalityAndRegions = result;
            if (
                // Sjekker om en person ble returnert
                !this.personMunicipalityAndRegions ||
                // OR sjekker om alle kommune/fylke felter er null
                (!this.personMunicipalityAndRegions.INT_MunicipalityNumber__c &&
                    !this.personMunicipalityAndRegions.INT_TemporaryMunicipalityNumber__c)
            ) {
                this.hjelpemiddelsentralError = 'Ingen adresser registrert for å kunne finne hjelpemiddelsentral';
            } else {
                getAllHjelpemiddelSentraler({}).then((result) => {
                    this.allHjelpemiddelSentraler = result;
                    const regionNumber = this.personMunicipalityAndRegions?.INT_MunicipalityNumber__c
                        ? this.personMunicipalityAndRegions?.INT_MunicipalityNumber__c.substring(0, 2)
                        : null;
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
        getBilsenter({ accountId: this.recordId })
            .then((result) => {
                if (result) {
                    this.setBilsenter(result);
                } else {
                    this.bilsenterError = 'Ingen adresser registrert for å kunne finne bilsenter';
                }
            })
            .catch((error) => {
                this.bilsenterError = 'Det oppstet en feil ved henting av bilsenter';
            });
    }
    setBostedHjelpemiddelsentral(hjelpemiddelsentral) {
        console.log('setter bostedhjelpemiddelsentral', hjelpemiddelsentral);
        this.bostedHjelpemiddelsentralString = hjelpemiddelsentral.Hjelpemiddelsentral_name__c;
        this.bostedHjelpemiddelsentralUrl = hjelpemiddelsentral.NAVurl__c;
    }
    setMidlertidigBostedHjelpemiddelsentral(hjelpemiddelsentral) {
        this.midlertidigHjelpemiddelsentralString = hjelpemiddelsentral.Hjelpemiddelsentral_name__c;
        this.midlertidigBostedHjelpemiddelsentralUrl = hjelpemiddelsentral.NAVurl__c;
    }

    setBilsenter(result) {
        this.bilsenterString = result.Bilsenter_Navn__c;
        this.bilsenterUrl = result.Bilsenter_Url__c;
        console.log('setter bilsenter', this.bilsenterString, this.bilsenterUrl);
    }

    connectedCallback() {
        this.getHjelpemiddelsentralerAndBilsenter();
    }
}
