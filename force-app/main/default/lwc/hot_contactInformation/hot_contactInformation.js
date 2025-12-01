import { LightningElement, api, wire } from 'lwc';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import { resolve } from 'c/hot_componentsUtils';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import LoggerUtility from 'c/loggerUtility';
import EMAIL_FIELD from '@salesforce/schema/Person__c.INT_KrrEmail__c';
import PHONE_FIELD from '@salesforce/schema/Person__c.INT_KrrMobilePhone__c';
import PHONE_1_FIELD from '@salesforce/schema/Person__c.INT_Phone1__c';
import PHONE_2_FIELD from '@salesforce/schema/Person__c.INT_Phone2__c';
import KRR_RESERVATION_FIELD from '@salesforce/schema/Person__c.INT_KRR_Reservation__c';
import KRR_VERIFIED_FIELD from '@salesforce/schema/Person__c.INT_VerifiedFromKRR__c';
import PDL_LAST_UPDATED_FIELD from '@salesforce/schema/Person__c.INT_LastUpdatedFromPDL__c';
import KRR_LAST_UPDATED_FIELD from '@salesforce/schema/Person__c.INT_LastUpdatedFromKRR__c';
import NAME_FIELD from '@salesforce/schema/Person__c.Name';
import DATA_SYNC_CHANNEL from '@salesforce/messageChannel/hotDataSyncChannel__c';
import getRelatedRecord from '@salesforce/apex/HOT_RecordInfoController.getRelatedRecord';
import updateKrrInfo from '@salesforce/apex/HOT_KrrInformationController.updateKrrInformation';

const LABELS = {
    mobile: 'Mobilnummer',
    phoneFromNav: 'Telefon fra nav.no'
};

const PERSON_CONTACT_FIELDS = [
    EMAIL_FIELD,
    PHONE_FIELD,
    PHONE_1_FIELD,
    PHONE_2_FIELD,
    KRR_RESERVATION_FIELD,
    KRR_VERIFIED_FIELD,
    KRR_LAST_UPDATED_FIELD,
    PDL_LAST_UPDATED_FIELD,
    NAME_FIELD
];

export default class Hot_contactInformation extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api relationshipField;

    email;
    phone;
    phone1;
    phone2;
    krrReservation;
    krrVerified;
    krrLastUpdated;
    pdlLastUpdated;
    personId;
    personIdent;
    wiredPersonInfoResult;
    errorMessage;
    isError = false;
    isLoading = true;
    updated = false;

    subscription = null;

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(this.messageContext, DATA_SYNC_CHANNEL, (message) =>
                this.handleMessage(message)
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    handleMessage(message) {
        if (message.status === 'SYNC_COMPLETE') {
            refreshApex(this.wiredPersonInfoResult);
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
            this.handleError(error);
            console.error(error);
            this.isLoading = false;
        }
    }

    @wire(getRecord, {
        recordId: '$personId',
        fields: PERSON_CONTACT_FIELDS
    })
    wiredPersonInfo(result) {
        this.wiredPersonInfoResult = result;
        if (result?.data) {
            this.populatePersonFields(result.data);
            this.isLoading = false;
        } else if (result?.error) {
            this.handleError(result.error);
            console.error(result.error);
            this.isLoading = false;
        }
    }

    populatePersonFields(data) {
        this.personIdent = getFieldValue(data, NAME_FIELD);
        if (this.personIdent) {
            this.updateKrrInformation(this.personIdent);
        }
        this.email = getFieldValue(data, EMAIL_FIELD);
        this.phone = getFieldValue(data, PHONE_FIELD);
        this.phone1 = getFieldValue(data, PHONE_1_FIELD);
        this.phone2 = getFieldValue(data, PHONE_2_FIELD);
        this.krrReservation = getFieldValue(data, KRR_RESERVATION_FIELD);
        this.krrVerified = getFieldValue(data, KRR_VERIFIED_FIELD);
        this.krrLastUpdated = getFieldValue(data, KRR_LAST_UPDATED_FIELD);
        this.pdlLastUpdated = getFieldValue(data, PDL_LAST_UPDATED_FIELD);
    }

    getRelatedRecordId(relationshipField, objectApiName) {
        getRelatedRecord({
            parentId: this.recordId,
            relationshipField: relationshipField,
            objectApiName: objectApiName
        })
            .then((record) => {
                if (!record) {
                    LoggerUtility.logError(
                        'HOT',
                        'ContactInformation',
                        null,
                        'No related record found for relationshipField: ' + relationshipField,
                        ' and objectApiName: ' + objectApiName,
                        this.recordId
                    );
                }
                this.personId = resolve(relationshipField, record);
                refreshApex(this.wiredPersonInfoResult); // In case wiredPersonInfo is cached to empty values before getRelatedRecord is finished
            })
            .catch((error) => {
                LoggerUtility.logError('HOT', 'ContactInformation', error, 'Error on getRelatedRecord', this.recordId);
                this.handleError(error);
                console.error(error);
                this.isLoading = false;
            });
    }

    updateKrrInformation(personIdent) {
        if (this.updated === false) {
            this.isLoading = true;
            updateKrrInfo({ personIdent: personIdent })
                .then(() => {
                    this.refreshRecord();
                    console.log('Successfully updated krr information');
                })
                .catch((error) => {
                    console.log('Krr informaion update failed:  ' + JSON.stringify(error, null, 2));
                })
                .finally(() => {
                    this.isLoading = false;
                    this.updated = true;
                });
        }
    }

    refreshRecord() {
        this.isLoading = true;
        refreshApex(this.wiredPersonInfoResult)
            .then(() => {
                //Successful refresh
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleError(error) {
        this.errorMessage = 'Unknown error';
        if (Array.isArray(error.body)) {
            this.errorMessage = error.body.map((e) => e.message).join(', ');
        } else if (typeof error.body.message === 'string') {
            this.errorMessage = error.body.message;
        }
        this.isError = true;
    }

    getFormattedPhone(phone, label) {
        return phone ? `${label}: ${phone}` : '';
    }

    handleCopyPhone(event) {
        const phoneNumber = this.removeCountryCode(event.target.dataset.phone);

        let hiddenInput = document.createElement('input');
        let successful = false;
        let msg = '';
        hiddenInput.value = phoneNumber;
        document.body.appendChild(hiddenInput);
        hiddenInput.select();
        try {
            // eslint-disable-next-line @locker/locker/distorted-document-exec-command
            successful = document.execCommand('copy');
            msg = successful ? 'successful' : 'unsuccessful';
            console.error('Copying text command was ', msg);
        } catch (err) {
            console.error('Oops, unable to copy: ', err);
        }
        document.body.removeChild(hiddenInput);
    }

    removeCountryCode(phoneNumber) {
        if (phoneNumber?.startsWith('+47') && phoneNumber.length > 2) {
            return phoneNumber.replace(/^\+47/, '');
        }
        return phoneNumber;
    }

    get formattedPhone() {
        return this.getFormattedPhone(this.phone, LABELS.mobile);
    }

    get formattedPhone1() {
        return this.getFormattedPhone(this.phone1, LABELS.phoneFromNav);
    }

    get formattedPhone2() {
        return this.getFormattedPhone(this.phone2, LABELS.phoneFromNav);
    }

    get fancyError() {
        return JSON.stringify(this.errorMessage);
    }

    get krrReservationTranslation() {
        return this.krrReservation ? 'Ja' : 'Nei';
    }

    get krrLastUpdatedFormatted() {
        return this.formatSystemDate(this.krrLastUpdated, 'KRR');
    }

    get pdlLastUpdatedFormatted() {
        return this.formatSystemDate(this.pdlLastUpdated, 'PDL - Folkeregisteret');
    }

    get wireFields() {
        return this.objectApiName ? [`${this.objectApiName}.Id`] : [];
    }

    formatSystemDate(updatedDate, sourceSystem) {
        if (!updatedDate) {
            return '';
        }
        const date = new Date(updatedDate);
        const formatter = new Intl.DateTimeFormat('nb-NO', {
            day: 'numeric',
            month: 'long',
            year: 'numeric'
        });
        const formattedSourceSystem = sourceSystem;

        return `Oppdatert ${formatter.format(date)} av ${formattedSourceSystem}`;
    }
}
