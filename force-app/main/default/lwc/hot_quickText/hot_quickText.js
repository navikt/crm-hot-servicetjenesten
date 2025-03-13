import { LightningElement, track, api, wire } from 'lwc';
import searchRecords from '@salesforce/apex/HOT_QuickTextSearchController.searchRecords';
import getQuicktexts from '@salesforce/apex/HOT_QuickTextSearchController.getQuicktexts';
import currentUserId from '@salesforce/user/Id';
import NKS_FULL_NAME from '@salesforce/schema/User.NKS_FullName__c';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

const ESC_KEY_CODE = 27;
const ESC_KEY_STRING = 'Escape';
const TAB_KEY_CODE = 9;
const TAB_KEY_STRING = 'Tab';
const LIGHTNING_INPUT_FIELD = 'LIGHTNING-INPUT-FIELD';

const QUICK_TEXT_TRIGGER_KEYS = ['Enter', ' ', ','];
export default class hot_quickText extends LightningElement {
    /**
     * api poperties for flow lwc components. if not exist - produces errors(warnings) in debug mode
     */
    @api availableActions;
    @api screenHelpText;
    @api navigateFlow;
    _conversationNote = '';
    _isOpen = false;
    qmap;
    initialRender = true;
    loadingData = false;
    checkBoxValue = 'Standard';
    supervisorName;
    userId = currentUserId;

    @track data = [];

    @api signatureCheckbox;
    @api comments;
    @api required = false;

    recentlyInserted = '';

    get textArea() {
        return this.template.querySelector('.conversationNoteTextArea');
    }
    get checkBoxOptions() {
        return [{ label: 'Standard signatur', value: 'Standard' }];
    }
    renderedCallback() {
        if (this.initialRender === true) {
            let inputField = this.textArea;
            inputField.focus();
            inputField.blur();
            this.initialRender = false;
        }
    }

    /**
     * Functions for handling modal focus
     */
    disconnectedCallback() {
        document.removeEventListener('click', this.outsideClickListener);
    }

    @api
    get isOpen() {
        return this._isOpen;
    }
    set isOpen(value) {
        this._isOpen = value;
    }

    handleCheckBoxChange(event) {
        let signature = this.template.querySelector('.standardSignature');
        let noteArea = this.template.querySelector('.conversationNoteTextArea');
        if (event.detail.value.includes('Standard')) {
            this.checkBoxValue = 'Standard';
            signature.className = signature.className
                .split(' ')
                .filter((e) => e !== 'signature-textarea-hidden')
                .concat('signature-textarea')
                .join(' ');
            noteArea.style.height = noteArea.offsetHeight - signature.offsetHeight + 'px';
        } else {
            this.checkBoxValue = 'Ingen';
            noteArea.style.height = noteArea.offsetHeight + signature.offsetHeight + 'px';
            signature.className = signature.className
                .split(' ')
                .filter((e) => e !== 'signature-textarea')
                .concat('signature-textarea-hidden')
                .join(' ');
        }
    }

    toggleModal() {
        if (this.isOpen) {
            this.hideModal();
            this.focusFirstChild();
            return;
        }
        this.showModal();
    }

    get cssClass() {
        const baseClasses = ['slds-modal'];
        baseClasses.push([this.isOpen ? 'slds-visible slds-fade-in-open' : 'slds-hidden']);
        return baseClasses.join(' ');
    }

    get modalAriaHidden() {
        return !this.isOpen;
    }

    showModal() {
        this._isOpen = true;
        this.template.querySelector('[data-id="modal"]').className = 'modalShow';
        this.template.querySelector('lightning-input').focus();
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
            if (el.classList.contains('lastLink') || el.classList.contains('firstlink')) {
                this._getCloseButton().focus();
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
        /* eslint-disable no-await-in-loop */
        for (let child of children) {
            let hasBeenFocused = false;
            if (this._getSlotName(child) === 'body') {
                continue;
            }
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
        return new Promise((resolve) => {
            if (el.disabled || (el.tagName === LIGHTNING_INPUT_FIELD && el.required)) {
                return resolve(false);
            }
            const promiseListener = () => resolve(true);
            try {
                el.addEventListener('focus', promiseListener);
                el.focus();
                el.removeEventListener('focus', promiseListener);
                setTimeout(() => resolve(false), 0);
            } catch (ex) {
                return resolve(false);
            }
            return resolve(false);
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
    @wire(getQuicktexts, {})
    wiredQuicktexts({ error, data }) {
        if (error) {
            console.log(error);
        } else if (data) {
            this.qmap = data.map((key) => {
                return {
                    abbreviation: key.nksAbbreviationKey__c,
                    content: { message: key.Message, isCaseSensitive: key.Case_sensitive__c }
                };
            });
        }
    }

    @wire(getRecord, {
        recordId: '$userId',
        fields: [NKS_FULL_NAME]
    })
    wiredUser({ error, data }) {
        if (error) {
            console.error('wiredUser failed: ', error);
        } else if (data) {
            this.supervisorName = getFieldValue(data, NKS_FULL_NAME);
        }
    }

    get standardSignature() {
        let regards = 'Med vennlig hilsen';
        return `${regards}\n${this.supervisorName}\nServicetjenesten Nav hjelpemidler og tilrettelegging`;
    }

    @api get conversationNote() {
        if (this.checkBoxValue === 'Standard') {
            return this._conversationNote + '\n\n' + this.standardSignature;
        }
        return this._conversationNote;
    }

    set conversationNote(value) {
        //skip as readonly
    }
    get conversationNoteTextArea() {
        return this._conversationNote;
    }

    set conversationNoteTextArea(value) {
        this._conversationNote = value;
    }

    @api get conversationNoteRich() {
        return this._conversationNote;
    }

    set conversationNoteRich(value) {
        this._conversationNote = value;
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
        evt.stopImmediatePropagation();

        this._conversationNote = editor.value;
    }

    handleKeyUp(evt) {
        const queryTerm = evt.target.value;

        if (evt.key.length > 1 && evt.key !== 'Enter') {
            return;
        }

        if (evt.key === 'Enter' || (queryTerm.length > 2 && this.loadingData === false)) {
            this.loadingData = true;
            searchRecords({
                search: queryTerm
            })
                .then((result) => {
                    this.numberOfRows = result.length;
                    this.data = result;
                })
                .catch((error) => {
                    console.log(error);
                })
                .finally(() => {
                    this.loadingData = false;
                });
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

        this.hideModal(undefined);
        this._conversationNote = editor.value;
    }

    handleChange(event) {
        this[event.target.name] = event.target.value;
        this._conversationNote = event.target.value;
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
        this.recentlyInserted = replacement;
    }

    insertquicktext(event) {
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

    @api
    validate() {
        if (this.required === true) {
            return this.conversationNoteTextArea && this.conversationNoteTextArea.length > 0
                ? { isValid: true }
                : { isValid: false, errorMessage: '	Samtalereferatet kan ikke være tomt!' };
        }
        return { isValid: true };
    }
}
