import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getNews from '@salesforce/apex/NKS_HomePageController.getNews';
import createAuditLog from '@salesforce/apex/NKS_AuditLogController.createAuditLog';
import countViews from '@salesforce/apex/NKS_AuditLogController.countViews';
import hasPermission from '@salesforce/customPermission/NKS_Manage_News';
import { refreshApex } from '@salesforce/apex';
import AUTHOR_NAME_FIELD from '@salesforce/schema/User.NKS_FullName__c';

export default class NksHomePageNews extends LightningElement {
    @api recordId;
    @api enableRefresh = false;

    @track news;

    authorId;
    showSpinner = false;
    wiredNews;
    wiredCounter;
    title;
    author;
    publishDate;
    lastModifiedDate;
    lastUpdatedDate;
    otherAuthors;
    information;
    imageURL;
    siteURL;
    numOfViews = 0;
    isRendered = false;

    renderedCallback() {
        if (!this.isRendered) {
            this.isRendered = true;
            createAuditLog({ recordId: this.recordId, lookupField: 'Announcement__c' });
        }
    }

    @wire(getNews, {
        recordId: '$recordId'
    })
    wiredData(result) {
        this.wiredNews = result;
        this.loadNews();
    }

    @wire(countViews, {
        recordId: '$recordId',
        lookupField: 'Announcement__c'
    })
    wiredCountViews(result) {
        this.wiredCounter = result;
        this.loadCounter();
    }

    @wire(getRecord, {
        recordId: '$authorId',
        fields: [AUTHOR_NAME_FIELD]
    })
    wiredRecord({ error, data }) {
        if (error) {
            console.log(error);
        } else if (data) {
            this.author = getFieldValue(data, AUTHOR_NAME_FIELD);
        }
    }

    loadCounter() {
        const { error, data } = this.wiredCounter;
        if (data) {
            this.numOfViews = data;
        } else if (error) {
            console.log(error);
        }
    }

    loadNews() {
        const { error, data } = this.wiredNews;
        if (data) {
            this.news = data;
            if (this.news) {
                this.title = this.news.Name;
                this.authorId = this.news.NKS_News_Author__c;
                this.publishDate = this.news.NKS_News_Publish_Date__c;
                this.lastUpdatedDate = this.news.NKS_News_Update_Date__c;
                this.lastModifiedDate = this.news.LastModifiedDate;
                this.otherAuthors = this.news.NKS_News_Other_Authors__c;
                this.information = this.news.NKS_Information__c;
                this.imageURL = this.news.NKS_ImageURL__c;
            }
        }
        if (error) {
            console.log(error);
        }
    }

    refreshRecord() {
        this.showSpinner = true;
        refreshApex(this.wiredCounter).then(() => {
            this.loadCounter();
        });
        refreshApex(this.wiredNews)
            .then(() => {
                this.loadNews();
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    get hasPermission() {
        return hasPermission;
    }
}
