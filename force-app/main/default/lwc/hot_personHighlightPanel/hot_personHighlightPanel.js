import { LightningElement, api, track, wire } from 'lwc';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import { resolve } from 'c/nksComponentsUtils';

import PERSON_FIRST_NAME from '@salesforce/schema/Person__c.INT_FirstName__c';
import PERSON_IDENT_FIELD from '@salesforce/schema/Person__c.Name';
import FULL_NAME_FIELD from '@salesforce/schema/Person__c.NKS_Full_Name__c';
import NAV_ICONS from '@salesforce/resourceUrl/HOT_navIcons';

import getPersonBadgesAndInfo from '@salesforce/apex/NKS_PersonBadgesController.getPersonBadgesAndInfo';
import getHistorikk from '@salesforce/apex/NKS_FullmaktController.getHistorikk';
import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';

const PERSON_FIELDS = [PERSON_FIRST_NAME, PERSON_IDENT_FIELD, FULL_NAME_FIELD, WRITTEN_STANDARD_FIELD];

export default class NksPersonHighlightPanel extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api relationshipField;

    @track loadingStates = {
        getPersonBadgesAndInfo: true,
        getHistorikk: true,
        getRecordPerson: true
    };

    shownBadge;
    personId;
    wireFields;
    wiredBadge;
    historikkWiredData;
    isLoaded;
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

    personDetails = {};

    uuAlertText = '';

    connectedCallback() {
        this.wireFields = [`${this.objectApiName}.Id`];
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
        }
        if (error) {
            this.addErrorMessage('setWiredBadge', error);
            console.error(error);
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

    onKeyPressHandler(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            this.onClickHandler(event);
        }
    }

    onClickHandler(event) {
        const selectedBadge = event.target.dataset.id;
        const cmp = this.template.querySelector(
            `lightning-layout-item[data-id="${selectedBadge}"] c-hot_person-highlight-panel-badge-content`
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
            this.fullName = getFieldValue(data, FULL_NAME_FIELD);
            this.firstName = getFieldValue(data, PERSON_FIRST_NAME);
            this.personIdent = getFieldValue(data, PERSON_IDENT_FIELD);
            this.personDetails = {
                personId: this.personId,
                firstName: this.firstName,
                personIdent: this.personIdent,
                fullName: this.fullName
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

    get warningIconSrc() {
        return NAV_ICONS + '/warningTriangle.svg#warningTriangle';
    }

    get xMarkIconSrc() {
        return NAV_ICONS + '/xMarkIcon.svg#xMarkIcon';
    }
}
