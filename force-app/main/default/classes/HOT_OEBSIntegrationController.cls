public with sharing class HOT_OEBSIntegrationController {
    // Topp-nivå wrapper for hver "integrasjon"
    public class oebsWrapper {
        @AuraEnabled
        public brukerNrWrapper brukerNr { get; set; }
        @AuraEnabled
        public brukerPassWrapper brukerPass { get; set; }
        @AuraEnabled
        public List<orderWrapper> orderList { get; set; }
        @AuraEnabled
        public List<SFWrapper> serviceRequestList { get; set; }
        @AuraEnabled
        public List<SOWrapper> serviceOrderList { get; set; }

        public oebsWrapper() {
            orderList = new List<orderWrapper>();
            serviceRequestList = new List<SFWrapper>();
            serviceOrderList = new List<SOWrapper>();
        }
    }

    public class brukerNrWrapper {
        @AuraEnabled
        public String brukerNummer;
        @AuraEnabled
        public String brukerStatus;
        @AuraEnabled
        public String fnr;
        @AuraEnabled
        public String fnrStatus;
    }

    public class brukerPassWrapper {
        @AuraEnabled
        public String fnr;
        @AuraEnabled
        public String brukerNummer;
        @AuraEnabled
        public String kontrakt_nummer;
        @AuraEnabled
        public String sjekk_navn;
        @AuraEnabled
        public String start_date;
        @AuraEnabled
        public String end_date;
        @AuraEnabled
        public String status;
    }

    public class orderWrapper {
        @AuraEnabled
        public String orgId;
        @AuraEnabled
        public String ordreNummer;
        @AuraEnabled
        public String fnr;
        @AuraEnabled
        public String brukerNummer;
        @AuraEnabled
        public String ordreDato;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public List<orderLineWrapper> ordreLinjer { get; set; }
    }

    public class SOWrapper {
        @AuraEnabled
        public String serviceOrdreNummer;
        @AuraEnabled
        public String serviceType;
        @AuraEnabled
        public String sfNummer;
        @AuraEnabled
        public String opprettelsesDato;
        @AuraEnabled
        public String artikkel;
        @AuraEnabled
        public String artikkelBeskrivelse;
        @AuraEnabled
        public String serviceOrdreStatus;
        @AuraEnabled
        public String fnr;
        @AuraEnabled
        public String brukernr;
    }

    public class SFWrapper {
        @AuraEnabled
        public String orgId;
        @AuraEnabled
        public String sfNummer;
        @AuraEnabled
        public String sfType;
        @AuraEnabled
        public String problemSammendrag;
        @AuraEnabled
        public String losningSammendrag;
        @AuraEnabled
        public String fnr;
        @AuraEnabled
        public String brukerNummer;
        @AuraEnabled
        public String sfOpprettetDato;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public List<notatWrapper> sfNotater { get; set; }
    }

    public class orderLineWrapper {
        @AuraEnabled
        public String ordreLinjeNummer;
        @AuraEnabled
        public String artikkel;
        @AuraEnabled
        public String artikkelBeskrivelse;
        @AuraEnabled
        public String antall;
        @AuraEnabled
        public String ordreLinjeDato;
        @AuraEnabled
        public String lovetDato;
        @AuraEnabled
        public String planlagtSkipningsDato;
        @AuraEnabled
        public String statusOrdreLinje;
        @AuraEnabled
        public String anmodningsNummer;
        @AuraEnabled
        public String bestillingsNummer;
        @AuraEnabled
        public String leveringsadresse;
        @AuraEnabled
        public String city;
        @AuraEnabled
        public String postNummer;
        @AuraEnabled
        public String kommune;
        @AuraEnabled
        public String bydel;
    }

    public class notatWrapper {
        @AuraEnabled
        public String notat;
        @AuraEnabled
        public String opprettetDato;
        @AuraEnabled
        public String opprettetAvNavn;
        @AuraEnabled
        public String opprettetAvIdent;
    }

    @AuraEnabled(cacheable=true)
    public static oebsWrapper HOT_OEBS_Integration(Id recordId, String objectApiName, String apiName) {
        List<oebsWrapper> wrapperList = new List<oebsWrapper>();
        oebsWrapper wrapper = new oebsWrapper();

        // Henter fnr nummer basert på objekt type og bygger opp path parameter for API callout med fnr
        String fnr = fetchPersonIdent(recordId, objectApiName);
        Map<String, String> pathParamMap = new Map<String, String>();
        pathParamMap.put('fnr', fnr);
        if (String.isBlank(fnr)) {
            // Hvis vi ikke finner fnr, returner en tom liste
            return wrapper;
        }

        // gjennomfør callout og hent ut responsen
        String responseBody = performCallout(pathParamMap, apiName);
        if (String.isBlank(responseBody) || responseBody == null) {
            return wrapper;
        }

        //deserialize og bygg wrapper basert på responsen
        if (apiName == 'GET_OEBS_Brukernr' || apiName == 'GET_OEBS_BrukerPass') {
            wrapper = deserializeBrukerResponse(responseBody, apiName);
        } else if (apiName == 'GET_OEBS_Ordre') {
            wrapper = deserializeOrderResponse(responseBody);
        } else if (apiName == 'GET_OEBS_SF') {
            wrapper = deserializeServiceReqResponse(responseBody);
        } else if (apiName == 'GET_OEBS_SO') {
            wrapper = deserializeServiceOrderResponse(responseBody);
        }
        return wrapper;
    }

    @TestVisible
    private static String fetchPersonIdent(Id recordId, String objectApiName) {
        Id personId = getPersonId(recordId, objectApiName);
        if (personId == null) {
            return null;
        }
        return [SELECT Name FROM Person__c WHERE Id = :personId].Name;
    }

    private static Id getPersonId(Id recordId, String objectApiName) {
        if (objectApiName == 'Case') {
            return [SELECT Account.CRM_Person__c FROM Case WHERE Id = :recordId].Account.CRM_Person__c;
        } else if (objectApiName == 'Account') {
            return [SELECT CRM_Person__c FROM Account WHERE Id = :recordId].CRM_Person__c;
        } else if (objectApiName == 'Person__c') {
            return recordId;
        }
        return null;
    }

    private static String performCallout(Map<String, String> pathParamMap, String apiName) {
        // Opprett og konfigurer ApiController
        LoggerUtility logger = new LoggerUtility('HOT');
        ApiController ac = new ApiController()
            .setLogCategory('HOT')
            .setLogger(logger)
            .setLogCalloutRequest()
            .publishLogAfterCallout()
            .setLogDomain(CRM_ApplicationDomain.Domain.HOT);

        ac.initRequest('OEBS', apiName, pathParamMap);
        ac.addSaasProxyServiceAuthHeader();

        // Legg til ekstra headers
        String transactionId = String.valueOf(Crypto.getRandomLong());
        ac.setLogUuid(transactionId);
        ac.setHeaders(new Map<String, String>{ 'Nav-CallId' => transactionId, 'Content-Type' => 'application/json' });

        // Utfør kall
        ac.doCallout();
        String responseBody = ac.getResponse().getBody();
        Integer responseStatusCode = ac.getResponse().getStatusCode();
        if (responseStatusCode != 200) {
            String errorMessage = 'StatusCode: ' + responseStatusCode.toString() + '    -    ' + responseBody;
            System.debug('ErrorMessage: ' + errorMessage);
            LoggerUtility warning = new LoggerUtility();
            warning.warning(errorMessage, null, CRM_ApplicationDomain.Domain.HOT);
            warning.publish();
            return null;
        } else {
            return responseBody;
        }
    }

    private static oebsWrapper deserializeBrukerResponse(String responseBody, String apiName) {
        oebsWrapper wrapper = new oebsWrapper();
        if (apiName == 'GET_OEBS_Brukernr') {
            try {
                brukerNrWrapper result = (brukerNrWrapper) JSON.deserialize(responseBody, brukerNrWrapper.class);
                wrapper.brukerNr = result;
            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        } else {
            try {
                brukerPassWrapper result = (brukerPassWrapper) JSON.deserialize(responseBody, brukerPassWrapper.class);
                wrapper.brukerPass = result;
            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
        return wrapper;
    }

    private static oebsWrapper deserializeOrderResponse(String responseBody) {
        oebsWrapper wrapper = new oebsWrapper();
        try {
            system.debug('responsebody: ' + responseBody);
            List<orderWrapper> wrappers = (List<orderWrapper>) JSON.deserialize(responseBody, List<orderWrapper>.class);
            wrapper.orderList = wrappers;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return wrapper;
    }

    private static oebsWrapper deserializeServiceReqResponse(String responseBody) {
        oebsWrapper wrapper = new oebsWrapper();
        try {
            List<SFWrapper> wrappers = (List<SFWrapper>) JSON.deserialize(responseBody, List<SFWrapper>.class);
            wrapper.serviceRequestList = wrappers;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return wrapper;
    }

    private static oebsWrapper deserializeServiceOrderResponse(String responseBody) {
        oebsWrapper wrapper = new oebsWrapper();
        try {
            List<SOWrapper> wrappers = (List<SOWrapper>) JSON.deserialize(responseBody, List<SOWrapper>.class);
            wrapper.serviceOrderList = wrappers;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return wrapper;
    }
}
