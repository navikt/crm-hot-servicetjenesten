public with sharing class HOT_PostAddressController {
    public class PostAddress {
        @AuraEnabled
        public String navn;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String adresselinje1;
        @AuraEnabled
        public String adresselinje2;
        @AuraEnabled
        public String adresselinje3;
        @AuraEnabled
        public String postummer;
        @AuraEnabled
        public String poststed;
        @AuraEnabled
        public String landkode;
        @AuraEnabled
        public String land;

        public PostAddress(HOT_PostAddressService.HOT_PostAddressResponse response) {
            status = response.status;
            if (status != '200') {
                return;
            }
            navn = response.navn;
            type = response.adresse.type;
            adresselinje1 = response.adresse.adresselinje1;
            adresselinje2 = response.adresse.adresselinje2;
            adresselinje3 = response.adresse.adresselinje3;
            postummer = response.adresse.postnummer;
            poststed = response.adresse.poststed;
            landkode = response.adresse.landkode;
            land = response.adresse.land;
        }
    }
    @AuraEnabled(cacheable=true)
    public static PostAddress getPostAddress(Id recordId, String objectApiName) {
        String ident;
        if (objectApiName.equals('Case')) {
            ident = [SELECT Account.CRM_Person__r.Name FROM Case WHERE Id = :recordId LIMIT 1]
                ?.Account
                ?.CRM_Person__r
                ?.Name;
        } else if (objectApiName.equals('Account')) {
            ident = [SELECT CRM_Person__r.Name FROM Account WHERE Id = :recordId LIMIT 1]?.CRM_Person__r?.Name;
        } else if (objectApiName.equals('LiveChatTranscript')) {
            ident = [SELECT Account.CRM_Person__r.Name FROM LiveChatTranscript WHERE Id = :recordId LIMIT 1]
                ?.Account
                ?.CRM_Person__r
                ?.Name;
        } else {
            return null;
        }
        return new PostAddress(HOT_PostAddressService.getPostAddress(ident));
    }
}
