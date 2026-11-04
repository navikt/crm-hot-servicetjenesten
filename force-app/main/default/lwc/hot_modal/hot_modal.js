import { LightningElement, api } from 'lwc';

export default class HotModal extends LightningElement {
    @api heading = '';
    @api description = '';

    renderedCallback() {
        const dialog = this.template.querySelector('dialog');

        if (!dialog.open) {
            dialog.showModal();
        }
    }

    handleClose() {
        this.template.querySelector('dialog').close();
    }

    handleCancel(event) {
        event.preventDefault();
        event.stopPropagation();
        this.handleClose();
    }

    handleClosed() {
        this.dispatchEvent(new CustomEvent('dismiss'));
    }
}
