import { LightningElement, api, wire } from 'lwc';
//import getNksStatus from '@salesforce/apex/HOT_HomePageController.getNksStatus';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

export default class Hot_homePageHighlightPanelTop extends LightningElement {
    @api fagsystemTitle;
    @api navTitle;

    fagsystem;
    nav;

    fagsystemId;
    navId;
    fagsystemInfo;
    navInfo;

    showFagsystemContent = false;
    showNavContent = false;
    lastClickedBadge = '';
    isFagsystemDataLoaded = false;
    isNavDataLoaded = false;

    subscription = {};
    channelName = '/event/HOT_Home_Page_Event__e';

    wiredFagsystem;
    wiredNav;

    connectedCallback() {
        this.handleSubscribe();
        this.registerErrorListener();
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    /* @wire(getNksStatus, { title: '$fagsystemTitle' })
    handleFagsystemData(result) {
        this.wiredFagsystem = result;
        const { data, error } = result;
        if (data) {
            this.fagsystem = data;
            this.fagsystemId = data.Id;
            this.fagsystemInfo = data.NKS_Information__c;
            this.isFagsystemDataLoaded = true;
        } else if (error) {
            console.error('Error fetching fagsystem status: ', error);
        }
    }

    @wire(getNksStatus, { title: '$navTitle' })
    handleNavData(result) {
        this.wiredNav = result;
        const { data, error } = result;
        if (data) {
            this.nav = data;
            this.navId = data.Id;
            this.navInfo = data.NKS_Information__c;
            this.isNavDataLoaded = true;
        } else if (error) {
            console.error('Error fetching NAV status: ', error);
        }
    }*/

    handleBadgeClick(event) {
        const { label } = event.detail;

        if (label === this.fagsystemTitle) {
            this.toggleContent('fagsystem');
        } else if (label === this.navTitle) {
            this.toggleContent('nav');
        }
    }

    toggleContent(badgeType) {
        const isFagsystem = badgeType === 'fagsystem';
        this.showFagsystemContent = isFagsystem ? !this.showFagsystemContent : false;
        this.showNavContent = isFagsystem ? false : !this.showNavContent;
        this.lastClickedBadge = badgeType;
    }

    handleSubscribe() {
        const messageCallback = (response) => {
            console.log('New message received: ', JSON.stringify(response));
            const recordId = response.data.payload.RecordId__c;
            this.refreshData(recordId);
        };

        subscribe(this.channelName, -1, messageCallback)
            .then((response) => {
                console.log('Subscription request sent to: ', JSON.stringify(response.channel));
                this.subscription = response;
            })
            .catch((error) => {
                console.error('Subscription failed: ', error);
            });
    }

    handleUnsubscribe() {
        unsubscribe(this.subscription, (response) => {
            console.log('Unsubscribed successfully: ', JSON.stringify(response));
        });
    }

    registerErrorListener() {
        onError((error) => {
            console.error('EMP API error: ', JSON.stringify(error));
        });
    }

    refreshData(recordId) {
        if (recordId === this.fagsystemId) {
            refreshApex(this.wiredFagsystem);
        }
        if (recordId === this.navId) {
            refreshApex(this.wiredNav);
        }
    }
}
