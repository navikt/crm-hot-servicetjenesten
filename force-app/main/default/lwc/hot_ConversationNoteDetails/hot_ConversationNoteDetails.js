import { LightningElement, api, wire } from 'lwc';
import getReverseRelatedRecord from '@salesforce/apex/HOT_RecordInfoController.getReverseRelatedRecord';
import { refreshApex } from '@salesforce/apex';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CONVERSATION_NOTE_OBJECT from '@salesforce/schema/Conversation_Note__c';
//import CHANGE_USER_LABEL from '@salesforce/label/c.NKS_Change_User';
//import CREATE_TASK_LABEL from '@salesforce/label/c.NKS_Create_NAV_Task';
import { publishToAmplitude } from 'c/amplitude';
import { handleShowNotifications, getOutputVariableValue } from 'c/hot_ComponentsUtils';
import CONVERSATION_NOTE_NOTIFICATIONS_CHANNEL from '@salesforce/messageChannel/conversationNoteNotifications__c';
import BUTTON_CONTAINER_NOTIFICATIONS_CHANNEL from '@salesforce/messageChannel/buttonContainerNotifications__c';
import { subscribe, unsubscribe, MessageContext, APPLICATION_SCOPE } from 'lightning/messageService';
import invokeSendNavTaskFlow from '@salesforce/apex/HOT_SendNavTaskHandler.invokeSendNavTaskFlow';
import getProcessingId from '@salesforce/apex/HOT_SendNavTaskHandler.getProcessingId';
import getNavUnitInfo from '@salesforce/apex/HOT_SendNavTaskHandler.getNavUnitInfo';
import getCommonCodeName from '@salesforce/apex/HOT_ButtonContainerController.getCommonCodeName';

export default class Hot_ConversationNoteDetails extends LightningElement {

    @api recordId;
    @api objectApiName;

    navTasks = [];
    notes = [];
    expanded = true;
    //changeUserLabel = CHANGE_USER_LABEL; //'Bytt bruker'
    //createTaskLabel = CREATE_TASK_LABEL; //'Opprett NAV-oppgave'
    changeUserLabel = 'Bytt bruker';
    createTaskLabel = 'Opprett NAV-oppgave';
    conversationNoteSubscription = null;
    buttonContainerSubscription = null;
    flowButtonLabel;
    flowApiName;
    _wiredRecord;

    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    @wire(MessageContext)
    messageContext;

    @wire(getObjectInfo, { objectApiName: CONVERSATION_NOTE_OBJECT })
    objectInfo;

    @wire(getReverseRelatedRecord, {
        parentId: '$recordId',
        queryFields: 'Id, CRM_Conversation_Note__c, createddate, CRM_Theme__r.Name, CRM_Theme_Group__r.Name',
        objectApiName: 'Conversation_Note__c',
        relationshipField: 'CRM_Case__c',
        ordering: 'createddate asc'
    })
    wiredData(result) {
        this._wiredRecord = result;
        const { data, error } = result;
        if (data) {
            this.notes = data.map((x) => {
                return { ...x, name: x.CRM_Theme__r ? x.CRM_Theme__r?.Name : x.CRM_Theme_Group__r?.Name };
            });
        } else if (error) {
            console.error('Error fetching reverse related records:', error);
        }
    }

    get recordLabel() {
        return this.objectInfo?.data?.label || 'Samtalereferat';
    }

    get inputVariables() {
        return [{ name: 'recordId', type: 'String', value: this.recordId }];
    }

    get reverseExpanded() {
        return !this.expanded;
    }

    get sectionClasses() {
        return `slds-section slds-var-p-horizontal_medium slds-var-p-top_small slds-m-vertical_none ${
            this.expanded ? 'slds-is-open' : ''
        }`;
    }

    get hasCNotes() {
        return this.notes != null && this.notes.length > 0;
    }

    get notificationBoxTemplate() {
        return this.template.querySelector('c-nks-notification-box');
    }

    handleShowButtons(outputVariables) {
        const hasReadAccess = getOutputVariableValue(outputVariables, 'HAS_PERSON_READ');
        const hasNoAccount = getOutputVariableValue(outputVariables, 'HAS_NO_ACCOUNT');
        this.flowButtonLabel = hasReadAccess || hasNoAccount ? this.changeUserLabel : this.createTaskLabel;
        this.flowApiName = hasReadAccess || hasNoAccount ? 'NKS_Case_Change_Account' : 'NKS_Case_Send_NAV_Task_v_2';
    }

    handleStatusChange(event) {
        const { status, outputVariables } = event.detail;
        this.handleShowButtons(outputVariables);

        if (
            status === 'FINISHED' &&
            outputVariables?.some((output) => output.objectType === 'Conversation_Note__c' && output.value !== null)
        ) {
            publishToAmplitude('Conversation Note Created');
            refreshApex(this._wiredRecord);
            handleShowNotifications('journal_conversation', outputVariables, this.notificationBoxTemplate, true);
            this.handleSendingNavTasks('navTasks', outputVariables);
        }
    }

    handleChange(event) {
        if (event.detail) {
            const { value } = event.detail;
            let message = {
                eventType: 'ThemeCategorization',
                properties: { value: value }
            };
            message.eventType +=
                value === 'GENERELL_SAK' || value === 'FAGSAK' ? ' - Sakstype endret' : ' - Theme/Gjelder changed';
            publishToAmplitude('ThemeCategorization', { value: value });
        }
    }

    handleExpandClick() {
        this.expanded = !this.expanded;
    }

    subscribeToMessageChannel() {
        if (!this.conversationNoteSubscription) {
            this.conversationNoteSubscription = subscribe(
                this.messageContext,
                CONVERSATION_NOTE_NOTIFICATIONS_CHANNEL,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }

        if (!this.buttonContainerSubscription) {
            this.buttonContainerSubscription = subscribe(
                this.messageContext,
                BUTTON_CONTAINER_NOTIFICATIONS_CHANNEL,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    unsubscribeToMessageChannel() {
        if (this.conversationNoteSubscription) {
            unsubscribe(this.conversationNoteSubscription);
            this.conversationNoteSubscription = null;
        }

        if (this.buttonContainerSubscription) {
            unsubscribe(this.buttonContainerSubscription);
            this.buttonContainerSubscription = null;
        }
    }

    handleMessage(message) {
        if (this.recordId === message.recordId) {
            handleShowNotifications(message.flowApiName, message.outputVariables, this.notificationBoxTemplate);
        }
    }

    async handleSendingNavTasks(variableName, outputVariables) {
        try {
            this.getNavTasks(variableName, outputVariables);
            await this.updateNavTasks();
            this.sendNavTasks();
        } catch (error) {
            console.error('Problem handling navTasks:', JSON.stringify(error));
        }
    }

    getNavTasks(variableName, outputVariables) {
        const variable = outputVariables.find((element) => element.name === variableName && element.value !== null);

        if (variable) {
            if (Array.isArray(variable.value)) {
                this.navTasks = variable.value;
            } else {
                console.warn('Expected an array but found a different type:', typeof variable.value);
            }
        } else {
            console.error('Variable not found or value is null:', variableName);
        }
    }

    async updateNavTasks() {
        try {
            const processingId = await getProcessingId({ recordId: this.recordId });
            const updatedNavTasks = this.navTasks.map((item) => ({
                ...item,
                NKS_Henvendelse_BehandlingsId__c: processingId
            }));
            this.navTasks = updatedNavTasks;
        } catch (error) {
            console.error('Error updating navTasks:', error);
        }
    }

    sendNavTasks() {
        this.notificationBoxTemplate.filterNotification('Oppgaven er lagret');

        this.navTasks.forEach((navTask) => {
            invokeSendNavTaskFlow({ navTask })
                .then((result) => {
                    if (result) {
                        getNavUnitInfo({ navUnitId: navTask.CRM_NavUnit__c }).then((unitInfo) => {
                            if (unitInfo) {
                                getCommonCodeName({ id: navTask.NKS_Theme__c }).then((theme) => {
                                    if (theme) {
                                        const unitNumber = unitInfo.INT_UnitNumber__c;
                                        const unitName = unitInfo.Name;
                                        const optionalText = `${theme}\xa0\xa0\xa0\xa0\xa0Sendt til: ${unitNumber} ${unitName}`;
                                        this.notificationBoxTemplate.addNotification('Oppgave opprettet', optionalText);
                                    }
                                });
                            }
                        });
                    }
                })
                .catch((error) => {
                    console.error('Problem sending NAV Task:', error);
                });
        });
    }
}
