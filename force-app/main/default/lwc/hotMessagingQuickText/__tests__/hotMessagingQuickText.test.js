import { createElement } from 'lwc';
import HotMessagingQuickText from 'c/hotMessagingQuickText';
import getQuicktexts from '@salesforce/apex/CRM_HenvendelseQuicktextController.getContextQuicktexts';
import searchRecords from '@salesforce/apex/CRM_HenvendelseQuicktextController.searchContextRecords';
import { setImmediate } from 'timers';

jest.mock('@salesforce/apex/CRM_HenvendelseQuicktextController.getContextQuicktexts', () => ({
    default: jest.fn()
}), { virtual: true });
jest.mock('@salesforce/apex/CRM_HenvendelseQuicktextController.searchContextRecords', () => ({
    default: jest.fn()
}), { virtual: true });

const flushPromises = () => new Promise(setImmediate);
const abbreviation = (message) => ({
    nksAbbreviationKey__c: 'hello',
    Message: message,
    Case_sensitive__c: false
});

function mount(ids = []) {
    const element = createElement('c-hot-messaging-quick-text', { is: HotMessagingQuickText });
    element.contextRecordIds = ids;
    document.body.appendChild(element);
    return element;
}

function expand(element, value = 'hello ') {
    const editor = element.shadowRoot.querySelector('textarea');
    editor.value = value;
    editor.setSelectionRange(value.length, value.length);
    editor.dispatchEvent(new KeyboardEvent('keyup', { key: ' ', keyCode: 32 }));
    return editor;
}

function search(element, term = 'Hello') {
    const input = element.shadowRoot.querySelector('lightning-input');
    input.value = term;
    input.dispatchEvent(new KeyboardEvent('keyup', { key: 'Enter', bubbles: true }));
}

describe('contextual Quick Text', () => {
    beforeEach(() => {
        getQuicktexts.mockResolvedValue([]);
        searchRecords.mockResolvedValue([]);
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.resetAllMocks();
    });

    it('passes context and expands prepared text without HTML cleanup', async () => {
        getQuicktexts.mockResolvedValue([abbreviation('Hello Ada <Example>')]);
        const element = mount(['001000000000001']);
        await flushPromises();
        expect(getQuicktexts).toHaveBeenCalledWith({ contextRecordIds: ['001000000000001'] });
        expect(expand(element).value).toBe('Hello Ada <Example> ');
        expect(element.conversationNote).toBe('Hello Ada <Example> ');
    });

    it('supports typing before loading completes', () => {
        getQuicktexts.mockReturnValue(new Promise(() => {}));
        expect(expand(mount()).value).toBe('hello ');
    });

    it('clears old abbreviations immediately and ignores stale loads', async () => {
        let finishOld;
        getQuicktexts.mockImplementationOnce(() => new Promise((resolve) => { finishOld = resolve; }));
        const element = mount(['001000000000001']);
        element.contextRecordIds = ['001000000000002'];
        getQuicktexts.mockResolvedValue([abbreviation('New account')]);
        element.contextRecordIds = ['001000000000003'];
        await flushPromises();
        finishOld([abbreviation('Old account')]);
        await flushPromises();
        expect(expand(element).value).toBe('New account ');
    });

    it('does not reload an equivalent context or expose its internal array', async () => {
        const element = mount(['001000000000001']);
        await flushPromises();
        element.contextRecordIds = ['001000000000001'];
        const ids = element.contextRecordIds;
        ids.push('001000000000002');
        expect(element.contextRecordIds).toEqual(['001000000000001']);
        expect(getQuicktexts).toHaveBeenCalledTimes(1);
    });

    it('passes context to search and preserves modal cleanup and change events', async () => {
        searchRecords.mockResolvedValue([{
            RecordId: 'text1',
            Name: 'Greeting',
            Message: '<p>Hello Ada <Example></p>',
            Summary: 'Hello Ada'
        }]);
        const element = mount(['001000000000001']);
        const changed = jest.fn();
        element.addEventListener('commentschange', changed);
        await flushPromises();
        search(element);
        await flushPromises();
        expect(searchRecords).toHaveBeenCalledWith({
            search: 'Hello',
            contextRecordIds: ['001000000000001']
        });
        element.shadowRoot.querySelector('.quicktext-item').click();
        expect(element.conversationNote).toBe('Hello Ada \n');
        expect(changed.mock.calls[0][0].detail).toBe('Hello Ada \n');
    });

    it('does not show results returned for a previous context', async () => {
        let finishSearch;
        searchRecords.mockReturnValue(new Promise((resolve) => { finishSearch = resolve; }));
        const element = mount(['001000000000001']);
        await flushPromises();
        search(element);
        element.contextRecordIds = ['001000000000002'];
        finishSearch([{ RecordId: 'old', Name: 'Old', Message: 'Old', Summary: 'Old' }]);
        await flushPromises();
        expect(element.shadowRoot.querySelector('.quicktext-item')).toBeNull();
        expect(element.shadowRoot.querySelector('lightning-spinner')).toBeNull();
    });

    it('logs loading failures', async () => {
        const consoleError = jest.spyOn(console, 'error').mockImplementation(() => {});
        getQuicktexts.mockRejectedValue({ body: { message: 'Context limit exceeded' } });
        const element = createElement('c-hot-messaging-quick-text', { is: HotMessagingQuickText });
        document.body.appendChild(element);
        await flushPromises();
        expect(consoleError).toHaveBeenCalledWith(
            'Problem getting quick texts:',
            { body: { message: 'Context limit exceeded' } }
        );
        expect(expand(element).value).toBe('hello ');
        consoleError.mockRestore();
    });

    it('logs search failures and removes previous results', async () => {
        const consoleError = jest.spyOn(console, 'error').mockImplementation(() => {});
        searchRecords.mockRejectedValue({ body: { message: 'Search unavailable' } });
        const element = mount();
        await flushPromises();
        search(element);
        await flushPromises();
        expect(consoleError).toHaveBeenCalledWith(
            'Problem searching quick texts:',
            { body: { message: 'Search unavailable' } }
        );
        expect(element.shadowRoot.querySelector('.quicktext-item')).toBeNull();
        expect(element.shadowRoot.querySelector('lightning-spinner')).toBeNull();
        consoleError.mockRestore();
    });
});
