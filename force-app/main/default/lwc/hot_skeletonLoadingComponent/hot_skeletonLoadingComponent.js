import { LightningElement } from 'lwc';
import personHighlightPanel from './personHighlightPanel.html';

export default class SkeletonLoadingComponent extends LightningElement {
    render() {
        return personHighlightPanel;
    }
}
