public without sharing class HOT_KrrInformationController {
    static LoggerUtility logger = new LoggerUtility();

    @AuraEnabled
    public static void updateKrrInformation(String personIdent) {
        List<Person__c> personsToUpdate = new List<Person__c>();
        CRM_DatabaseOperations cdo = new CRM_DatabaseOperations();
        cdo.setDomain(CRM_ApplicationDomain.Domain.HOT);
        try {
            List<KrrCalloutService.Person> personer = KrrCalloutService.doPersonOppslag2(
                new List<String>{ personIdent },
                null
            );
            if (personer != null && !personer.isEmpty()) {
                for (Person__c person : [SELECT Id FROM Person__c WHERE Name = :personIdent]) {
                    personsToUpdate.add(
                        new Person__c(
                            Id = person.Id,
                            INT_KrrEmail__c = personer[0]?.epostadresse,
                            INT_KrrMobilePhone__c = personer[0]?.mobiltelefonnummer,
                            INT_LastUpdatedFromKRR__c = Datetime.now(),
                            INT_VerifiedFromKRR__c = sistVerifisertDato(personer[0]),
                            INT_KRR_Reservation__c = personer[0]?.reservert == null ? false : personer[0]?.reservert,
                            INT_KrrWrittenStandard__c = personer[0]?.spraak
                        )
                    );
                }
            }

            if (!personsToUpdate.isEmpty())
                cdo.updateRecords(personsToUpdate);
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
