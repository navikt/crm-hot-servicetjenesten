import { LightningElement, api } from 'lwc';

// Thiscomponent has a duplicate of customButton in crm-henvnedelse
// Changes in this component should be reflected there
export default class hotButton extends LightningElement {
    @api elementId = 'buttonId';
    @api elementDataId = 'buttonDataId';
    @api autofocus = false;
    @api disabled = false;
    @api type = 'button'; // Button, Submit, Reset
    @api value;
    @api name = 'button';
    // @ts-ignore
    @api title;
    @api buttonStyling = 'primary'; // Primary, Secondary, Tertiary, Danger
    @api buttonLabel;
    // @ts-ignore
    @api ariaLabel;
    // @ts-ignore
    @api ariaExpanded = false;
    @api isLink = false;
    @api fullHeight = false;
    @api standardLength = false;

    get buttonClass() {
        let buttonStyle = this.buttonStyling?.toLowerCase();
        const baseClass =
            'slds-button  button-spacing ' +
            (this.fullHeight ? 'button-full-height ' : '') +
            (this.standardLength ? '' : 'slds-button_stretch ');
        const styleMap = {
            primary: 'slds-button_brand',
            secondary: 'slds-button_outline-brand',
            danger: 'slds-button_destructive'
        };
        return baseClass + (styleMap[buttonStyle] || 'slds-button_brand');
    }

    handleClick(event) {
        const clickedEvent = new CustomEvent('buttonclick', {
            detail: {
                event: event.target.value,
                dataId: this.elementDataId
            }
        });
        this.dispatchEvent(clickedEvent);
    }

    @api focusButton() {
        this.template.querySelector('button').focus();
    }

    get defaultAriaLabel() {
        return this.ariaLabel ?? this.defaultButtonLabel;
    }

    get defaultValue() {
        return this.value ?? this.defaultButtonLabel;
    }

    get defaultTitle() {
        return this.title ?? this.defaultButtonLabel;
    }

    get defaultButtonLabel() {
        return this.buttonLabel ?? 'Knapp uten navn';
    }
}