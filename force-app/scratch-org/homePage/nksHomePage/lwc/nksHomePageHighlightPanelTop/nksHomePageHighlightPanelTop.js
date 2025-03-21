import { LightningElement, api, wire } from 'lwc';
import getNksStatus from '@salesforce/apex/NKS_HomePageController.getNksStatus';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

export default class NksHomePageHighlightPanelTop extends LightningElement {
    @api fagsystemTitle;
    @api navTitle;

    fagsystem;
    nav;

    _fagsystemId;
    _fagsystemInfo;
    _navId;
    _navInfo;

    showFagsystemContent = false;
    showNavContent = false;
    lastClickedBadge = '';
    isFagsystemDataLoaded = false;
    isNavDataLoaded = false;

    subscription = {};
    channelName = '/event/NKS_Home_Page_Event__e';

    wiredFagsystem;
    wiredNav;

    connectedCallback() {
        this.handleSubscribe();
        this.registerErrorListener();
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    @api
    get fagsystemId() {
        return this._fagsystemId;
    }

    set fagsystemId(value) {
        this._fagsystemId = value;
    }

    @api
    get fagsystemInfo() {
        return this._fagsystemInfo;
    }

    set fagsystemInfo(value) {
        this._fagsystemInfo = value;
    }

    @api
    get navId() {
        return this._navId;
    }

    set navId(value) {
        this._navId = value;
    }

    @api
    get navInfo() {
        return this._navInfo;
    }

    set navInfo(value) {
        this._navInfo = value;
    }

    @wire(getNksStatus, { title: '$fagsystemTitle' })
    handleFagsystemData(result) {
        this.wiredFagsystem = result;
        const { data, error } = result;
        if (data) {
            this.fagsystem = data;
            this._fagsystemId = data.Id;
            this._fagsystemInfo = data.NKS_Information__c;
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
            this._navId = data.Id;
            this._navInfo = data.NKS_Information__c;
            this.isNavDataLoaded = true;
        } else if (error) {
            console.error('Error fetching NAV status: ', error);
        }
    }

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
