import { LightningElement, api, track, wire } from 'lwc';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import { resolve } from 'c/nksComponentsUtils';

import PERSON_ACTORID_FIELD from '@salesforce/schema/Person__c.INT_ActorId__c';
import PERSON_FIRST_NAME from '@salesforce/schema/Person__c.INT_FirstName__c';
import PERSON_IDENT_FIELD from '@salesforce/schema/Person__c.Name';
import GENDER_FIELD from '@salesforce/schema/Person__c.INT_Sex__c';
import IS_DECEASED_FIELD from '@salesforce/schema/Person__c.INT_IsDeceased__c';
import FULL_NAME_FIELD from '@salesforce/schema/Person__c.NKS_Full_Name__c';
import AGE_FIELD from '@salesforce/schema/Person__c.CRM_Age__c';
import CITIZENSHIP_FIELD from '@salesforce/schema/Person__c.INT_Citizenships__c';
import MARITAL_STATUS_FIELD from '@salesforce/schema/Person__c.INT_MaritalStatus__c';
import WRITTEN_STANDARD_FIELD from '@salesforce/schema/Person__c.INT_KrrWrittenStandard__c';
import NAV_ICONS from '@salesforce/resourceUrl/NKS_navIcons';

import getPersonBadgesAndInfo from '@salesforce/apex/NKS_PersonBadgesController.getPersonBadgesAndInfo';
import getPersonAccessBadges from '@salesforce/apex/NKS_PersonAccessBadgesController.getPersonAccessBadges';
import getHistorikk from '@salesforce/apex/NKS_FullmaktController.getHistorikk';
import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';
import getVeilederName from '@salesforce/apex/NKS_NOMController.getEmployeeName';
import getVeilederIdent from '@salesforce/apex/NKS_AktivitetsplanController.getOppfolgingsInfo';
import getArbeidssoeker from '@salesforce/apex/NKS_ArbeidssoekerController.getArbeidssoeker';

const PERSON_FIELDS = [
    PERSON_FIRST_NAME,
    PERSON_IDENT_FIELD,
    PERSON_ACTORID_FIELD,
    GENDER_FIELD,
    IS_DECEASED_FIELD,
    FULL_NAME_FIELD,
    AGE_FIELD,
    CITIZENSHIP_FIELD,
    MARITAL_STATUS_FIELD,
    WRITTEN_STANDARD_FIELD
];

export default class NksPersonHighlightPanel extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api relationshipField;

    @track loadingStates = {
        getPersonBadgesAndInfo: true,
        getPersonAccessBadges: true,
        getHistorikk: true,
        getRecordPerson: true
    };

    shownBadge;
    personId;
    wireFields;
    wiredBadge;
    historikkWiredData;
    isLoaded;
    actorId;
    veilederName;
    veilederIdent;
    fullName;
    firstName;
    personIdent;

    badges;
    dateOfDeath;
    badgeContent;
    arbeidssoekerPerioder;
    errorMessageList = {};
    errorMessages;
    erNasjonalOppfolging = false;

    oppfolgingAndMeldekortData = {};
    personDetails = {};

    uuAlertText = '';

    connectedCallback() {
        this.wireFields = [`${this.objectApiName}.Id`];
    }

    @wire(getVeilederIdent, { actorId: '$actorId' })
    wireVeilIdentInfo({ data, error }) {
        if (data) {
            this.veilederIdent = data.primaerVeileder;
            this.underOppfolging = data.underOppfolging;
            this.oppfolgingAndMeldekortData.underOppfolging = this.underOppfolging;
            this.oppfolgingAndMeldekortData.veilederIdent = this.veilederIdent;

            // When wiredPersonInfo runs, it instantly sends oppfolgingAndMeldekortData to the mid component
            // and does not resend it when this dependant wire has finished running, therefore the code below
            // is needed to send oppfolging and veilederident afterwards.
            const midPanel = this.template.querySelector('c-nks-person-highlight-panel-mid');
            if (midPanel) {
                midPanel.updateOppfolging(this.oppfolgingAndMeldekortData);
            }
            if (data.underOppfolging && data.OppfolgingsEnhet.enhetId === '4154') {
                this.erNasjonalOppfolging = true;
                this.setWiredBadge();
            }
        } else if (error) {
            this.addErrorMessage('getVeilederIdent', error);
            console.error(error);
        }
    }

    @wire(getVeilederName, { navIdent: '$veilederIdent' })
    wiredName({ data, error }) {
        if (data) {
            console.log('Geir');
            console.log(data);
            this.veilederName = data;
            this.oppfolgingAndMeldekortData.veilederName = this.veilederName;
        } else if (error) {
            console.error('Error occurred: ', JSON.stringify(error, null, 2));
        }
    }

    @wire(getPersonBadgesAndInfo, {
        field: '$relationshipField',
        parentObject: '$objectApiName',
        parentRecordId: '$recordId',
        filterOpenSTO: true
    })
    wiredBadgeInfo(value) {
        this.wiredBadge = value;
        const { data, error } = value;
        this.loadingStates.getPersonBadgesAndInfo = !(error || data);
        this.setWiredBadge();
    }

    setWiredBadge() {
        if (this.wiredBadge == null || this.historikkWiredData == null) return;
        const { data, error } = this.wiredBadge;
        const { data: historikkData } = this.historikkWiredData;

        if (data) {
            let badges = [];
            if (this.erNasjonalOppfolging) {
                badges.push({
                    name: 'NOE',
                    label: 'NOE',
                    styling: 'slds-m-left_x-small slds-m-vertical_xx-small pointer yellowBadge',
                    clickable: true,
                    tabindex: '0',
                    badgeContent: 'NOE',
                    badgeContentType: 'NOE'
                });
            }
            badges = [...badges, ...data.badges];
            if (historikkData && historikkData.length > 0) {
                badges.push({
                    name: 'historicalGuardianship',
                    label: 'Historiske fullmakter',
                    styling: 'slds-m-left_x-small slds-m-vertical_xx-small pointer greyBadge',
                    clickable: true,
                    tabindex: '0',
                    badgeContent: historikkData,
                    badgeContentType: 'historicalPowerOfAttorney'
                });
            }
            this.badges = badges;

            // this.entitlements = data.entitlements;
            if (data.errors && data.errors.length > 0) {
                this.addErrorMessage('setWiredBadge', data.errors);
            }
            this.dateOfDeath = data.dateOfDeath;
            this.setUuAlertText();
        }
        if (error) {
            this.addErrorMessage('setWiredBadge', error);
            console.error(error);
        }
    }

    @wire(getPersonAccessBadges, {
        field: '$relationshipField',
        parentObject: '$objectApiName',
        parentRecordId: '$recordId'
    })
    wiredPersonBadgeInfo(value) {
        this.wiredPersonAccessBadge = value;
        try {
            this.setWiredPersonAccessBadge();
        } catch (error) {
            console.error('There was problem to fetch data from wire-function: ' + error);
        } finally {
            this.loadingStates.getPersonAccessBadges = false;
        }
    }

    @wire(getHistorikk, {
        recordId: '$recordId',
        objectApiName: '$objectApiName'
    })
    wiredHistorikk(value) {
        this.historikkWiredData = value;
        const { data, error } = this.historikkWiredData;
        // data is null if there is no historic data
        this.loadingStates.getHistorikk = !(error || data || data === null);
        if (data) {
            this.setWiredBadge();
        } else if (error) {
            this.addErrorMessage('getHistorikk', error);
            console.error(error);
        }
    }

    setWiredPersonAccessBadge() {
        const { data, error } = this.wiredPersonAccessBadge;

        if (data) {
            this.isNavEmployee = data.some((element) => element.name === 'isNavEmployee');
            this.isConfidential = data.some((element) => element.name === 'isConfidential');
            this.personAccessBadges = data;
            this.setUuAlertText();
        } else if (error) {
            this.addErrorMessage('setWiredPersonAccessBadge', error);
            console.error(error);
        }
    }

    onKeyPressHandler(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            this.onClickHandler(event);
        }
    }

    onClickHandler(event) {
        const selectedBadge = event.target.dataset.id;
        const cmp = this.template.querySelector(
            `lightning-layout-item[data-id="${selectedBadge}"] c-nks-person-highlight-panel-badge-content`
        );
        if (cmp == null) return;
        this.handleSelectedBadge(cmp.dataset.id, selectedBadge);
    }

    handleSelectedBadge(selectedBadge, badge) {
        if (this.shownBadge === selectedBadge) {
            this.closeBadge();
            return;
        }
        this.shownBadge = selectedBadge;
        this.setExpanded(badge);
    }

    closeBadge() {
        this.shownBadge = '';
        this.setExpanded(null);
    }

    setExpanded(selectedBadge) {
        const badges = this.template.querySelectorAll('.slds-badge');
        badges.forEach((badge) => {
            if (badge instanceof HTMLElement && badge.dataset.id === selectedBadge && badge.ariaExpanded === 'false') {
                // eslint-disable-next-line @locker/locker/distorted-element-set-attribute
                badge.setAttribute('aria-expanded', 'true');
            } else if (badge.role === 'button') {
                // eslint-disable-next-line @locker/locker/distorted-element-set-attribute
                badge.setAttribute('aria-expanded', 'false');
            }
        });
    }

    getRelatedRecordId(relationshipField, objectApiName) {
        getRelatedRecord({
            parentId: this.recordId,
            relationshipField: relationshipField,
            objectApiName: objectApiName
        })
            .then((record) => {
                this.personId = resolve(relationshipField, record);
                this.oppfolgingAndMeldekortData.personId = this.personId;
            })
            .catch((error) => {
                this.addErrorMessage('getRelatedRecord', error);
                console.error(error);
            });
    }

    @wire(getRecord, {
        recordId: '$personId',
        fields: PERSON_FIELDS
    })
    wiredPersonInfo({ error, data }) {
        this.loadingStates.getRecordPerson = !(error || data);
        if (data) {
            this.actorId = getFieldValue(data, PERSON_ACTORID_FIELD);
            this.fullName = getFieldValue(data, FULL_NAME_FIELD);
            this.firstName = getFieldValue(data, PERSON_FIRST_NAME);
            this.personIdent = getFieldValue(data, PERSON_IDENT_FIELD);
            this.personDetails = {
                personId: this.personId,
                firstName: this.firstName,
                personIdent: this.personIdent,
                actorId: this.actorId,
                fullName: this.fullName,
                gender: getFieldValue(data, GENDER_FIELD),
                isDeceased: getFieldValue(data, IS_DECEASED_FIELD),
                age: getFieldValue(data, AGE_FIELD),
                writtenStandard: getFieldValue(data, WRITTEN_STANDARD_FIELD)
            };

            // this.handleBackgroundColor();
        } else if (error) {
            this.addErrorMessage('getRecord', error);
            console.error(error);
            // this.handleBackgroundColor();
        }
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$wireFields'
    })
    wiredRecordInfo({ error, data }) {
        if (data) {
            if (this.relationshipField && this.objectApiName) {
                this.getRelatedRecordId(this.relationshipField, this.objectApiName);
            }
        }
        if (error) {
            this.addErrorMessage('wiredRecordInfo', error);
            console.error(error);
        }
    }

    @wire(getArbeidssoeker, { identnr: '$personIdent' })
    wiredArbeidssoeker({ data, error }) {
        if (data) {
            this.arbeidssoekerPerioder = JSON.parse(data);
        }
        if (error) {
            this.addErrorMessage('getArbeidssoeker', error);
            console.error(error);
        }
    }

    formatMaritalStatus(str) {
        if (typeof str !== 'string') {
            return str;
        }
        return str.replace(/_/g, ' ').replace(' eller enkemann', '/-mann');
    }

    setUuAlertText() {
        const securityMeasures = this.badges?.find((badge) => badge.badgeContentType === 'SecurityMeasure');
        const hasSecurityMeasures = securityMeasures?.badgeContent.length > 0;
        if (!(hasSecurityMeasures || this.isConfidential || this.isNavEmployee)) {
            this.uuAlertText = '';
            return;
        }

        const navEmployeeText = ' er egen ansatt';
        const isConfidentialText = ' skjermet';
        let alertText = `Bruker${this.isNavEmployee ? navEmployeeText : ''}`;
        const securityMeasureText = hasSecurityMeasures
            ? ` har ${securityMeasures?.label}: ${securityMeasures?.badgeContent
                  .map((secMeasure) => secMeasure.SecurityMeasure)
                  .join(', ')}`
            : '';
        const confidentialityText =
            this.isNavEmployee && this.isConfidential ? ', og' : this.isConfidential ? ' er' : '';
        alertText += confidentialityText;
        alertText += this.isConfidential ? isConfidentialText : '';
        alertText += (this.isNavEmployee || this.isConfidential) && hasSecurityMeasures ? ' og' : '';
        alertText += securityMeasureText || '';
        alertText += '.';
        this.uuAlertText = alertText;
    }

    addErrorMessage(errorName, error) {
        if (Array.isArray(error)) {
            this.errorMessageList[errorName] = error.flat();
        } else if (typeof error === 'object') {
            this.errorMessageList[errorName] = error.body?.exceptionType + ': ' + error.body?.message;
        } else {
            this.errorMessageList[errorName] = error;
        }
        this.updateErrorMessages();
    }

    closeErrorMessage(event) {
        const errorName = event.currentTarget.dataset.errorName;
        this.closeErrorMessages(errorName);
    }

    closeErrorMessages(errorName) {
        if (Object.keys(this.errorMessageList).includes(errorName)) {
            delete this.errorMessageList[errorName];
            this.updateErrorMessages();
        }
    }

    updateErrorMessages() {
        this.errorMessages = Object.keys(this.errorMessageList).map((errorName) => {
            return { errorName: errorName, error: this.errorMessageList[errorName] };
        });
    }

    get isLoading() {
        // eslint-disable-next-line @salesforce/aura/ecma-intrinsics, compat/compat
        return Object.values(this.loadingStates).some((isLoading) => isLoading);
    }

    get panelClass() {
        return this.fullName ? 'highlightPanel' : 'highlightPanelConfidential';
    }

    get isArbeidssoeker() {
        return this.arbeidssoekerPerioder?.some((period) => period.avsluttet == null);
    }

    get warningIconSrc() {
        return NAV_ICONS + '/warningTriangle.svg#warningTriangle';
    }

    get xMarkIconSrc() {
        return NAV_ICONS + '/xMarkIcon.svg#xMarkIcon';
    }
}
