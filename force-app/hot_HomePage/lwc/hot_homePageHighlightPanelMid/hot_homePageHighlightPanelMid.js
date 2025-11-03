import { LightningElement } from 'lwc';
import bobLogo from '@salesforce/resourceUrl/bobLogo';
export default class NksHomePageHighlightPanelMid extends LightningElement {
    get links() {
        return [
            {
                title: `Bob `,
                url: 'https://bob.ansatt.nav.no/',
                imageUrl: `${bobLogo}#logo`,
                showImage: true
            },
            {
                title: 'Norsk-engelsk ordliste',
                url: 'https://navno.sharepoint.com/sites/enhet-kontaktsenter/SitePages/Ordliste-Norsk-Engelsk.aspx'
            }
        ];
    }
}
