import { LightningElement } from 'lwc';
import setStatusCompleted from '@salesforce/apex/HOT_ChatAuthController.setStatusCompleted';

export default class AuthenticationCompletedHandler extends LightningElement {
    connectedCallback() {
        const chatTranscriptId = this.getUrlParamValue(window.location.href, 'ctid');

        setStatusCompleted({ chatTranscriptId: chatTranscriptId })
            .then((result) => {
                console.log(result);
            })
            .catch((error) => {
                console.log(error);
            });

        // eslint-disable-next-line @lwc/lwc/no-async-operation, @locker/locker/distorted-window-set-timeout
        setTimeout(function () {
            window.close();
        }, 5000);
    }

    getUrlParamValue(url, key) {
        // eslint-disable-next-line compat/compat
        return new URL(url).searchParams.get(key);
    }
}