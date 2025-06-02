public without sharing class HOT_KrrInformationController {
    static LoggerUtility logger = new LoggerUtility();

    @AuraEnabled
    public static void updateKrrInformation(String personIdent) {
        List<Person__c> personsToUpdate = new List<Person__c>();
        CRM_DatabaseOperations cdo = new CRM_DatabaseOperations();
        cdo.setDomain(CRM_ApplicationDomain.Domain.HOT);
    
        try {
            KrrCalloutService service = new KrrCalloutService();
            KrrCalloutService.KrrResponse response = service.getPersons(
                new List<String>{ personIdent },
                true
            );
    
            if (response != null && response.personer != null && response.personer.containsKey(personIdent)) {
                KrrCalloutService.Person personData = response.personer.get(personIdent);
    
                for (Person__c person : [SELECT Id FROM Person__c WHERE Name = :personIdent]) {
                    personsToUpdate.add(
                        new Person__c(
                            Id = person.Id,
                            INT_KrrEmail__c = personData?.epostadresse,
                            INT_KrrMobilePhone__c = personData?.mobiltelefonnummer,
                            INT_LastUpdatedFromKRR__c = Datetime.now(),
                            INT_VerifiedFromKRR__c = sistVerifisertDato(personData),
                            INT_KRR_Reservation__c = personData?.reservert == null ? false : personData?.reservert,
                            INT_KrrWrittenStandard__c = personData?.spraak
                        )
                    );
                }
            }
    
            if (!personsToUpdate.isEmpty()) {
                cdo.updateRecords(personsToUpdate);
            }
        } catch (Exception e) {
            if (!personsToUpdate.isEmpty()) {
                logger.exception(e, personsToUpdate[0]);
            } else {
                logger.exception(e, null, CRM_ApplicationDomain.Domain.HOT);
            }
            logger.publish();
            throw new AuraHandledException('Failed to refresh KRR information.');
        }
    }

    private static Datetime sistVerifisertDato(KrrCalloutService.Person pers) {
        Datetime emailVerifisertDato = pers?.epostadresseVerifisert;
        Datetime mobileVerifisertDato = pers?.mobiltelefonnummerVerifisert;
        if (emailVerifisertDato != null && mobileVerifisertDato != null) {
            if (emailVerifisertDato < mobileVerifisertDato) {
                return mobileVerifisertDato;
            }
            return emailVerifisertDato;
        } else if (emailVerifisertDato != null)
            return emailVerifisertDato;
        else if (mobileVerifisertDato != null)
            return mobileVerifisertDato;
        else
            return null;
    }
}
