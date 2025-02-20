import { LightningElement, api, wire } from 'lwc';
//import crmSingleValueUpdate from '@salesforce/messageChannel/crmSingleValueUpdate__c';
import { publish, MessageContext } from 'lightning/messageService';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

//#### LABEL IMPORTS ####
//import VALIDATION_ERROR from '@salesforce/label/c.NKS_Single_Record_Input_Validation_Error';

export default class HotSingleRecordInputField extends LightningElement {
    //FIELD PARAMS
    @api dirty;
    @api disabled;
    @api fieldName;
    @api readOnly;
    @api required;
    @api value = null;
    @api variant;

    //OBJECT PARAMS
    @api density;
    @api objectApiName;
    @api recordId;
    @api recordTypeId;

    @wire(MessageContext)
    messageContext;

    VALIDATION_ERROR = 'Vennligst fyll ut feltet';

    connectedCallback() {
        const payload = { name: this.fieldName, value: this.value };
        publish(this.messageContext, crmSingleValueUpdate, payload);
    }

    onChange(event) {
        if (event.detail.value.length === 0) {
            this.value = null;
        } else {
            this.value = event.detail.value;
        }
        this.dispatchEvent(new FlowAttributeChangeEvent('value', this.value));
        const payload = { name: this.fieldName, value: this.value };
        publish(this.messageContext, crmSingleValueUpdate, payload);
    }

    //Validation preventing user moving to next screen in flow if state is not valid
    @api
    validate() {
        //Theme and theme group must be set
        if (true === this.required && this.value) {
            return { isValid: true };
        }
        return {
            isValid: false,
            errorMessage: VALIDATION_ERROR
        };
    }
}
