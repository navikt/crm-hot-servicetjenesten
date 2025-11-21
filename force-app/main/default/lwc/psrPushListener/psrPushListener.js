import { LightningElement } from 'lwc';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import PSRController from '@salesforce/apex/PSREventController.PSREventController';

export default class PsrPushListener extends LightningElement {
    channel = '/topic/PSRPushTopic';
    subscription = {};
    status = 'Not connected';
    latestEvent;

    connectedCallback() {
        this.handleSubscribe();
        this.registerErrorListener();
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    handleSubscribe() {
        const messageCallback = (response) => {
            console.log('New PSR event received: ', JSON.stringify(response));
            this.latestEvent = JSON.stringify(response, null, 2);
            this.status = 'Event received!';

            PSRController({ responseJson: JSON.stringify(response) })
                .then((result) => {
                    console.log('Apex callout result:', result);
                })
                .catch((error) => {
                    console.error('Apex error:', error);
                });
        };

        subscribe(this.channel, -1, messageCallback).then((response) => {
            console.log('Subscribed to channel: ', JSON.stringify(response));
            this.subscription = response;
            this.status = 'Connected & Listening';
        });

        processEvent({ responseJson: JSON.stringify(response) })
            .then((result) => {
                console.log('Apex callout result:', result);
            })
            .catch((error) => {
                console.error('Apex error:', error);
            });
    }

    handleUnsubscribe() {
        if (this.subscription && this.subscription.id) {
            unsubscribe(this.subscription, (response) => {
                console.log('Unsubscribed: ', JSON.stringify(response));
                this.status = 'Unsubscribed';
            });
        }
    }

    registerErrorListener() {
        onError((error) => {
            console.error('EMP API error: ', JSON.stringify(error));
            this.status = 'Error — check logs';
        });
    }
}
