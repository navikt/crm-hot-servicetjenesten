import { LightningElement, api } from 'lwc';

export default class hot_personHighlightPanelBot extends LightningElement {
    @api personDetails;

    actorId;
    fnr;

    get isDisabledButtons() {
        // this.personDetails.actorId this.personDetails.personIdent
        return true;
    }
}
