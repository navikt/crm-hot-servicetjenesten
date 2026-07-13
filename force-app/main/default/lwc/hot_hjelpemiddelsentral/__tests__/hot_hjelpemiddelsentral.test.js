import { createElement } from 'lwc';
import HotHjelpemiddelsentral from 'c/hot_hjelpemiddelsentral';

describe('c-hot-hjelpemiddelsentral', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('uses configured display name for Tromsø', () => {
        const element = createElement('c-hot-hjelpemiddelsentral', {
            is: HotHjelpemiddelsentral
        });

        element.setBostedHjelpemiddelsentral({
            Hjelpemiddelsentral_name__c: 'Nav hjelpemiddelsentral Troms og Finnmark (4719) - Tromsø',
            NAVurl__c: 'https://example.com'
        });

        expect(element.bostedHjelpemiddelsentralString).toBe(
            'Nav hjelpemiddelsentral Troms og Finnmark (4719) - Tromsø'
        );
    });

    it('uses configured display name for Lakselv', () => {
        const element = createElement('c-hot-hjelpemiddelsentral', {
            is: HotHjelpemiddelsentral
        });

        element.setMidlertidigBostedHjelpemiddelsentral({
            Hjelpemiddelsentral_name__c: 'Nav hjelpemiddelsentral Troms og Finnmark (4719) - Lakselv',
            NAVurl__c: 'https://example.com'
        });

        expect(element.midlertidigHjelpemiddelsentralString).toBe(
            'Nav hjelpemiddelsentral Troms og Finnmark (4719) - Lakselv'
        );
    });

    it('matches configured numbers exactly', () => {
        const element = createElement('c-hot-hjelpemiddelsentral', {
            is: HotHjelpemiddelsentral
        });

        expect(element.containsConfiguredNumber('5501,5503,5510', '5501')).toBe(true);
        expect(element.containsConfiguredNumber('5501,5503,5510', '55')).toBe(false);
    });
});
