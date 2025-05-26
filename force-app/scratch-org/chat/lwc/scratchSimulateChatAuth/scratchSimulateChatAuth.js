import { LightningElement } from 'lwc';
import setStatusCompleted from '@salesforce/apex/HOT_ChatAuthController.setStatusCompleted';

export default class ScratchSimulateChatAuth extends LightningElement {
    loading = false;
    errorMsg;

    initAuth() {
        let chatId = this.inputField.value;
        console.log('INIT AUTH: ' + chatId);
        if (chatId && chatId !== '') {
            this.loading = true;
            this.errorMsg = null;
            setStatusCompleted({ chatTranscriptId: chatId })
                .then((result) => {
                    console.log(result);
                })
                .catch((error) => {
                    console.log(error);
                    this.errorMsg = error.body.message;
                })
                .finally(() => {
                    this.loading = false;
                });
        }
    }

    get inputField() {
        return this.template.querySelector('lightning-input');
    }
}
