/* eslint-disable vars-on-top */
/* eslint-disable @lwc/lwc/no-api-reassignments */
import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getRelatedRecord from '@salesforce/apex/HOT_RecordInfoController.getRelatedRecord';
import updateKrrInfo from '@salesforce/apex/HOT_KrrInformationController.updateKrrInformation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, publish, MessageContext } from 'lightning/messageService';
// import nksRefreshRecord from '@salesforce/messageChannel/nksRefreshRecord__c';
// import krrUpdateChannel from '@salesforce/messageChannel/krrUpdate__c';
import NAME from '@salesforce/schema/Person__c.Name';
import { resolve } from 'c/hot_componentsUtils';
export default class hotRecordInfo extends NavigationMixin(LightningElement) {
    @api recordId; // Id from record page (From UiRecordAPI)
    @api viewedRecordId; // Id of the record to display information for
    @api viewedObjectApiName = null; // API name of the object to display information from
    @api relationshipField = null; // Field api name if the recordId is to be set via relationship
    @api objectApiName; // Value from UiRecordAPI
    @api displayedFields = null;
    @api cardLabel;
    @api iconName; // Name of the icon to display on the format required from the icon-name attribute in lighning:card
    @api numCols = 2; // Number of columns for the displayed fields
    @api hideLabels = false; // Boolean to determine if labels is to be displayed
    _showLink = false; // Boolean to determine if action slot is to be displayed
    @api wireFields;
    @api parentWireFields;
    @api enableRefresh = false; // Enable a visual refresh button to help solve issues related to NKS-1086
    @api copyFields;
    @api showKrrInfo = false;

    showSpinner = false;
    subscription;
    hasListeners;
    isLoading = false;
    updated = false;
    personId;

    renderedCallback() {
        if (this.hasListeners || this.copyFieldsNr.length === 0 || !this.viewedObjectApiName || !this.wireRecord)
            return;
        //adding eventListeners to copy buttons
        this.fieldList
            .filter((e) => {
                return e.copyButton;
            })
            .forEach((e) => {
                let button = this.template.querySelector('div.' + e.buttonName);
                button.addEventListener(
                    'click',
                    () => {
                        this.handleCopy(e);
                    },
                    this
                );
            }, this);
        this.hasListeners = true;
    }

    disconnectedCallback() {
        //this.unsubscribeToMessageChannel();
    }

    //Lightning message service subscribe
    // subscribeToMessageChannel() {
    //     if (!this.subscription) {
    //         this.subscription = subscribe(this.messageContext, nksRefreshRecord, (message) => {
    //             let recordId = message.recordId;
    //             if (this.recordId === recordId) {
    //                 //If component is showing information in context of the updated record, update the related record id as it might have been changed
    //                 this.getRelatedRecordId(this.relationshipField, this.objectApiName);
    //             } else if (this.viewedRecordId === recordId) {
    //                 //If displaying information from the updated record -> refresh Apex
    //                 this.refreshRecord();
    //             }
    //         });
    //     }
    // }

    //Lightning message service unsubsubscribe
    // unsubscribeToMessageChannel() {
    //     unsubscribe(this.subscription);
    //     this.subscription = null;
    // }

    connectedCallback() {
        //this.subscribeToMessageChannel();
        this.viewedObjectApiName = this.viewedObjectApiName == null ? this.objectApiName : this.viewedObjectApiName;
        if (this.relationshipField != null && this.relationshipField !== '') {
            this.getRelatedRecordId(this.relationshipField, this.objectApiName);
        }
        this.viewedRecordId = this.viewedRecordId ? this.viewedRecordId : this.recordId;
        this.wireFields = [this.viewedObjectApiName + '.Id'];
        this.fieldList.forEach((e) => {
            this.wireFields.push(this.viewedObjectApiName + '.' + e.fieldName);
        }, this);
        this.parentWireFields = [this.objectApiName + '.Id'];
    }

    @api
    set showLink(value) {
        if (value === 'TRUE' || value === 'true' || value === true) {
            this._showLink = true;
        } else {
            this._showLink = false;
        }
    }

    get showLink() {
        return this._showLink;
    }

    getRelatedRecordId(relationshipField, objectApiName) {
        getRelatedRecord({
            parentId: this.recordId,
            relationshipField: relationshipField,
            objectApiName: objectApiName
        })
            .then((record) => {
                this.viewedRecordId = resolve(relationshipField, record);
                // personId
                this.personId = this.viewedObjectApiName === 'Person__c' ? this.viewedRecordId : '';
            })
            .catch((error) => {
                console.log(error);
            });
    }

    get columnWidth() {
        return 12 / this.numCols;
    }

    get recordIdSet() {
        return this.viewedRecordId != null;
    }

    get fieldList() {
        let fieldList = (this.displayedFields != null ? this.displayedFields.replace(/\s/g, '').split(',') : []).map(
            (e, i) => {
                return {
                    fieldName: e,
                    copyButton: this.copyFieldsNr.includes(i),
                    buttonName: this.viewedObjectApiName + '_' + e + '_copyButton',
                    buttonTip:
                        this.wireObjectInfo.data && this.wireObjectInfo.data.fields[e]
                            ? 'Kopier ' + this.wireObjectInfo.data.fields[e].label
                            : ''
                };
            }
        );
        return fieldList;
    }

    get copyFieldsNr() {
        let copyFieldsNr =
            this.copyFields != null
                ? this.copyFields
                      .replace(/\s/g, '')
                      .split(',')
                      .map((e) => parseInt(e, 10) - 1)
                : [];
        return copyFieldsNr;
    }

    handleCopy(field) {
        if (!this.wireRecord.data.fields[field.fieldName].value) {
            this.showCopyToast(field.fieldName, 'warning');
            return;
        }
        var hiddenInput = document.createElement('input');
        hiddenInput.value = this.wireRecord.data.fields[field.fieldName].value;
        document.body.appendChild(hiddenInput);
        hiddenInput.focus();
        hiddenInput.select();
        try {
            // eslint-disable-next-line @locker/locker/distorted-document-exec-command
            let successful = document.execCommand('copy');
            if (!successful) this.showCopyToast(field.fieldName, 'error');
        } catch (error) {
            this.showCopyToast(field.fieldName, 'error');
        }
        document.body.removeChild(hiddenInput);
        this.template.querySelector('div.' + field.buttonName).firstChild.focus();
    }

    showCopyToast(field, status) {
        const evt = new ShowToastEvent({
            message:
                status === 'success'
                    ? this.wireObjectInfo.data.fields[field].label + ' ble kopiert til utklippstavlen.'
                    : status === 'warning'
                    ? this.wireObjectInfo.data.fields[field].label + ' er tomt.'
                    : 'Kunne ikke kopiere ' + this.wireObjectInfo.data.fields[field].label,
            variant: status,
            mode: 'pester'
        });
        this.dispatchEvent(evt);
    }

    //Opens the account page on click
    navigateToRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.viewedRecordId,
                objectApiName: this.viewedObjectApiName,
                actionName: 'view'
            }
        });
    }

    @wire(MessageContext)
    messageContext;

    @wire(getObjectInfo, {
        objectApiName: '$viewedObjectApiName'
    })
    wireObjectInfo;

    @wire(getRecord, {
        recordId: '$viewedRecordId',
        fields: '$wireFields'
    })
    wireRecord;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$parentWireFields'
    })
    dewireParent() {
        //If the parent is updated, the relation might have changed and component is reinitialized
        if (this.relationshipField) {
            this.getRelatedRecordId(this.relationshipField, this.objectApiName);
        }
    }

    @wire(getRecord, {
        recordId: '$personId',
        fields: [NAME]
    })
    wiredRecord({ error, data }) {
        if (error) {
            console.log(error);
        } else if (data) {
            let personIdent = getFieldValue(data, NAME);
            if (
                this.showKrrInfo &&
                this.viewedObjectApiName === 'Person__c' &&
                personIdent !== '' &&
                personIdent !== null
            ) {
                this.updateKrrInformation(personIdent);
            }
        }
    }

    updateKrrInformation(personIdent) {
        if (this.updated === false) {
            this.isLoading = true;
            updateKrrInfo({ personIdent: personIdent })
                .then(() => {
                    this.refreshKrrInfo();
                    console.log('Successfully updated krr information');
                })
                .catch((error) => {
                    //Update failed
                    console.log('Krr informaion update failed:  ' + JSON.stringify(error, null, 2));
                })
                .finally(() => {
                    this.isLoading = false;
                    this.updated = true;
                });
        }
    }

    //Supports refreshing the record
    refreshRecord() {
        this.showSpinner = true;
        refreshApex(this.wireRecord)
            .then(() => {
                //Successful refresh
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    refreshKrrInfo() {
        this.refreshRecord();
        //publish(this.messageContext, krrUpdateChannel, { updated: true });
    }
}
