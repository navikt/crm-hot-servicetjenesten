import { LightningElement, api } from 'lwc';

export default class hot_relatedListItem extends LightningElement {
    @api record;
    @api usedFields;
    @api relatedObjectApiName;
    @api index;
    @api objectName;
    @api dateField;
}
