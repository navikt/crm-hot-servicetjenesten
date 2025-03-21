import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class NksHomePageListEntry extends NavigationMixin(LightningElement) {
    @api record;
    @api isKnowledge = false;
    @api isNews = false;
    @api isPinned = false;

    recordPageUrl;

    navigateToSObject(event) {
        event.preventDefault();
        event.stopPropagation();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.record.recordId,
                actionName: 'view'
            }
        });
    }

    connectedCallback() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.record.recordId,
                actionName: 'view'
            }
        }).then((url) => {
            this.recordPageUrl = url;
        });
    }

    isToday(dateToCheck) {
        // Get today's date
        const today = new Date();
        // Compare the components of the dateToCheck with today's date
        const isSameDate =
            dateToCheck.getDate() === today.getDate() &&
            dateToCheck.getMonth() === today.getMonth() &&
            dateToCheck.getFullYear() === today.getFullYear();
        // Return true if the dateToCheck is today, otherwise return false
        return isSameDate;
    }

    countDays(dateToCheck) {
        const today = new Date();
        // calculate the time difference of two dates
        const differenceInTime = Math.abs(dateToCheck.getTime() - today.getTime());
        // To calculate the no. of days between two dates
        const differenceInDays = differenceInTime / (1000 * 3600 * 24);
        return differenceInDays;
    }

    formatDate(inputDate, inputTxt) {
        let res;
        const dateToCheck = new Date(inputDate);
        let numOfDays = this.countDays(dateToCheck);
        const hour = ('0' + dateToCheck.getHours()).slice(-2);
        const minutes = (dateToCheck.getMinutes() < 10 ? '0' : '') + dateToCheck.getMinutes();
        const date = dateToCheck.getDate();
        const month = dateToCheck.toLocaleString('no', { month: 'long' });

        const roundedNumOfDays = Math.trunc(numOfDays);

        if (this.isToday(dateToCheck)) {
            res = `${inputTxt} i dag kl. ${hour}:${minutes}`;
        } else {
            if (numOfDays > 0 && numOfDays < 1) {
                res = `${inputTxt} i går kl. ${hour}:${minutes}`;
            }
            if (roundedNumOfDays >= 1 && roundedNumOfDays <= 6) {
                res = `${inputTxt} for ${roundedNumOfDays} døgn siden`;
            }
            if (roundedNumOfDays > 6) {
                res = `${inputTxt}: ${date}. ${month}`;
            }
        }
        return res;
    }

    get publishDate() {
        return this.formatDate(this.record.publishDate, 'Publisert');
    }

    get updateDate() {
        return this.formatDate(this.record.lastUpdatedDate, 'Oppdatert');
    }
}
