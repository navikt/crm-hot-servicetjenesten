import { LightningElement, api, wire, track } from 'lwc';
import getRelatedRecord from '@salesforce/apex/HOT_RecordInfoController.getRelatedRecord';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import PERSON_IDENT_FIELD from '@salesforce/schema/Person__c.Name';
import PERSON_ACTORID_FIELD from '@salesforce/schema/Person__c.INT_ActorId__c';
import PERSON_ACCOUNT_FIELD from '@salesforce/schema/Person__c.CRM_Account__c';
import { syncActorOppgaver } from 'c/crmOppgaveSyncher';
import { resolve } from 'c/hot_componentsUtils';

const syncStatus = {
    SYNCING: 'SYNCING',
    SYNCED: 'SYNCED',
    ERROR: 'ERROR'
};

export default class hot_dataSyncher extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api relationshipField;

    @track syncStatuses = [];

    wireFields = [this.objectApiName + '.Id'];
    personId;
    personFields = [PERSON_ACTORID_FIELD, PERSON_IDENT_FIELD, PERSON_ACCOUNT_FIELD];
    initialized = false;
    synced = false;

    connectedCallback() {
        this.addSyncStatus('oppgave', 'Oppgave', syncStatus.SYNCING);
        this.getRelatedRecordId(this.relationshipField, this.objectApiName);
        this.initialized = true;
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$wireFields'
    })
    wiredRecordInfo({ error, data }) {
        if (data) {
            if (this.initialized && this.relationshipField && this.objectApiName) {
                this.getRelatedRecordId(this.relationshipField, this.objectApiName);
            }
        } else if (error) {
            console.log('Problem getting record: ', JSON.stringify(error, null, 2));
        }
    }

    @wire(getRecord, {
        recordId: '$personId',
        fields: '$personFields'
    })
    wiredPersonInfo({ error, data }) {
        if (data) {
            let personIdent = getFieldValue(data, PERSON_IDENT_FIELD);
            let personActorId = getFieldValue(data, PERSON_ACTORID_FIELD);
            let personAccountId = getFieldValue(data, PERSON_ACCOUNT_FIELD);

            if (personIdent) {
                this.doSynch(personIdent, personActorId);
            }
        }
        if (error) {
            console.log('Problem getting person information: ', JSON.stringify(error, null, 2));
        }
    }

    async doSynch(personIdent, personActorId, eventName = 'e.force:refreshView') {
        try {
            this.synced = false;
            await this.oppgaveSync(personActorId);
            this.synced = true;
            const refreshEvent = new CustomEvent(eventName);
            this.dispatchEvent(refreshEvent);
        } catch (error) {
            console.error('Problem syncing oppgave: ', JSON.stringify(error, null, 2));
        }
    }

    async oppgaveSync(personActorId) {
        try {
            const syncStatusObj = this.getSyncStatus('oppgave');
            if (syncStatusObj.status !== syncStatus.SYNCING) {
                return;
            }

            await syncActorOppgaver(personActorId);
            this.setSyncStatus('oppgave', syncStatus.SYNCED);
        } catch (error) {
            this.setSyncStatus('oppgave', syncStatus.ERROR);
            console.error('Error in oppgaveSync:', JSON.stringify(error, null, 2));
            throw new Error('Error syncing oppgave: ' + error.message);
        }
    }

    getRelatedRecordId(relationshipField, objectApiName) {
        getRelatedRecord({
            parentId: this.recordId,
            relationshipField: relationshipField,
            objectApiName: objectApiName
        })
            .then((record) => {
                let resolvedPersonId = resolve(relationshipField, record);
                if (this.personId !== resolvedPersonId) {
                    this.setSyncStatus('oppgave', syncStatus.SYNCING);
                    this.personId = resolvedPersonId;
                }
            })
            .catch((error) => {
                console.log('Problem getting related record: ', JSON.stringify(error, null, 2));
            });
    }

    addSyncStatus(name, label, status) {
        let ss = this.getSyncStatus(name);

        if (ss) {
            ss.label = label;
            ss.status = status;
        } else {
            ss = this.getNewSyncStatus(name, label, status);
            this.syncStatuses.push(ss);
        }

        this.calculateSyncStatus(ss);
    }

    getNewSyncStatus(name, label, status) {
        return {
            name: name,
            label: label,
            status: status,
            isSyncing: false,
            isSynced: false,
            isError: false
        };
    }

    setSyncStatus(name, status) {
        let ss = this.getSyncStatus(name);
        if (ss) {
            ss.status = status;
            this.calculateSyncStatus(ss);
        }
    }

    calculateSyncStatus(ss) {
        ss.isSyncing = ss.status === syncStatus.SYNCING;
        ss.isSynced = ss.status === syncStatus.SYNCED;
        ss.isError = ss.status === syncStatus.ERROR;
    }

    getSyncStatus(name) {
        return this.syncStatuses.find((element) => element.name === name);
    }
    get notSynced() {
        return !this.synced;
    }
}
