import { LightningElement, api, track, wire } from 'lwc';
import getThreads from '@salesforce/apex/CRM_MessageHelper.getThreadsCollection';
import createThread from '@salesforce/apex/CRM_MessageHelper.createThread';
import { refreshApex } from '@salesforce/apex';

export default class CrmMessagingMessageComponent extends LightningElement {
    showmodal = false;
    showtaskmodal = false;
    activeSectionMessage = '';
    threads;
    singlethread;
    _threadsforRefresh;
    @api recordId;
    @api singleThread;
    @api showClose;
    setCardTitle;
    hasError = false;
    @api englishTextTemplate;
    @api textTemplate; //Support for conditional text template
    @track slotsNeedCheckedOrRendered = { messages: true }; // To check the slot content the slot has to be rendered initially

    renderedCallback() {
        this.handleSlotChanges();
    }

    @wire(getThreads, { recordId: '$recordId', singleThread: '$singleThread' }) //Calls apex and extracts messages related to this record
    wiredThreads(result) {
        this._threadsforRefresh = result;

        if (result.error) {
            this.error = result.error;
            this.hasError = true;
            console.log(JSON.stringify(result.error, null, 2));
        } else if (result.data) {
            this.threads = result.data;
        }
    }
    handlenewpressed() {
        createThread({ recordId: this.recordId })
            .then((result) => {
                return refreshApex(this._threadsforRefresh);
            })
            .catch((error) => {});
    }

    get showSpinner() {
        return !this.threads && !this.hasError;
    }

    get shownewbutton() {
        return this.threads && this.threads.length === 0 && this.recordId;
    }

    get cardTitle() {
        return this.setCardTitle ?? (this.singleThread === true ? 'Samtale' : 'Samtaler');
    }

    @api
    set cardTitle(cardTitle) {
        this.setCardTitle = cardTitle;
    }

    handleEnglishEvent(event) {
        const englishEvent = new CustomEvent('englisheventtwo', {
            detail: event.detail
        });
        this.dispatchEvent(englishEvent);
    }

    // Make the component check slot content dynamically.
    // If the slot is not rendered in the DOM we have no way of checking it's content
    @api
    checkSlotChange(slotName) {
        console.log('Api call');
        console.log(slotName);
        console.log(this.slotsNeedCheckedOrRendered[slotName]);
        this.slotsNeedCheckedOrRendered[slotName] = true;
    }

    handleSlotChanges() {
        const slots = this.template.querySelectorAll('slot');
        if (!slots) return;
        const changeableSlots = Object.keys(this.slotsNeedCheckedOrRendered).filter(
            (slotValue) => this.slotsNeedCheckedOrRendered[slotValue]
        );
        changeableSlots.forEach((slotName) => {
            const slot = Array.from(slots).find((a) => a.name === slotName);
            if (!slot) return;
            const hasContent = slot.assignedElements().length !== 0;
            this.slotsNeedCheckedOrRendered[slot.name] = hasContent;
        });
    }
}
