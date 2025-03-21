import { LightningElement, api, wire } from 'lwc';
import getList from '@salesforce/apex/NKS_HomePageController.getList';
import getKnowledgeList from '@salesforce/apex/NKS_HomePageController.getKnowledgeList';
import getCaseList from '@salesforce/apex/NKS_HomePageController.getCaseList';
import getAnnouncementList from '@salesforce/apex/NKS_HomePageController.getAnnouncementList';
import getUserSkills from '@salesforce/apex/NKS_HomePageController.getUserSkills';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe, onError } from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import userId from '@salesforce/user/Id';

export default class nksHomePageList extends NavigationMixin(LightningElement) {
    @api cardLabel = 'Title';
    @api iconName = '';
    @api title = 'Name';
    @api content = '';
    @api objectName = 'NKS_Announcement__c';
    @api orderby = '';
    @api limit = 10;
    @api listviewname = 'Recent';
    @api linklabel = 'Vis alle';
    @api datefield = 'CreatedDate';
    @api showimage = false;
    @api filterbyskills = false;
    @api refreshPageAutomatically = false;
    @api enableRefresh = false;
    @api filter = "Name = 'Navn'";

    records = [];
    userSkills = [];
    showSpinner = false;
    channelName = '/topic/Announcement_Updates';
    subscription = {};
    pageurl;
    isRefreshDisabled = false;

    connectedCallback() {
        this.showSpinner = true;
        this.setWireParameters();
        if (this.isSTO || this.objectName === 'LiveChatTranscript') {
            this.filter += " AND OwnerId='" + userId + "'";
        }
        if (this.filterbyskills) {
            this.fetchUserSkills();
        }
        this.generateListUrl();
        this.setupEmpSubscription();
    }

    objectNameForCase;
    objectNameForAnnouncement;
    objectNameForKnowledge;
    objectNameForGeneral;
    // Prevent all wires from running by keeping 1 param undefined
    setWireParameters() {
        this.objectNameForCase = this.objectName === 'Case' ? this.objectName : undefined;
        this.objectNameForAnnouncement = this.objectName === 'NKS_Announcement__c' ? this.objectName : undefined;
        this.objectNameForKnowledge = this.objectName === 'Knowledge__kav' ? this.objectName : undefined;
        this.objectNameForGeneral = this.objectName === 'General' ? this.objectName : undefined;
    }

    fetchUserSkills() {
        getUserSkills()
            .then((data) => {
                this.userSkills = data;
            })
            .catch((error) => {
                this.handleError(error);
            });
    }

    wiredResults;
    @wire(getCaseList, {
        title: '$title',
        content: '$content',
        objectName: '$objectNameForCase',
        filter: '$filter',
        orderBy: '$orderby',
        limitNumber: '$limit',
        dateField: '$datefield'
    })
    caseList(result) {
        if (this.objectNameForCase) {
            this.handleWireResult(result);
        }
    }

    @wire(getAnnouncementList, {
        title: '$title',
        content: '$content',
        objectName: '$objectNameForAnnouncement',
        filter: '$filter',
        orderBy: '$orderby',
        limitNumber: '$limit',
        dateField: '$datefield',
        showImage: '$showimage',
        filterBySkills: '$filterbyskills',
        skills: '$userSkills'
    })
    announcementList(result) {
        if (this.objectNameForAnnouncement) {
            this.handleWireResult(result);
        }
    }

    @wire(getKnowledgeList, {
        title: '$title',
        content: '$content',
        objectName: '$objectNameForKnowledge',
        filter: '$filter',
        orderBy: '$orderby',
        limitNumber: '$limit',
        dateField: '$datefield',
        showImage: '$showimage',
        filterBySkills: '$filterbyskills',
        skills: '$userSkills'
    })
    knowledgeList(result) {
        if (this.objectNameForKnowledge) {
            this.handleWireResult(result);
        }
    }

    @wire(getList, {
        title: '$title',
        content: '$content',
        objectName: '$objectNameForGeneral',
        filter: '$filter',
        orderBy: '$orderby',
        limitNumber: '$limit',
        dateField: '$datefield'
    })
    generalList(result) {
        if (this.objectNameForGeneral) {
            this.handleWireResult(result);
        }
    }

    handleWireResult(result) {
        this.wiredResults = result;
        if (result.data) {
            this.records = result.data;
        } else if (result.error) {
            this.handleError(result.error);
        }

        setTimeout(() => {
            this.showSpinner = false;
        }, 100);
    }

    generateListUrl() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.objectName,
                actionName: 'list'
            },
            state: {
                filterName: this.listviewname
            }
        }).then((url) => {
            this.pageUrl = url;
        });
    }

    navigateToList() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.objectName,
                actionName: 'list'
            },
            state: {
                filterName: this.listviewname
            }
        });
    }

    setupEmpSubscription() {
        if (this.isEmpSubscribed) {
            return;
        }
        if (this.refreshPageAutomatically && this.objectName === 'NKS_Announcement__c') {
            subscribe(this.channelName, -1, this.refreshComponent)
                .then((response) => {
                    this.subscription = response;
                    if (!this.isEmpSubscribed) {
                        this.printError();
                    }
                })
                .catch((error) => {
                    this.printError(error);
                });
        }
    }

    handleError(error) {
        let message = 'Unknown error';
        if (Array.isArray(error.body)) {
            message = error.body.map((e) => e.message).join(', ');
        } else if (typeof error.body.message === 'string') {
            message = error.body.message;
        }
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message,
                variant: 'error'
            })
        );
    }

    printError() {
        onError((error) => {
            console.error('Received error from empApi: ', JSON.stringify(error));
        });
    }

    paginateListOfRecords() {
        // eslint-disable-next-line @lwc/lwc/no-api-reassignments
        this.limit += 3;
        this.refreshComponent();
    }

    async refreshComponent() {
        this.showSpinner = true;
        this.isRefreshDisabled = true;
        await refreshApex(this.wiredResults);
        this.showSpinner = false;
        setTimeout(() => { // 10 sec delay to avoid spamming requests
            this.isRefreshDisabled = false;
        }, 10000);
    }

    get isEmpSubscribed() {
        return Object.keys(this.subscription).length !== 0 && this.subscription.constructor === Object;
    }

    get newsRecords() {
        if (this.isNews && this.records && Array.isArray(this.records)) {
            let sortedList = [...this.records];

            // Sort by 'pin' property in descending order (pinned items first)
            sortedList.sort((a, b) => (b.pin === a.pin ? 0 : b.pin ? 1 : -1));
            return sortedList;
        }
        return [];
    }

    get isNews() {
        return this.objectName === 'NKS_Announcement__c' && this.filter?.includes('News');
    }

    get isKnowledge() {
        return this.objectName === 'Knowledge__kav';
    }

    get hasRecord() {
        return this.records.length > 0;
    }

    get isSTO() {
        return this.objectName === 'Case' && this.filter.includes('STO_Case');
    }

    get isStripedList() {
        return this.objectName === 'LiveChatTranscript' || this.isSTO;
    }

    get setEmptyStateForCase() {
        return !this.hasRecord && this.isSTO;
    }

    get lastIndex() {
        return this.objectName === 'LiveChatTranscript' || this.isSTO ? this.records.length - 1 : 0;
    }
}
