public with sharing class HOT_AddressController {
    private static LoggerUtility logger = new LoggerUtility('HOT Address Controller');

    @AuraEnabled(cacheable=true)
    public static List<HOT_Address> getBostedAddress(Id recordId, String objectApiName) {
        Person__c person = getPersonIdentAndFullName(recordId, objectApiName);
        if (person.Name == null) {
            return new List<HOT_Address>();
        }

        List<HOT_Address> bostedAddress = new List<HOT_Address>();
        try {
            PDL_API_Response addressData = queryAddressFromPDL(person.Name);
            bostedAddress = setAddressData(addressData);
            setAddressFullNameAndCity(bostedAddress, person);
        } catch (Exception e) {
            handleException('bosted', e, person.Name);
        } finally {
            logger.publish();
        }
        return bostedAddress;
    }

    @AuraEnabled(cacheable=true)
    public static List<HOT_Address> getOppholdsAddress(Id recordId, String objectApiName) {
        Person__c person = getPersonIdentAndFullName(recordId, objectApiName);
        List<HOT_Address> opAddresses = new List<HOT_Address>();
        try {
            PDL_API_Response response = queryAddressFromPDL(person.Name);
            for (PDL_Oppholdsadresse oa : response.data.hentPerson?.oppholdsadresse) {
                if (oa.metadata?.historisk == true) {
                    continue;
                }

                HOT_Address opAddr = new HOT_Address();
                if (oa?.vegadresse != null) {
                    opAddr.setOppholdsAddressFieldsFromVegAdresse(oa.vegadresse);
                } else if (oa?.matrikkeladresse != null) {
                    opAddr.setOppholdsAddressFieldsFromMatrikkelAdresse(oa.matrikkeladresse);
                } else if (oa?.utenlandskAdresse != null) {
                    opAddr.setOppholdsAddressFieldsFromUtenlandskAdresse(oa.utenlandskAdresse);
                }
                opAddresses.add(opAddr);
            }
            setAddressFullNameAndCity(opAddresses, person);
        } catch (Exception e) {
            handleException('opphold', e, person.Name);
        } finally {
            logger.publish();
        }
        return opAddresses;
    }

    @TestVisible
    private static List<HOT_Address> setAddressData(PDL_API_Response addressData) {
        List<HOT_Address> addrData = new List<HOT_Address>();
        HOT_Address addr = new HOT_Address();
        if (addressData.data.hentPerson.bostedsadresse?.size() > 0) {
            addr.setBostedVegMatrikkAddress(setLastUpdatedBostedsAdresse(addressData.data.hentPerson.bostedsadresse));
            addrData.add(addr);
        } else if (addressData.data.hentPerson.oppholdsadresse?.size() > 0) {
            addr.setOppholdsAddress(setLastUpdatedOppholdsAdresse(addressData.data.hentPerson.oppholdsadresse));
            addrData.add(addr);
        }
        // Always append delt bosted address if it exists
        if (addressData.data.hentPerson.deltBosted?.size() > 0) {
            addr = new HOT_Address(); // Wipe in case bostedsAdresse > 0
            addr.setDeltBostedsAddress(setLastUpdatedDeltBostedsAddress(addressData.data.hentPerson?.deltBosted));
            addrData.add(addr);
        }
        if (!addrData.isEmpty()) {
            return addrData;
        }
        HOT_Address boAddr = new HOT_Address();
        boAddr.address = 'Ikke registrert';
        addrData.add(boAddr);
        return addrData;
    }

    @TestVisible
    private static PDL_Bostedsadresse setLastUpdatedBostedsAdresse(List<PDL_Bostedsadresse> addresses) {
        PDL_Bostedsadresse latestAddress;
        for (PDL_Bostedsadresse addr : addresses) {
            if (
                addr.gyldigFraOgMed != null &&
                (latestAddress == null ||
                addr.gyldigFraOgMed > latestAddress.gyldigFraOgMed)
            ) {
                latestAddress = addr;
            }
        }
        if (latestAddress == null) {
            for (PDL_Bostedsadresse addr : addresses) {
                if (latestAddress == null || getCreatedDate(latestAddress.metadata) < getCreatedDate(addr.metadata)) {
                    latestAddress = addr;
                }
            }
        }
        return latestAddress;
    }

    @TestVisible
    private static PDL_Oppholdsadresse setLastUpdatedOppholdsAdresse(List<PDL_Oppholdsadresse> addresses) {
        PDL_Oppholdsadresse latestAddress;
        for (PDL_Oppholdsadresse addr : addresses) {
            if (
                addr.gyldigFraOgMed != null &&
                (latestAddress == null ||
                addr.gyldigFraOgMed > latestAddress.gyldigFraOgMed)
            ) {
                latestAddress = addr;
            }
        }
        if (latestAddress == null) {
            for (PDL_Oppholdsadresse addr : addresses) {
                if (latestAddress == null || getCreatedDate(latestAddress.metadata) < getCreatedDate(addr.metadata)) {
                    latestAddress = addr;
                }
            }
        }
        return latestAddress;
    }

    @TestVisible
    private static PDL_DeltBosted setLastUpdatedDeltBostedsAddress(List<PDL_DeltBosted> addresses) {
        PDL_DeltBosted latestAddress;
        for (PDL_DeltBosted addr : addresses) {
            if (
                addr.startdatoForKontrakt != null &&
                (latestAddress == null ||
                latestAddress.startdatoForKontrakt < addr.startdatoForKontrakt)
            ) {
                latestAddress = addr;
            }
        }
        if (latestAddress == null) {
            for (PDL_DeltBosted addr : addresses) {
                if (latestAddress == null || getCreatedDate(latestAddress.metadata) < getCreatedDate(addr.metadata)) {
                    latestAddress = addr;
                }
            }
        }
        return latestAddress;
    }

    @TestVisible
    private static void setAddressFullNameAndCity(List<HOT_Address> addresses, Person__c person) {
        if (addresses == null || person == null) {
            return;
        }

        String uppercasedFullName = person.NKS_Full_Name__c?.toUpperCase();
        Set<String> zipCodesWithoutRegion = new Set<String>();
        for (HOT_Address address : addresses) {
            address.fullName = uppercasedFullName;
            if (address.zipCode != null && address.region == null) {
                zipCodesWithoutRegion.add(address.zipCode);
            }
        }
        if (!zipCodesWithoutRegion.isEmpty()) {
            Map<String, Common_Code__c> zipCodeToCityMap = new Map<String, Common_Code__c>();
            for (Common_Code__c cc : [
                SELECT CRM_Code__c, Name
                FROM Common_Code__c
                WHERE CRM_Code_Set__c = 'Postnummer' AND CRM_Code__c IN :zipCodesWithoutRegion
            ]) {
                zipCodeToCityMap.put(cc.CRM_Code__c, cc);
            }
            for (HOT_Address address : addresses) {
                if (zipCodeToCityMap.containsKey(address.zipCode)) {
                    address.city = zipCodeToCityMap.get(address.zipCode).Name;
                }
            }
        }
    }

    @TestVisible
    private static Person__c getPersonIdentAndFullName(Id recordId, String objectApiName) {
        Id personId = null;
        if (objectApiName == 'Case') {
            personId = [SELECT Account.CRM_Person__c FROM Case WHERE Id = :recordId]?.Account?.CRM_Person__c;
        } else if (objectApiName == 'Account') {
            personId = [SELECT CRM_Person__c FROM Account WHERE Id = :recordId]?.CRM_Person__c;
        } else if (objectApiName == 'LiveChatTranscript') {
            personId = [SELECT Account.CRM_Person__c FROM LiveChatTranscript WHERE Id = :recordId]
                ?.Account
                ?.CRM_Person__c;
        }
        return personId != null ? [SELECT Name, NKS_Full_Name__c FROM Person__c WHERE Id = :personId] : null;
    }

    @TestVisible
    private static PDL_API_Response queryAddressFromPDL(String ident) {
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.bostedsadresse.selectAll(true);
        query.hentPerson.oppholdsadresse.selectAll(true);
        return query.execute();
    }

    @TestVisible
    private static Datetime getCreatedDate(PDL_Metadata metadata) {
        for (PDL_Endring endring : metadata.endringer) {
            if (endring.type == PDL_Endringstype.OPPRETT)
                return endring.registrert;
        }
        return Datetime.newInstance(0, 0, 0, 0, 0, 0);
    }

    @TestVisible
    private static Datetime getLastUpdateDate(PDL_Metadata metadata) {
        Datetime latestUpdate;

        for (PDL_Endring endring : metadata.endringer) {
            if (
                endring.type == PDL_Endringstype.OPPRETT && (latestUpdate == null || latestUpdate < endring.registrert)
            ) {
                latestUpdate = endring.registrert;
            }
        }
        return latestUpdate;
    }

    @TestVisible
    private static String createOppholdsAddressFromUtenlandskAdresse(List<String> addressFields) {
        String address = '';
        for (String addressField : addressFields) {
            if (!String.isBlank(addressField)) {
                address += addressField.toUpperCase() + ' ';
            }
        }
        address = address.trim();
        return String.isBlank(address) ? null : address;
    }

    /*
        UTILITY FUNCTIONS
    */

    private static void handleException(String addressType, Exception e, String personIdent) {
        logger.error(
            'Problem getting ' +
                addressType +
                ' address for personIdent: ' +
                personIdent +
                '\n' +
                e.getMessage() +
                '\n' +
                e.getStackTraceString(),
            null,
            CRM_ApplicationDomain.Domain.HOT,
            null
        );
    }

    private static String safeUpperCase(String value) {
        return value != null ? value.toUpperCase() : null;
    }

    @TestVisible
    private static String formatDateString(String inputDate) {
        if (String.isBlank(inputDate)) {
            return null;
        }

        List<String> splitDate = inputDate.split('-');
        return String.join(new List<String>{ splitDate[2], splitDate[1], splitDate[0] }, '.');
    }

    /*
        WRAPPER CLASS
    */

    public class HOT_Address {
        @AuraEnabled
        public String additionalName; // not in use
        @AuraEnabled
        public String address;
        @AuraEnabled
        public String changeRegisteredDate; // not in use
        @AuraEnabled
        public String city;
        @AuraEnabled
        public String coordinates; // not in use
        @AuraEnabled
        public String countryCode;
        @AuraEnabled
        public String fullName;
        @AuraEnabled
        public String houseNumber;
        @AuraEnabled
        public String houseLetter;
        @AuraEnabled
        public String municipalityNumber; // not in use
        @AuraEnabled
        public String recId; // not in use
        @AuraEnabled
        public String region;
        @AuraEnabled
        public String utilityUnitNumber; // not in use
        @AuraEnabled
        public String zipCode;
        @AuraEnabled
        public String type; // Bosted, delt bosted, opphold

        // Includes coordinates
        @TestVisible
        private void setOppholdsAddressFieldsFromVegAdresse(PDL_Vegadresse vegAddr) {
            this.address = safeUpperCase(vegAddr.adressenavn);
            this.houseNumber = safeUpperCase(vegAddr.husnummer);
            this.houseLetter = safeUpperCase(vegAddr.husbokstav);
            this.zipCode = vegAddr.postnummer;
            this.municipalityNumber = vegAddr.kommunenummer;
            this.coordinates = JSON.serialize(vegAddr.koordinater);
        }

        // Includes coordinates
        @TestVisible
        private void setOppholdsAddressFieldsFromMatrikkelAdresse(PDL_Matrikkeladresse matAddr) {
            this.zipCode = matAddr.postnummer;
            this.municipalityNumber = matAddr.kommunenummer;
            this.coordinates = JSON.serialize(matAddr.koordinater);
        }

        @TestVisible
        private void setOppholdsAddressFieldsFromUtenlandskAdresse(PDL_UtenlandskAdresse utenlandsAddr) {
            this.address = createOppholdsAddressFromUtenlandskAdresse(
                new List<String>{
                    utenlandsAddr.adressenavnNummer,
                    utenlandsAddr.bygningEtasjeLeilighet,
                    utenlandsAddr.postboksNummerNavn
                }
            );
            this.zipCode = utenlandsAddr.postkode;
            this.city = utenlandsAddr.bysted;
            this.region = utenlandsAddr.regionDistriktOmraade;
            this.countryCode = utenlandsAddr.landkode;
        }

        @TestVisible
        private void setFieldsFromVegAdresse(PDL_Vegadresse vegAddr) {
            this.address = safeUpperCase(vegAddr.adressenavn);
            this.utilityUnitNumber = safeUpperCase(vegAddr.bruksenhetsnummer);
            this.zipCode = vegAddr.postnummer;
            this.additionalName = safeUpperCase(vegAddr.tilleggsnavn);
            this.houseLetter = safeUpperCase(vegAddr.husbokstav);
            this.houseNumber = safeUpperCase(vegAddr.husnummer);
        }

        @TestVisible
        private void setFieldsFromMatrikkelAdresse(PDL_Matrikkeladresse matAddr) {
            this.utilityUnitNumber = safeUpperCase(matAddr.bruksenhetsnummer);
            this.zipCode = matAddr.postnummer;
            this.additionalName = safeUpperCase(matAddr.tilleggsnavn);
        }

        @TestVisible
        private void setFieldsFromUtenlandskAdresse(PDL_UtenlandskAdresse utenlandsAddr) {
            this.address = safeUpperCase(utenlandsAddr.adressenavnNummer);
            this.utilityUnitNumber = safeUpperCase(utenlandsAddr.bygningEtasjeLeilighet);
            this.zipCode = utenlandsAddr.postkode;
            this.city = safeUpperCase(utenlandsAddr.bySted);
            this.region = safeUpperCase(utenlandsAddr.regionDistriktOmraade);
            this.countryCode = safeUpperCase(utenlandsAddr.landkode);
        }

        @TestVisible
        private void setBostedVegMatrikkAddress(PDL_Bostedsadresse address) {
            if (address?.vegadresse != null) {
                this.setFieldsFromVegAdresse(address.vegadresse);
            } else if (address?.matrikkeladresse != null) {
                this.setFieldsFromMatrikkelAdresse(address.matrikkeladresse);
            }

            PDL_Metadata meta = address?.metadata;
            if (meta != null) {
                this.changeRegisteredDate = HOT_AddressController.formatDateString(
                    String.valueOf(HOT_AddressController.getLastUpdateDate(meta).date())
                );
            }
        }

        @TestVisible
        private void setOppholdsAddress(PDL_Oppholdsadresse address) {
            if (address?.vegadresse != null) {
                this.setFieldsFromVegAdresse(address.vegadresse);
            } else if (address?.matrikkeladresse != null) {
                this.setFieldsFromMatrikkelAdresse(address.matrikkeladresse);
            } else if (address?.utenlandskAdresse != null) {
                this.setFieldsFromUtenlandskAdresse(address.utenlandskAdresse);
            }
            PDL_Metadata meta = address?.metadata;
            if (meta != null) {
                this.changeRegisteredDate = HOT_AddressController.formatDateString(
                    String.valueOf(meta.endringer[0]?.registrert.date())
                );
            }
            this.type = 'OPPHOLDSADRESSE';
        }

        @TestVisible
        private void setDeltBostedsAddress(PDL_DeltBosted address) {
            if (address?.vegadresse != null) {
                this.setFieldsFromVegAdresse(address.vegadresse);
            } else if (address?.matrikkeladresse != null) {
                this.setFieldsFromMatrikkelAdresse(address.matrikkeladresse);
            }
            PDL_Metadata meta = address?.metadata;
            if (meta != null) {
                this.changeRegisteredDate = HOT_AddressController.formatDateString(
                    String.valueOf(meta.endringer[0]?.registrert.date())
                );
            }
            this.type = 'DELT BOSTED';
        }
    }
}
