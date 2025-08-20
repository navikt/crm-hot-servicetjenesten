import { LightningElement, api } from 'lwc';
import { FlowNavigationBackEvent, FlowNavigationNextEvent, FlowNavigationFinishEvent } from 'lightning/flowSupport';
import templateWithFooter from './templateWithFooter.html';
import templateWithoutFooter from './templateWithoutFooter.html';
import sharedStyling from './sharedStyling.css';

export default class Hot_FlowNavigation extends LightningElement {
    @api action = 'NEXT';
    @api buttonLabel;
    @api buttonAlignment;
    @api stretched = false;
    @api availableActions = ['NEXT', 'BACK', 'FINISH'];
    @api buttonVariant = 'brand';
    @api removeFooter = false;

    static stylesheets = [sharedStyling];

    render() {
        return this.removeFooter ? templateWithoutFooter : templateWithFooter;
    }

    handleButtonClick() {
        let flowEvent;

        switch (this.action) {
            case 'NEXT':
                flowEvent = new FlowNavigationNextEvent();
                break;
            case 'BACK':
                flowEvent = new FlowNavigationBackEvent();
                break;
            case 'FINISH':
                flowEvent = new FlowNavigationFinishEvent();
                break;
            default:
                console.error('Invalid action:', this.action);
                return;
        }

        if (flowEvent) {
            this.dispatchEvent(flowEvent);
        }
    }

    get alignment() {
        switch (this.buttonAlignment) {
            case 'RIGHT':
                return 'end';
            case 'LEFT':
                return '';
            case 'CENTER':
                return 'center';
            default:
                return 'end';
        }
    }

    get validAction() {
        return this.availableActions.find((action) => action === this.action);
    }
}
