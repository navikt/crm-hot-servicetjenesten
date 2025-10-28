import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

export default class HotKnowledgeFieldViewer extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api fieldName = 'ArticleBody';

    fieldValue;

    @wire(getRecord, { recordId: '$recordId', fields: '$fieldList' })
    wiredRecord({ data }) {
        if (!data) {
            this.fieldValue = undefined;
            return;
        }

        const field = this.fieldApiName;
        this.fieldValue = field ? data.fields?.[field]?.value : undefined;
    }

    get fieldList() {
        if (!this.fieldName) {
            return [];
        }
        if (this.fieldName.includes('.')) {
            return [this.fieldName];
        }
        if (!this.objectApiName) {
            return [];
        }
        return [`${this.objectApiName}.${this.fieldName}`];
    }

    get fieldApiName() {
        if (!this.fieldName) {
            return undefined;
        }
        const parts = this.fieldName.split('.');
        return parts[parts.length - 1];
    }
}
