import { LightningElement, api } from 'lwc';
import hasPermission from '@salesforce/customPermission/HOT_Manage_Traffic_Updates';
import updateHotStatus from '@salesforce/apex/HOT_HomePageController.updateHOTStatus';

export default class Hot_homePageHighlightPanelBadge extends LightningElement {
    @api badgeLabel;
    @api showContent = false;

    _recordId;
    _recordInfo;
    isEditing = false;
    draft;

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        this._recordId = value;
    }

    @api
    get recordInfo() {
        return this._recordInfo;
    }

    set recordInfo(value) {
        this._recordInfo = value;
        this.draft = value;
    }

    get ariaExpanded() {
        return this.showContent.toString();
    }

    get isEditable() {
        return hasPermission;
    }

    get badgeClass() {
        const base = 'slds-badge slds-badge_centered custom-badge';

        if (!this.recordId) {
            return `${base} slds-theme_success disabled-badge`;
        }

        if (this.recordInfo) {
            return `${base} slds-theme_error cursor-pointer`;
        }

        return `${base} slds-theme_success ${this.isEditable ? 'cursor-pointer' : ''}`.trim();
    }

    get iconClass() {
        return `slds-icon_container custom-icon ${this.iconName === 'utility:error' ? 'slds-icon-utility-error' : 'slds-icon-utility-success'}`;
    }

    get iconName() {
        if (!this.recordId) {
            return 'utility:success';
        }

        return this.recordInfo ? 'utility:error' : 'utility:success';
    }

    get headerLineClass() {
        return this.recordInfo ? 'headerLine slds-theme_error' : 'headerLine slds-theme_success';
    }

    toggleDropdown() {
        if (!(this.recordInfo || this.isEditable)) {
            return;
        }
        this.dispatchEvent(
            new CustomEvent('badgeclick', {
                detail: { label: this.badgeLabel }
            })
        );
    }

    handleTextChange(event) {
        this.draft = event.target.value;
    }

    enableEditing() {
        this.isEditing = true;
        setTimeout(() => {
            const inputElement = this.template.querySelector('.input');
            if (inputElement) {
                inputElement.focus();
            }
        }, 0);
    }

    handleSave() {
        this.isEditing = false;
        this.updateRecord();
    }

    handleCancel() {
        this.isEditing = false;
        this.draft = this.recordInfo || '';
    }

    updateRecord() {
        if (!this.recordId) {
            console.log('Missing required data.');
            return;
        }

        const fields = {
            Id: this.recordId,
            NKS_Information__c: this.draft
        };

        updateHotStatus({ fields })
            .then(() => {
                this._recordInfo = this.draft;
                console.log('HOT status updated successfully');
            })
            .catch((error) => {
                const errorMessage = error?.body?.message || 'An unknown error occurred';
                console.error('Error updating record:', errorMessage);
            });
    }
}
