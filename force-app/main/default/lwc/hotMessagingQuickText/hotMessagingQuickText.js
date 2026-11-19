import { LightningElement, api } from 'lwc';
import searchRecords from '@salesforce/apex/CRM_HenvendelseQuicktextController.searchContextRecords';
import getQuicktexts from '@salesforce/apex/CRM_HenvendelseQuicktextController.getContextQuicktexts';
import BLANK_ERROR from '@salesforce/label/c.CRMHenveldelse_Blank';

const ESC_KEY_CODE = 27;
const ESC_KEY_STRING = 'Escape';
const TAB_KEY_CODE = 9;
const TAB_KEY_STRING = 'Tab';
const LIGHTNING_INPUT_FIELD = 'LIGHTNING-INPUT-FIELD';
const QUICK_TEXT_TRIGGER_KEYS = ['Enter', ' ', ','];
const keyCodes = [
    0, 3, 9, 13, 16, 17, 18, 19, 20, 21, 25, 27, 28, 29, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 47, 91, 92, 93,
    95, 112, 113, 114, 115, 116, 117, 119, 120, 121, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135,
    136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 151, 166, 167, 172, 174, 175, 176, 177, 178, 179, 180, 181, 182,
    183, 224, 225, 230, 233, 255
];

export default class HotQuickText extends LightningElement {
    @api comments;
    @api required = false;
    @api resetTextTemplate = '';
    @api useForConversationNote = false;
    @api standardSignature = false;
    @api isCaseReserved = false;

    checkBoxValue = 'Standard';
    recentlyInserted = '';
    labels = { BLANK_ERROR };
    _conversationNote = '';
    qmap = [];
    _contextRecordIds = [];
    contextVersion = 0;
    searchVersion = 0;
    initialRender = true;
    loadingData = false;
    data = [];
    _isOpen = false;
    _standardSignatureText = '';

    @api
    get contextRecordIds() {
        return [...this._contextRecordIds];
    }

    set contextRecordIds(value) {
        const ids = value ? [...value] : [];
        if (JSON.stringify(ids) === JSON.stringify(this._contextRecordIds)) {
            return;
        }
        this._contextRecordIds = ids;
        this.contextVersion += 1;
        this.searchVersion += 1;
        this.qmap = [];
        this.data = [];
        this.numberOfRows = 0;
        this.loadingData = false;
        if (this.isConnected) {
            this.loadQuicktexts();
        }
    }

    connectedCallback() {
        this.loadQuicktexts();
    }

    renderedCallback() {
        this.textArea.value = this._conversationNote;
        if (this.initialRender) {
            if (this.standardSignature === true) {
                let signature = this.template.querySelector('.standardSignature');
                let noteArea = this.template.querySelector('.conversationNoteTextArea');
                noteArea.style.height = noteArea.offsetHeight - signature.offsetHeight + 'px';
            }

            this.initialRender = false;
        }
    }

    /**
     * Functions for handling modal focus
     */
    disconnectedCallback() {
        this.contextVersion += 1;
        this.searchVersion += 1;
        document.removeEventListener('click', this.outsideClickListener);
    }

    toggleModal() {
        this._isOpen = !this._isOpen;
        if (this.isOpen) {
            this.focusFirstChild();
        }
    }

    @api
    async showModal() {
        this._isOpen = true;

        await Promise.resolve();

        this.template.querySelector('lightning-input')?.focus();

        /*
        if (this.useForConversationNote) {
            publishToAmplitude('Quicktext', { type: 'Quicktext opened' });
        }*/
    }

    hideModal() {
        this._isOpen = false;
        this.template.querySelector('[data-id="modal"]').className = 'modalHide';
    }

    outsideClickListener = (e) => {
        e.stopPropagation();
        if (!this.isOpen) {
            return;
        }
        this.toggleModal();
    };

    innerKeyUpHandler(event) {
        if (event.keyCode === ESC_KEY_CODE || event.code === ESC_KEY_STRING) {
            this.hideModal();
        } else if (event.keyCode === TAB_KEY_CODE || event.code === TAB_KEY_STRING) {
            const el = this.template.activeElement;
            let focusableElement;
            if (el.classList.contains('lastLink') || el.classList.contains('firstlink')) {
                focusableElement = this._getCloseButton();
            }
            if (focusableElement) {
                focusableElement.focus();
            }
        }
    }

    _getCloseButton() {
        let closeButton = this.template.querySelector('lightning-button-icon[title="Lukk"]');
        if (!closeButton) {
            closeButton = this.template.querySelector('lightning-button-icon');
        }
        return closeButton;
    }

    _getSlotName(element) {
        let slotName = element.slot;
        while (!slotName && element.parentElement) {
            slotName = this._getSlotName(element.parentElement);
        }
        return slotName;
    }

    async focusFirstChild() {
        const children = [...this.querySelectorAll('*')];
        for (let child of children) {
            let hasBeenFocused = false;
            if (this._getSlotName(child) === 'body') {
                continue;
            }
            // eslint-disable-next-line no-await-in-loop
            await this.setFocus(child).then((res) => {
                hasBeenFocused = res;
            });
            if (hasBeenFocused) {
                return;
            }
        }
        const closeButton = this._getCloseButton();
        if (closeButton) {
            closeButton.focus();
        }
    }

    setFocus(el) {
        // eslint-disable-next-line consistent-return
        return new Promise((resolve) => {
            if (el.disabled || (el.tagName === LIGHTNING_INPUT_FIELD && el.required)) {
                return resolve(false);
            }
            const promiseListener = () => resolve(true);
            try {
                el.addEventListener('focus', promiseListener);
                el.focus();
                el.removeEventListener('focus', promiseListener);
                // eslint-disable-next-line @lwc/lwc/no-async-operation, @locker/locker/distorted-window-set-timeout
                setTimeout(() => resolve(false), 0);
            } catch (ex) {
                return resolve(false);
            }
        });
    }

    innerClickHandler(event) {
        event.stopPropagation();
    }

    setFocusOnTextArea() {
        let inputField = this.textArea;
        inputField.focus();
    }

    /**
     * Functions for conversation note/quick text
     */
    async loadQuicktexts() {
        const version = this.contextVersion;
        try {
            const data = await getQuicktexts({ contextRecordIds: this._contextRecordIds });
            if (version === this.contextVersion && this.isConnected) {
                this.qmap = data.filter((key) => key.nksAbbreviationKey__c).map((key) => ({
                    abbreviation: key.nksAbbreviationKey__c,
                    content: { message: key.Message, isCaseSensitive: key.Case_sensitive__c }
                }));
            }
        } catch (error) {
            if (version === this.contextVersion && this.isConnected) {
                this.qmap = [];
                console.error('Problem getting quick texts:', error);
            }
        }
    }

    insertText(event) {
        const editor = this.textArea;
        editor.focus();
        editor.setRangeText(
            this.toPlainText(event.currentTarget.dataset.message),
            editor.selectionStart,
            editor.selectionEnd,
            'select'
        );

        this.hideModal();
        this._conversationNote = editor.value;
        const attributeChangeEvent = new CustomEvent('commentschange', {
            detail: this.conversationNote
        });
        this.dispatchEvent(attributeChangeEvent);

        if (!this.useForConversationNote) {
            this.dispatchEvent(new CustomEvent('locklang'));
        }
    }

    handleChange(event) {
        if (this.useForConversationNote) {
            this[event.target.name] = event.target.value;
        }
        this._conversationNote = event.target.value;
        const attributeChangeEvent = new CustomEvent('commentschange', {
            detail: this.conversationNote
        });
        this.dispatchEvent(attributeChangeEvent);
    }

    handlePaste(evt) {
        const editor = this.textArea;
        editor.setRangeText(
            this.toPlainText((evt.clipboardData || window.clipboardData).getData('text')),
            editor.selectionStart,
            editor.selectionEnd,
            'end'
        );
        evt.preventDefault();
        this._conversationNote = editor.value;

        if (this.useForConversationNote) {
            evt.stopImmediatePropagation();
            const attributeChangeEvent = new CustomEvent('commentschange', {
                detail: this.conversationNote
            });
            this.dispatchEvent(attributeChangeEvent);
        }
    }

    handleKeyUp(evt) {
        const queryTerm = evt.target.value;
        if (evt.key.length > 1 && evt.key !== 'Enter' && evt.key !== 'Backspace') {
            return;
        }

        if (evt.key === 'Enter' || (queryTerm.length > 2 && this.loadingData === false)) {
            evt.stopPropagation();
            const version = ++this.searchVersion;
            this.loadingData = true;
            searchRecords({
                search: queryTerm,
                contextRecordIds: this._contextRecordIds
            })
                .then((result) => {
                    if (version === this.searchVersion && this.isConnected) {
                        this.numberOfRows = result.length;
                        this.data = result;
                    }
                })
                .catch((error) => {
                    if (version === this.searchVersion && this.isConnected) {
                        this.data = [];
                        this.numberOfRows = 0;
                        console.error('Problem searching quick texts:', error);
                    }
                })
                .finally(() => {
                    if (version === this.searchVersion && this.isConnected) {
                        this.loadingData = false;
                    }
                });
        }
    }

    handleCheckBoxChange(event) {
        let signature = this.template.querySelector('.standardSignature');
        let noteArea = this.template.querySelector('.conversationNoteTextArea');
        if (event.detail.value.includes('Standard')) {
            this.checkBoxValue = 'Standard';
            signature.classList.replace('signature-textarea-hidden', 'signature-textarea');
            noteArea.style.height = noteArea.offsetHeight - signature.offsetHeight + 'px';
        } else {
            this.checkBoxValue = 'Ingen';
            noteArea.style.height = noteArea.offsetHeight + signature.offsetHeight + 'px';
            signature.classList.replace('signature-textarea', 'signature-textarea-hidden');
        }
    }

    _getQmappedItem(abbreviation) {
        for (const item of this.qmap) {
            if (item.abbreviation.toUpperCase() !== item.content.message) {
                item.abbreviation = item.abbreviation.toUpperCase();
                if (item.abbreviation === abbreviation.toUpperCase()) {
                    return item;
                }
            }
            if (item.abbreviation === abbreviation) {
                return item;
            }
        }
        return null;
    }

    /**
     * Performs text replacement and alerts screen reader
     */
    _replaceWithQuickText(editor, replacement, start, end) {
        editor.setRangeText(replacement, start, end, 'end');
        this._conversationNote = editor.value;
        this.recentlyInserted = replacement;
    }

    insertquicktext(event) {
        if (!keyCodes.includes(event.keyCode) && !this.useForConversationNote) {
            //to lock langBtn if a valid key is pressed
            const lockLang = new CustomEvent('locklang');
            this.dispatchEvent(lockLang);
        }

        if (QUICK_TEXT_TRIGGER_KEYS.includes(event.key)) {
            const editor = this.textArea;
            const carretPositionEnd = editor.selectionEnd;
            const lastItem = editor.value
                .substring(0, carretPositionEnd)
                .replace(/(\r\n|\n|\r)/g, ' ')
                .trim()
                .split(' ')
                .pop();

            const lastWord = lastItem.replace(event.key, '');

            let obj = this._getQmappedItem(lastWord);

            if (obj != null) {
                const quickText = obj.content.message;
                const isCaseSensitive = obj.content.isCaseSensitive;
                const startindex = carretPositionEnd - lastWord.length - 1;
                const lastChar = event.key === 'Enter' ? '\n' : event.key;
                if (obj.content.message === lastWord) return;

                if (isCaseSensitive) {
                    const words = quickText.split(' ');

                    if (lastItem.charAt(0) === lastItem.charAt(0).toLowerCase()) {
                        words[0] = words[0].toLowerCase();
                        const lowerCaseQuickText = words.join(' ');
                        this._replaceWithQuickText(
                            editor,
                            lowerCaseQuickText + lastChar,
                            startindex,
                            carretPositionEnd
                        );
                    } else if (lastItem.charAt(0) === lastItem.charAt(0).toUpperCase()) {
                        const upperCaseQuickText = quickText.charAt(0).toUpperCase() + quickText.slice(1);
                        this._replaceWithQuickText(
                            editor,
                            upperCaseQuickText + lastChar,
                            startindex,
                            carretPositionEnd
                        );
                    }
                } else {
                    this._replaceWithQuickText(editor, quickText + lastChar, startindex, carretPositionEnd);
                }
            } else {
                // Clear screen reader buffer for reading the next one.
                this._conversationNote = editor.value;
                this.recentlyInserted = '';
            }
        }
    }

    toPlainText(value) {
        let plainText = value ? value : '';
        plainText = plainText.replace(/<\/[^\s>]+>/g, '\n'); //Replaces all ending tags with newlines.
        plainText = plainText.replace(/<[^>]+>/g, ''); //Remove remaining html tags
        plainText = plainText.replace(/&nbsp;/g, ' '); //Removes &nbsp; from the html that can arise from copy-paste
        return plainText;
    }

    handleCaseStatusChange() {
        this.dispatchEvent(
            new CustomEvent('setcasetoinprogress', {
                composed: true,
                bubbles: true
            })
        );
    }

    @api
    validate() {
        if (this.required) {
            return this.conversationNote && this.conversationNote.length > 0
                ? { isValid: true }
                : { isValid: false, errorMessage: this.labels.BLANK_ERROR };
        }
        return { isValid: true };
    }

    @api
    clear() {
        //sets text content to the current
        this._conversationNote = this.resetTextTemplate ? this.resetTextTemplate : '';
        this.textArea.value = this._conversationNote;
        const englishstoclearevent = new CustomEvent('englishstoclearevent');
        this.dispatchEvent(englishstoclearevent);
    }

    @api
    get isOpen() {
        return this._isOpen;
    }

    set isOpen(value) {
        this._isOpen = value;
    }

    @api
    get conversationNote() {
        return this._conversationNote;
    }

    set conversationNote(value) {
        this._conversationNote = value;
    }

    @api
    get conversationNoteRich() {
        return this._conversationNote;
    }

    set conversationNoteRich(value) {
        this._conversationNote = value;
    }
    @api
    get conversationNoteWithSignature() {
        if (this.standardSignature === true && this.checkBoxValue === 'Standard' && this.standardSignatureText !== '') {
            return this.conversationNote + '\n\n' + this.standardSignatureText;
        }
        return this.conversationNote;
    }
    set conversationNoteWithSignature(value) {
        //readonly
    }
    @api
    get standardSignatureText() {
        return this._standardSignatureText;
    }
    set standardSignatureText(value) {
        this._standardSignatureText = value;
    }
    get cssClass() {
        const baseClasses = ['slds-modal'];
        baseClasses.push([this.isOpen ? 'slds-visible slds-fade-in-open' : 'slds-hidden']);
        return baseClasses.join(' ');
    }

    get modalAriaHidden() {
        return !this.isOpen;
    }

    get textArea() {
        return this.template.querySelector('.conversationNoteTextArea');
    }

    get placeHolderText() {
        return this.useForConversationNote ? '' : 'Skriv melding her';
    }
    get checkBoxOptions() {
        return [{ label: 'Standard signatur', value: 'Standard' }];
    }
}
