import { LightningElement, api } from 'lwc';
import hasPermission from '@salesforce/customPermission/Manage_Traffic_Updates';
import updateNksStatus from '@salesforce/apex/NKS_HomePageController.updateNksStatus';

export default class NksHomePageHighlightPanelBadge extends LightningElement {
    @api badgeLabel;
    @api showContent = false;

    _recordId;
    _recordInfo;
    badgeClass = 'slds-badge slds-badge_centered custom-badge';
    iconClass = 'slds-icon_container custom-icon';
    iconName = 'utility:success';
    isEditing = false;
    draft;

    connectedCallback() {
        this.updateBadgeClass();
    }

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        this._recordId = value;
        if (value) {
            this.updateBadgeClass();
        }
    }

    @api
    get recordInfo() {
        return this._recordInfo;
    }

    set recordInfo(value) {
        this._recordInfo = value;
        this.draft = value;
        this.updateBadgeClass();
    }

    get ariaExpanded() {
        return this.showContent.toString();
    }

    get isEditable() {
        return hasPermission;
    }

    updateBadgeClass() {
        const baseBadgeClass = 'slds-badge slds-badge_centered custom-badge';
        const baseIconClass = 'slds-icon_container custom-icon';

        this.badgeClass = baseBadgeClass;
        this.iconClass = baseIconClass;

        if (!this.recordId) {
            this.badgeClass = `${baseBadgeClass} slds-theme_success disabled-badge`;
            this.iconClass = `${baseIconClass} slds-icon-utility-success`;
            this.iconName = 'utility:success';
        } else if (this.recordInfo) {
            this.badgeClass = `${baseBadgeClass} slds-theme_error cursor-pointer`;
            this.iconClass = `${baseIconClass} slds-icon-utility-error`;
            this.iconName = 'utility:error';
        } else {
            this.badgeClass = `${baseBadgeClass} slds-theme_success ${this.isEditable ? 'cursor-pointer' : ''}`.trim();
            this.iconClass = `${baseIconClass} slds-icon-utility-success`;
            this.iconName = 'utility:success';
        }
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
        // eslint-disable-next-line @lwc/lwc/no-async-operation, @locker/locker/distorted-window-set-timeout
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

        updateNksStatus({ fields })
            .then(() => {
                this._recordInfo = this.draft;
                this.updateBadgeClass();
                console.log('NKS status updated successfully');
            })
            .catch((error) => {
                const errorMessage = error?.body?.message || 'An unknown error occurred';
                console.error('Error updating record:', errorMessage);
            });
    }
}
