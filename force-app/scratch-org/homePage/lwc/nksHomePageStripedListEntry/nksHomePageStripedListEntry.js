import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
export default class NksHomePageStripedListEntry extends NavigationMixin(LightningElement) {
    @api record;
    @api index;
    @api lastIndex;

    recordUrl;

    connectedCallback() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.record.recordId,
                actionName: 'view'
            }
        }).then((url) => {
            this.recordUrl = url;
        });
    }

    get className() {
        let cssClass = 'slds-grid slds-var-p-horizontal_medium slds-var-p-vertical_x-small listItem';
        if (this.index % 2 === 0) {
            cssClass += ' isEven';
        }
        if (this.index === 0) {
            cssClass += ' isFirst';
        }
        if (this.index === this.lastIndex) {
            cssClass += ' isLast';
        }
        return cssClass;
    }

    navigateToPage(event) {
        event.preventDefault();
        event.stopPropagation();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.record.recordId,
                actionName: 'view'
            }
        });
    }
}
