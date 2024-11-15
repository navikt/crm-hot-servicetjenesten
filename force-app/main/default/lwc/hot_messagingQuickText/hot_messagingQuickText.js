import { LightningElement, track, api, wire } from 'lwc';
// import searchRecords from '@salesforce/apex/CRM_HenvendelseQuicktextController.searchRecords';
// import getQuicktexts from '@salesforce/apex/CRM_HenvendelseQuicktextController.getQuicktexts';
// import BLANK_ERROR from '@salesforce/label/c.CRMHenveldelse_Blank';

// const ESC_KEY_CODE = 27;
// const ESC_KEY_STRING = 'Escape';
// const TAB_KEY_CODE = 9;
// const TAB_KEY_STRING = 'Tab';
// const LIGHTNING_INPUT_FIELD = 'LIGHTNING-INPUT-FIELD';
// //all invalid key presses
// // prettier-ignore
// const keyCodes = [0, 3, 9, 13, 16, 17, 18, 19, 20, 21, 25, 27, 28, 29, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 47, 91, 92, 93, 95, 112, 113, 114, 115, 116, 117, 119, 120, 121, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 151, 166, 167, 172, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 224, 225, 230, 233, 255];
// const QUICK_TEXT_TRIGGER_KEYS = ['Enter', ' ', ','];
export default class hotQuickText extends LightningElement {
    //     labels = { BLANK_ERROR };
    //     _conversationNote;
    //     loadingData = false;
    //     qmap;
    //     initialRender = true;
    //     @api comments;
    //     @api required = false;
    //     @api resetTextTemplate = '';
    //     @track data = [];
    //     recentlyInserted = "";
    //     get textArea() {
    //         return this.template.querySelector('.conversationNoteTextArea');
    //     }
    //     renderedCallback() {
    //         if (this.initialRender === true) {
    //             let inputField = this.textArea;
    //             inputField.focus();
    //             inputField.blur();
    //             this.initialRender = false;
    //         }
    //     }
    //     /**
    //      * Functions for handling modal focus
    //      */
    //     disconnectedCallback() {
    //         document.removeEventListener('click', this.outsideClickListener);
    //     }
    //     @api
    //     isOpen() {
    //         return this.template.querySelector('[data-id="modal"]').className === 'modalShow';
    //     }
    //     toggleModal() {
    //         this.isOpen = !this.isOpen;
    //         if (this.isOpen) {
    //             this.focusFirstChild();
    //         }
    //     }
    //     get cssClass() {
    //         const baseClasses = ['slds-modal'];
    //         baseClasses.push([this.isOpen ? 'slds-visible slds-fade-in-open' : 'slds-hidden']);
    //         return baseClasses.join(' ');
    //     }
    //     get modalAriaHidden() {
    //         return !this.isOpen;
    //     }
    //     @api
    //     showModal() {
    //         this.template.querySelector('[data-id="modal"]').className = 'modalShow';
    //         this.template.querySelector('lightning-input').focus();
    //     }
    //     hideModal() {
    //         this.template.querySelector('[data-id="modal"]').className = 'modalHide';
    //     }
    //     outsideClickListener = (e) => {
    //         e.stopPropagation();
    //         if (!this.isOpen) {
    //             return;
    //         }
    //         this.toggleModal();
    //     };
    //     innerKeyUpHandler(event) {
    //         if (event.keyCode === ESC_KEY_CODE || event.code === ESC_KEY_STRING) {
    //             this.hideModal();
    //         } else if (event.keyCode === TAB_KEY_CODE || event.code === TAB_KEY_STRING) {
    //             const el = this.template.activeElement;
    //             let focusableElement;
    //             if (el.classList.contains('lastLink') || el.classList.contains('firstlink')) {
    //                 focusableElement = this._getCloseButton();
    //             }
    //             if (focusableElement) {
    //                 focusableElement.focus();
    //             }
    //         }
    //     }
    //     _getCloseButton() {
    //         let closeButton = this.template.querySelector('lightning-button-icon[title="Lukk"]');
    //         if (!closeButton) {
    //             closeButton = this.template.querySelector('lightning-button-icon');
    //         }
    //         return closeButton;
    //     }
    //     _getSlotName(element) {
    //         let slotName = element.slot;
    //         while (!slotName && element.parentElement) {
    //             slotName = this._getSlotName(element.parentElement);
    //         }
    //         return slotName;
    //     }
    //     async focusFirstChild() {
    //         const children = [...this.querySelectorAll('*')];
    //         for (let child of children) {
    //             let hasBeenFocused = false;
    //             if (this._getSlotName(child) === 'body') {
    //                 continue;
    //             }
    //             await this.setFocus(child).then((res) => {
    //                 hasBeenFocused = res;
    //             });
    //             if (hasBeenFocused) {
    //                 return;
    //             }
    //         }
    //         const closeButton = this._getCloseButton();
    //         if (closeButton) {
    //             closeButton.focus();
    //         }
    //     }
    //     setFocus(el) {
    //         return new Promise((resolve) => {
    //             if (el.disabled || (el.tagName === LIGHTNING_INPUT_FIELD && el.required)) {
    //                 return resolve(false);
    //             }
    //             const promiseListener = () => resolve(true);
    //             try {
    //                 el.addEventListener('focus', promiseListener);
    //                 el.focus && el.focus();
    //                 el.removeEventListener('focus', promiseListener);
    //                 setTimeout(() => resolve(false), 0);
    //             } catch (ex) {
    //                 return resolve(false);
    //             }
    //         });
    //     }
    //     innerClickHandler(event) {
    //         event.stopPropagation();
    //     }
    //     setFocusOnTextArea() {
    //         let inputField = this.textArea;
    //         inputField.focus();
    //     }
    //    /**
    //      * Functions for conversation note/quick text
    //      */
    //     @wire(getQuicktexts, {})
    //     wiredQuicktexts({ error, data }) {
    //         if (error) {
    //             console.log(error);
    //         } else if (data) {
    //             this.qmap = data.map((key) => {
    //                 return {
    //                     abbreviation: key.nksAbbreviationKey__c,
    //                     content: { message: key.Message, isCaseSensitive: key.Case_sensitive__c }
    //                 };
    //             });
    //         }
    //     }
    //     @api
    //     get conversationNote() {
    //         return this._conversationNote;
    //     }
    //     set conversationNote(value) {
    //         this._conversationNote = value;
    //     }
    //     @api
    //     get conversationNoteRich() {
    //         return this._conversationNote;
    //     }
    //     set conversationNoteRich(value) {
    //         this._conversationNote = value;
    //     }
    //     insertText(event) {
    //         const editor = this.textArea;
    //         editor.focus();
    //         editor.setRangeText(
    //             this.toPlainText(event.currentTarget.dataset.message),
    //             editor.selectionStart,
    //             editor.selectionEnd,
    //             'select'
    //         );
    //         this.hideModal(undefined);
    //         this._conversationNote = editor.value;
    //         const attributeChangeEvent = new CustomEvent('commentschange', {
    //             detail: this.conversationNote
    //         });
    //         this.dispatchEvent(attributeChangeEvent);
    //         const lockLang = new CustomEvent('locklang');
    //         this.dispatchEvent(lockLang);
    //     }
    //     handleChange(event) {
    //         this._conversationNote = event.target.value;
    //         const attributeChangeEvent = new CustomEvent('commentschange', {
    //             detail: this.conversationNote
    //         });
    //         this.dispatchEvent(attributeChangeEvent);
    //     }
    //     handlePaste(evt) {
    //         const editor = this.textArea;
    //         editor.setRangeText(
    //             this.toPlainText((evt.clipboardData || window.clipboardData).getData('text')),
    //             editor.selectionStart,
    //             editor.selectionEnd,
    //             'end'
    //         );
    //         evt.preventDefault();
    //     }
    //     handlePaste() {
    //         handleChange();
    //     }
    //     handleKeyUp(evt) {
    //         const queryTerm = evt.target.value;
    //         if (evt.key.length > 1 && evt.key !== 'Enter' && evt.key !== 'Backspace') {
    //             return;
    //         }
    //         if (evt.key === 'Enter' || (queryTerm.length > 2 && this.loadingData === false)) {
    //             evt.stopPropagation();
    //             this.loadingData = true;
    //             searchRecords({
    //                 search: queryTerm
    //             })
    //                 .then((result) => {
    //                     this.numberOfRows = result.length;
    //                     this.data = result;
    //                 })
    //                 .catch((error) => {
    //                     console.log(error);
    //                 })
    //                 .finally(() => {
    //                     this.loadingData = false;
    //                 });
    //         }
    //     }
    //     _getQmappedItem(abbreviation) {
    //         for (const item of this.qmap) {
    //             if (item.abbreviation.toUpperCase() !== item.content.message) {
    //                 item.abbreviation = item.abbreviation.toUpperCase();
    //                 if (item.abbreviation === abbreviation.toUpperCase()) {
    //                     return item;
    //                 }
    //             }
    //             if (item.abbreviation === abbreviation) {
    //                 return item;
    //             }
    //         }
    //     }
    //     /**
    //      * Performs text replacement and alerts screen reader
    //      */
    //     _replaceWithQuickText(editor, replacement, start, end) {
    //         editor.setRangeText(replacement, start, end, 'end');
    //         this.recentlyInserted = replacement;
    //     }
    //     insertquicktext(event) {
    //         if (!keyCodes.includes(event.keyCode)) {
    //             //to lock langBtn if a valid key is pressed
    //             const lockLang = new CustomEvent('locklang');
    //             this.dispatchEvent(lockLang);
    //         }
    //         if (QUICK_TEXT_TRIGGER_KEYS.includes(event.key)) {
    //             const editor = this.textArea;
    //             const carretPositionEnd = editor.selectionEnd;
    //             const lastItem = editor.value
    //                 .substring(0, carretPositionEnd)
    //                 .replace(/(\r\n|\n|\r)/g, ' ')
    //                 .trim()
    //                 .split(' ')
    //                 .pop();
    //             const lastWord = lastItem.replace(event.key, '');
    //             let obj = this._getQmappedItem(lastWord);
    //             if(obj !== undefined) {
    //                 const quickText = obj.content.message;
    //                 const isCaseSensitive = obj.content.isCaseSensitive;
    //                 const startindex = carretPositionEnd - lastWord.length - 1;
    //                 const lastChar = event.key === 'Enter' ? '\n' : event.key;
    //                 if (isCaseSensitive) {
    //                     const words = quickText.split(' ');
    //                     if (lastItem.charAt(0) === lastItem.charAt(0).toLowerCase()) {
    //                         words[0] = words[0].toLowerCase();
    //                         const lowerCaseQuickText = words.join(' ');
    //                         this._replaceWithQuickText(editor, lowerCaseQuickText + lastChar, startindex, carretPositionEnd);
    //                     } else if (lastItem.charAt(0) === lastItem.charAt(0).toUpperCase()) {
    //                         const upperCaseQuickText = quickText.charAt(0).toUpperCase() + quickText.slice(1);
    //                         this._replaceWithQuickText(editor, upperCaseQuickText + lastChar, startindex, carretPositionEnd);
    //                     }
    //                 } else {
    //                     this._replaceWithQuickText(editor, quickText + lastChar, startindex, carretPositionEnd);
    //                 }
    //             } else {
    //                 // Clear screen reader buffer for reading the next one.
    //                 this.recentlyInserted = '';
    //             }
    //         }
    //     }
    //     toPlainText(value) {
    //         let plainText = value ? value : '';
    //         plainText = plainText.replace(/<\/[^\s>]+>/g, '\n'); //Replaces all ending tags with newlines.
    //         plainText = plainText.replace(/<[^>]+>/g, ''); //Remove remaining html tags
    //         plainText = plainText.replace(/&nbsp;/g, ' '); //Removes &nbsp; from the html that can arise from copy-paste
    //         return plainText;
    //     }
    //     @api
    //     validate() {
    //         if (this.required === true) {
    //             return this.conversationNote && this.conversationNote.length > 0
    //                 ? { isValid: true }
    //                 : { isValid: false, errorMessage: this.labels.BLANK_ERROR }; //CUSTOM LABEL HERE
    //         }
    //         return { isValid: true };
    //     }
    //     @api
    //     clear() {
    //         //sets text content to the current
    //         this._conversationNote = this.resetTextTemplate ? this.resetTextTemplate : '';
    //         this.textArea.value = this._conversationNote;
    //     }
}
