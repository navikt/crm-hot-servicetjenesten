import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getRelatedRecord from '@salesforce/apex/HOT_STORecordInfoController.getRelatedRecord';
import getThreadId from '@salesforce/apex/HOT_STORecordInfoController.getThreadIdByApiReference';
import NKS_FULL_NAME from '@salesforce/schema/User.NKS_FullName__c';
import COMPANY_NAME from '@salesforce/schema/User.CompanyName';
import PERSON_FULL_NAME from '@salesforce/schema/Person__c.NKS_Full_Name__c';
import CASE_THREAD_API_REFERENCE from '@salesforce/schema/Case.NKS_Henvendelse_BehandlingsId__c';
import THREAD_MEDSKRIV_REFERENCE from '@salesforce/schema/Thread__c.STO_Medskriv__C';
import THREAD_TYPE from '@salesforce/schema/Thread__c.CRM_Thread_Type__c';
// import MEDSKRIV_TEXT from '@salesforce/label/c.STO_Medskriv_Text';
// import MEDSKRIV_LABEL from '@salesforce/label/c.STO_Medskriv_Label';
import userId from '@salesforce/user/Id';
import { resolve } from 'c/hot_componentsUtils';

const englishCompanyTranslations = {
    'DIR ytelsesavdelingen': 'Benefits department, Directorate of Labour and Welfare',
    'Nav arbeid og ytelser styringsenhet': 'Nav Work and Benefits Management Unit',
    'Nav familie- og pensjonsytelser': 'Nav Family Benefits and Pensions Management Unit',
    'Nav kontroll Øst': 'Nav Control Eastern Norway',
    'Nav kontroll Vest': 'Nav Control Western Norway',
    'Nav kontroll Nord': 'Nav Control Northern Norway',
    'Nav kontroll styringsenhet': 'Nav Control Management Unit',
    'Nav medlemskap og avgift': 'Nav Social insurance and Contributions',
    'Nav oppfølging utland': 'Norwegian Labour and rehabilitation unit',
    'Nav registerforvaltning': 'Nav Registry Management',
    'Nav styringsenhet kontaktsenter': 'Nav Call and Service Centre Management Unit',
    'Seksjon fag- og ytelsesutvikling': 'Pensions and benefits - Legislation and development',
    'Seksjon informasjonsforvaltning': 'Information Management',
    'Seksjon juridisk': 'Legal affairs',
    'Seksjon kompetanseutvikling': 'Professional Development',
    'Seksjon styring': 'Governance',
    Ytelseslinjen: 'Nav Benefits Administration'
};

export default class hotStoMessaging extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api singleThread;
    @api cardTitle;
    @api showClose = false;
    @api checkMedskriv = false;
    @api submitButtonLabel;
    @api isThread;

    wireField;
    accountId;
    userId;
    personId;
    userName;
    supervisorName;
    companyName;
    norwegianCompanyName;
    englishCompanyName;
    accountApiName;
    threadId;
    englishTextTemplate = false;
    acceptedMedskriv = false;
    medskriv = false;
    threadType;
    isThreadIdNull = false;

    labels = {
        MEDSKRIV_TEXT: 'Medskriv tekst',
        MEDSKRIV_LABEL: 'Medskriv label'
    };

    connectedCallback() {
        this.wireField =
            this.objectApiName === 'Case'
                ? [this.objectApiName + '.Id', CASE_THREAD_API_REFERENCE]
                : [this.objectApiName + '.Id'];
        this.userId = userId;
        this.accountApiName = this.getAccountApiName();
    }

    dispatchStoToolbarAction(event) {
        //Sending event to parent to initialize flow
        const toolbarActionEvent = new CustomEvent('sto_toolbaraction', event);

        this.dispatchEvent(toolbarActionEvent);
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$wireField'
    })
    wiredRecord({ error, data }) {
        if (error) {
            console.error('wiredRecord failed: ', error);
        } else if (data) {
            if (this.objectApiName === 'Case') {
                const threadApiReference = getFieldValue(data, CASE_THREAD_API_REFERENCE);
                getThreadId({ apiRef: threadApiReference })
                    .then((threadId) => {
                        this.threadId = threadId;
                    })
                    .catch((err) => {
                        console.error('getThreadId failed: ', err);
                    })
                    .finally(() => {
                        this.isThreadIdNull = this.threadId == null;
                    });
            } else if (this.objectApiName === 'Thread__c') {
                this.threadId = this.recordId;
            }
            this.getAccountId();
        }
    }

    @wire(getRecord, {
        recordId: '$accountId',
        fields: ['Account.Id']
    })
    wiredAccount({ error, data }) {
        if (error) {
            console.error('wiredAccount failed: ', error);
        } else if (data) {
            if (this.accountId) {
                this.getPersonId();
            }
        }
    }

    @wire(getRecord, {
        recordId: '$personId',
        fields: [PERSON_FULL_NAME]
    })
    wiredPerson({ error, data }) {
        if (error) {
            console.error('wiredPerson failed', error);
        } else if (data) {
            if (this.accountId && this.personId) {
                let fullName = getFieldValue(data, PERSON_FULL_NAME);
                this.userName = fullName ? fullName.split(' ').shift() : '';
            }
        }
    }

    @wire(getRecord, {
        recordId: '$userId',
        fields: [NKS_FULL_NAME, COMPANY_NAME]
    })
    wiredUser({ error, data }) {
        if (error) {
            console.error('wiredUser failed: ', error);
        } else if (data) {
            this.supervisorName = getFieldValue(data, NKS_FULL_NAME);
            this.companyName = getFieldValue(data, COMPANY_NAME);
            try {
                this.norwegianCompanyName = this.getNorwegianCompanyName();
                this.englishCompanyName = this.getEnglishCompanyName();
            } catch (err) {
                console.error('Problem getting company name: ', err);
            }
        }
    }

    @wire(getRecord, { recordId: '$threadId', fields: [THREAD_MEDSKRIV_REFERENCE, THREAD_TYPE] })
    wiredThread({ error, data }) {
        if (error) {
            console.error('wiredThread failed: ', error);
        }
        if (data) {
            this.medskriv = getFieldValue(data, THREAD_MEDSKRIV_REFERENCE);
            this.threadType = getFieldValue(data, THREAD_TYPE);
        }
    }

    // Event Handlers
    handleEnglishEventTwo(event) {
        this.englishTextTemplate = event.detail;
    }

    handleMedskrivClick() {
        this.acceptedMedskriv = true;
        const child = this.template.querySelector('c-crm-messaging-message-component');
        child.checkSlotChange('messages');
        child.focus();
    }

    handleSubmit() {
        this.dispatchEvent(new CustomEvent('submitfromparent'));
    }

    forwardEvent(event) {
        this.dispatchEvent(new CustomEvent(event.type));
    }

    // Getters
    get textTemplate() {
        let salutation = this.userName == null ? 'Hei,' : 'Hei, ' + this.userName;
        let regards = 'Med vennlig hilsen';

        if (this.englishTextTemplate === true) {
            salutation = this.userName == null ? 'Hi,' : 'Hi ' + this.userName + ',';
            regards = 'Kind regards';
        }

        return `${salutation}\n\n\n\n${regards}\n${this.supervisorName}\n${
            this.englishTextTemplate === true ? this.englishCompanyName : this.norwegianCompanyName
        }`;
    }

    get computeClasses() {
        return this.threadType === 'BTO' ? 'greenHeader' : '';
    }

    get actualCardTitle() {
        if (this.objectApiName === 'Case' && ['BTO', 'STO'].includes(this.threadType))
            return this.threadType === 'STO' ? 'Skriv til oss' : 'Beskjed til oss';

        return this.cardTitle;
    }

    get showMedskrivBlocker() {
        return this.checkMedskriv === true && this.acceptedMedskriv === false && this.medskriv === false;
    }

    getAccountApiName() {
        if (this.objectApiName === 'Case') {
            return 'AccountId';
        } else if (this.objectApiName === 'Thread__c') {
            return 'CRM_Account__c';
        }
        return null;
    }

    getAccountId() {
        getRelatedRecord({
            parentId: this.recordId,
            relationshipField: this.accountApiName,
            objectApiName: this.objectApiName
        })
            .then((record) => {
                this.accountId = resolve(this.accountApiName, record);
            })
            .catch((error) => {
                console.error(error);
            });
    }

    getPersonId() {
        getRelatedRecord({
            parentId: this.accountId,
            relationshipField: 'CRM_Person__c',
            objectApiName: 'Account'
        })
            .then((record) => {
                this.personId = resolve('CRM_Person__c', record);
            })
            .catch((error) => {
                console.error('Problem getting person id: ', error);
            });
    }

    getNorwegianCompanyName() {
        try {
            const phraseMap = {
                'NAV ARBEID OG YTELSER': 'Nav arbeid og ytelser',
                'NAV FAMILIE- OG PENSJONSYTELSER': 'Nav familie- og pensjonsytelser',
                'NAV HJELPEMIDDELSENTRAL': 'Nav hjelpemiddelsentral',
                'NAV KONTROLL': 'Nav kontroll',
                'NAV OPPFØLGING UTLAND': 'Nav oppfølging utland',
                'NAV STYRINGSENHET KONTAKTSENTER': 'Nav styringsenhet kontaktsenter',
                'NAV ØKONOMI STØNAD': 'Nav økonomi stønad',
                'NAV UTLAND OG FELLESTJENESTER': 'Nav utland og fellestjenester',
                'NAV KONTROLL ANALYSE': 'Nav kontroll analyse',
                'NAV KONTROLL STYRINGSENHET': 'Nav kontroll styringsenhet',
                'NAV REGISTERFORVALTNING': 'Nav registerforvaltning',
                'NAV TILTAK': 'Nav tiltak',
                'NAV KLAGEINSTANS': 'Nav klageinstans',
                'SEKSJON FAG- OG YTELSESUTVIKLING': 'Seksjon fag- og ytelsesutvikling',
                'SEKSJON INFORMASJONSFORVALTNING': 'Seksjon informasjonsforvaltning',
                'SEKSJON JURIDISK': 'Seksjon juridisk',
                'SEKSJON KOMPETANSEUTVIKLING': 'Seksjon kompetanseutvikling',
                'SEKSJON STYRING': 'Seksjon styring'
            };

            const formatWord = (word) =>
                word
                    .split('-')
                    .map((part) => part.charAt(0).toUpperCase() + part.slice(1).toLowerCase())
                    .join('-');

            const formatRemainingWords = (name) => name.split(/\s+/).map(formatWord).join(' ');

            const formatCompanyName = (key, formattedName) => {
                const mappedPhrase = phraseMap[key];
                const remainingName = formattedName.replace(key, '').trim();
                return `${mappedPhrase} ${formatRemainingWords(remainingName)}`;
            };

            if (this.companyName === 'IT-AVDELINGEN') {
                return 'IT-avdelingen';
            }

            if (this.companyName.startsWith('DIR')) {
                const remainingName = this.companyName.slice(4).trim();
                const formattedName = remainingName
                    .toLowerCase()
                    .split(/\s+/)
                    .map((part) => {
                        if (part.includes('-')) {
                            return part
                                .split('-')
                                .map((subPart) => {
                                    return subPart.charAt(0).toLowerCase() + subPart.slice(1);
                                })
                                .join('-');
                        }
                        return part.toLowerCase();
                    })
                    .join(' ');
                return `DIR ${formattedName}`;
            }

            if (
                this.companyName.toLowerCase().includes('kontaktsenter') &&
                !this.companyName.toLowerCase().includes('styringsenhet')
            ) {
                return 'Nav kontaktsenter';
            }

            const formattedName = this.companyName.toUpperCase();
            for (const key in phraseMap) {
                if (formattedName.includes(key)) {
                    return formatCompanyName(key, formattedName);
                }
            }

            return formatRemainingWords(this.companyName);
        } catch (error) {
            console.error('Problem getting Norwegian company name:', error);
            return '';
        }
    }

    getEnglishCompanyName() {
        try {
            const normalizedCompanyName = this.norwegianCompanyName.trim();

            if (normalizedCompanyName in englishCompanyTranslations) {
                return englishCompanyTranslations[normalizedCompanyName];
            }

            let ecn = '';
            let hasEnglishTranslation = true;
            const mapObj = {
                og: 'and',
                i: 'in'
            };
            const unitsWithPrepositions = [
                'Nav Eiganes og Tasta',
                'Nav Evje og Hornnes',
                'Nav Herøy og Vanylven',
                'Nav Hillevåg og Hinna',
                'Nav Hundvåg og Storhaug',
                'Nav Møre og Romsdal',
                'Nav Nes i Akershus',
                'Nav Oppdal og Rennebu',
                'Nav Rennesøy og Finnøy',
                'Nav Røros, Os og Holtålen',
                'Nav Troms og Finnmark',
                'Nav Vestfold og Telemark',
                'Nav Våler i Hedmark'
            ];

            if (this.norwegianCompanyName.includes('arbeid og ytelser')) {
                ecn = this.norwegianCompanyName.replace('arbeid og ytelser', 'Work and Benefits');
            } else if (this.norwegianCompanyName.includes('familie- og pensjonsytelser')) {
                ecn = this.norwegianCompanyName.replace('familie- og pensjonsytelser', 'Family Benefits and Pensions');
            } else if (this.norwegianCompanyName.includes('hjelpemiddelsentral')) {
                ecn = this.norwegianCompanyName.replace('hjelpemiddelsentral', 'Department of assistive technology');
            } else if (this.norwegianCompanyName.includes('klageinstans')) {
                ecn = this.norwegianCompanyName.replace('klageinstans', 'Appeals');
            } else if (this.norwegianCompanyName.includes('kontaktsenter')) {
                ecn = this.norwegianCompanyName.replace('kontaktsenter', 'Call and Service Center');
            } else if (this.norwegianCompanyName.includes('kontroll analyse')) {
                ecn = this.norwegianCompanyName.replace('kontroll analyse', 'Control Analysis');
            } else if (this.norwegianCompanyName.includes('kontroll')) {
                ecn = this.norwegianCompanyName.replace('kontroll', 'Control');
            } else if (this.norwegianCompanyName.includes('tiltak')) {
                ecn = this.norwegianCompanyName.replace('tiltak', 'Department for employment measures');
            } else if (this.norwegianCompanyName.includes('Ytelseslinjen')) {
                ecn = this.norwegianCompanyName.replace('Ytelseslinjen', 'Benefits Administration');
            } else {
                if (unitsWithPrepositions.includes(this.norwegianCompanyName)) {
                    ecn = this.norwegianCompanyName.replace(/\b(?:og|i)\b/gi, (matched) => mapObj[matched]);
                    return ecn;
                }
                hasEnglishTranslation = false;
                console.error('There is no translation for this CompanyName.');
                return this.norwegianCompanyName;
            }
            if (hasEnglishTranslation) {
                ecn = ecn.replace(/\b(?:og|i)\b/gi, (matched) => mapObj[matched]);
            }
            return ecn;
        } catch (error) {
            console.error('Problem getting English company name: ' + error);
            return '';
        }
    }
}