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

        // Parameterized constructor
        public oebsWrapper(
            brukerNrWrapper brukerNr,
            brukerPassWrapper brukerPass,
            List<orderWrapper> orderList,
            List<SFWrapper> serviceRequestList,
            List<SOWrapper> serviceOrderList
        ) {
            this.brukerNr = brukerNr;
            this.brukerPass = brukerPass;
            this.orderList = (orderList == null) ? new List<orderWrapper>() : orderList;
            this.serviceRequestList = (serviceRequestList == null) ? new List<SFWrapper>() : serviceRequestList;
            this.serviceOrderList = (serviceOrderList == null) ? new List<SOWrapper>() : serviceOrderList;
        }
    }

    public class brukerNrWrapper {
        @AuraEnabled
        public String brukerNummer { get; set; }
        @AuraEnabled
        public String brukerStatus { get; set; }
        @AuraEnabled
        public String fnr { get; set; }
        @AuraEnabled
        public String fnrStatus { get; set; }

        // Parameterized constructor
        public brukerNrWrapper(String brukerNummer, String brukerStatus, String fnr, String fnrStatus) {
            this.brukerNummer = brukerNummer;
            this.brukerStatus = brukerStatus;
            this.fnr = fnr;
            this.fnrStatus = fnrStatus;
        }
    }

    public class brukerPassWrapper {
        @AuraEnabled
        public String fnr { get; set; }
        @AuraEnabled
        public String brukerNummer { get; set; }
        @AuraEnabled
        public String kontrakt_nummer { get; set; }
        @AuraEnabled
        public String sjekk_navn { get; set; }
        @AuraEnabled
        public String start_date { get; set; }
        @AuraEnabled
        public String end_date { get; set; }
        @AuraEnabled
        public String status { get; set; }

        // Parameterized constructor
        public brukerPassWrapper(
            String fnr,
            String brukerNummer,
            String kontrakt_nummer,
            String sjekk_navn,
            String start_date,
            String end_date,
            String status
        ) {
            this.fnr = fnr;
            this.brukerNummer = brukerNummer;
            this.kontrakt_nummer = kontrakt_nummer;
            this.sjekk_navn = sjekk_navn;
            this.start_date = start_date;
            this.end_date = end_date;
            this.status = status;
        }
    }

    public class orderWrapper {
        @AuraEnabled
        public String orgId { get; set; }
        @AuraEnabled
        public String ordreNummer { get; set; }
        @AuraEnabled
        public String fnr { get; set; }
        @AuraEnabled
        public String brukerNummer { get; set; }
        @AuraEnabled
        public String ordreDato { get; set; }
        @AuraEnabled
        public String status { get; set; }
        @AuraEnabled
        public List<orderLineWrapper> ordreLinjer { get; set; }

        // Default constructor
        public orderWrapper() {
            ordreLinjer = new List<orderLineWrapper>();
        }

        // Parameterized constructor
        public orderWrapper(
            String orgId,
            String ordreNummer,
            String fnr,
            String brukerNummer,
            String ordreDato,
            String status,
            List<orderLineWrapper> ordreLinjer
        ) {
            this.orgId = orgId;
            this.ordreNummer = ordreNummer;
            this.fnr = fnr;
            this.brukerNummer = brukerNummer;
            this.ordreDato = ordreDato;
            this.status = status;
            this.ordreLinjer = (ordreLinjer == null) ? new List<orderLineWrapper>() : ordreLinjer;
        }
    }

    public class SOWrapper {
        @AuraEnabled
        public String serviceOrdreNummer { get; set; }
        @AuraEnabled
        public String serviceType { get; set; }
        @AuraEnabled
        public String sfNummer { get; set; }
        @AuraEnabled
        public String opprettelsesDato { get; set; }
        @AuraEnabled
        public String artikkel { get; set; }
        @AuraEnabled
        public String artikkelBeskrivelse { get; set; }
        @AuraEnabled
        public String serviceOrdreStatus { get; set; }
        @AuraEnabled
        public String fnr { get; set; }
        @AuraEnabled
        public String brukernr { get; set; }

        // Parameterized constructor
        public SOWrapper(
            String serviceOrdreNummer,
            String serviceType,
            String sfNummer,
            String opprettelsesDato,
            String artikkel,
            String artikkelBeskrivelse,
            String fnr,
            String brukernr
        ) {
            this.serviceOrdreNummer = serviceOrdreNummer;
            this.serviceType = serviceType;
            this.sfNummer = sfNummer;
            this.opprettelsesDato = opprettelsesDato;
            this.artikkel = artikkel;
            this.artikkelBeskrivelse = artikkelBeskrivelse;
            this.fnr = fnr;
            this.brukernr = brukernr;
        }
    }

    public class SFWrapper {
        @AuraEnabled
        public String orgId { get; set; }
        @AuraEnabled
        public String sfNummer { get; set; }
        @AuraEnabled
        public String sfType { get; set; }
        @AuraEnabled
        public String problemSammendrag { get; set; }
        @AuraEnabled
        public String losningSammendrag { get; set; }
        @AuraEnabled
        public String fnr { get; set; }
        @AuraEnabled
        public String brukerNummer { get; set; }
        @AuraEnabled
        public String sfOpprettetDato { get; set; }
        @AuraEnabled
        public String status { get; set; }
        @AuraEnabled
        public List<notatWrapper> sfNotater { get; set; }

        // Default constructor
        public SFWrapper() {
            sfNotater = new List<notatWrapper>();
        }

        // Parameterized constructor
        public SFWrapper(
            String orgId,
            String sfNummer,
            String sfType,
            String problemSammendrag,
            String losningSammendrag,
            String fnr,
            String brukerNummer,
            String sfOpprettetDato,
            String status,
            List<notatWrapper> sfNotater
        ) {
            this.orgId = orgId;
            this.sfNummer = sfNummer;
            this.sfType = sfType;
            this.losningSammendrag = losningSammendrag;
            this.sfOpprettetDato = sfOpprettetDato;
            this.fnr = fnr;
            this.brukerNummer = brukerNummer;
            this.sfOpprettetDato = sfOpprettetDato;
            this.status = status;
            this.sfNotater = (sfNotater == null) ? new List<notatWrapper>() : sfNotater;
        }
    }

    public class orderLineWrapper {
        @AuraEnabled
        public String ordreLinjeNummer { get; set; }
        @AuraEnabled
        public String artikkel { get; set; }
        @AuraEnabled
        public String artikkelBeskrivelse { get; set; }
        @AuraEnabled
        public String antall { get; set; }
        @AuraEnabled
        public String ordreLinjeDato { get; set; }
        @AuraEnabled
        public String lovetDato { get; set; }
        @AuraEnabled
        public String planlagtSkipningsDato { get; set; }
        @AuraEnabled
        public String statusOrdreLinje { get; set; }
        @AuraEnabled
        public String anmodningsNummer { get; set; }
        @AuraEnabled
        public String bestillingsNummer { get; set; }
        @AuraEnabled
        public String leveringsadresse { get; set; }
        @AuraEnabled
        public String city { get; set; }
        @AuraEnabled
        public String postNummer { get; set; }
        @AuraEnabled
        public String kommune { get; set; }
        @AuraEnabled
        public String bydel { get; set; }

        // Parameterized constructor
        public orderLineWrapper(
            String ordreLinjeNummer,
            String artikkel,
            String artikkelBeskrivelse,
            String antall,
            String ordreLinjeDato,
            String lovetDato,
            String planlagtSkipningsDato,
            String statusOrdreLinje,
            String anmodningsNummer,
            String bestillingsNummer,
            String leveringsadresse,
            String city,
            String postNummer,
            String kommune,
            String bydel
        ) {
            this.ordreLinjeNummer = ordreLinjeNummer;
            this.artikkel = artikkel;
            this.artikkelBeskrivelse = artikkelBeskrivelse;
            this.antall = antall;
            this.ordreLinjeDato = ordreLinjeDato;
            this.lovetDato = lovetDato;
            this.planlagtSkipningsDato = planlagtSkipningsDato;
            this.statusOrdreLinje = statusOrdreLinje;
            this.anmodningsNummer = anmodningsNummer;
            this.bestillingsNummer = bestillingsNummer;
            this.leveringsadresse = leveringsadresse;
            this.city = city;
            this.postNummer = postNummer;
            this.kommune = kommune;
            this.bydel = bydel;
        }
    }

    public class notatWrapper {
        @AuraEnabled
        public String notat { get; set; }
        @AuraEnabled
        public String opprettetDato { get; set; }
        @AuraEnabled
        public String opprettetAvNavn { get; set; }
        @AuraEnabled
        public String opprettetAvIdent { get; set; }

        // Parameterized constructor
        public notatWrapper(String notat, String opprettetDato, String opprettetAvNavn, String opprettetAvIdent) {
            this.notat = notat;
            this.opprettetDato = opprettetDato;
            this.opprettetAvNavn = opprettetAvNavn;
            this.opprettetAvIdent = opprettetAvIdent;
        }
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
            brukerNrWrapper result = (brukerNrWrapper) JSON.deserialize(responseBody, brukerNrWrapper.class);
            wrapper.brukerNr = result;
        } else {
            brukerPassWrapper result = (brukerPassWrapper) JSON.deserialize(responseBody, brukerPassWrapper.class);
            wrapper.brukerPass = result;
        }
        return wrapper;
    }

    private static oebsWrapper deserializeOrderResponse(String responseBody) {
        oebsWrapper wrapper = new oebsWrapper();
        Object parsed = JSON.deserializeUntyped(responseBody);
        if (parsed instanceof List<Object>) {
            List<orderWrapper> wrappers = (List<orderWrapper>) JSON.deserialize(responseBody, List<orderWrapper>.class);
            wrapper.orderList = wrappers;
        } else if (parsed instanceof Map<String, Object>) {
            orderWrapper result = (orderWrapper) JSON.deserialize(responseBody, orderWrapper.class);
            wrapper.orderList = new List<orderWrapper>{ result };
        }
        return wrapper;
    }

    private static oebsWrapper deserializeServiceReqResponse(String responseBody) {
        oebsWrapper wrapper = new oebsWrapper();
        Object parsed = JSON.deserializeUntyped(responseBody);
        if (parsed instanceof List<Object>) {
            List<SFWrapper> wrappers = (List<SFWrapper>) JSON.deserialize(responseBody, List<SFWrapper>.class);
            wrapper.serviceRequestList = wrappers;
        } else if (parsed instanceof Map<String, Object>) {
            SFWrapper result = (SFWrapper) JSON.deserialize(responseBody, SFWrapper.class);
            wrapper.serviceRequestList = new List<SFWrapper>{ result };
        }
        return wrapper;
    }

    private static oebsWrapper deserializeServiceOrderResponse(String responseBody) {
        oebsWrapper wrapper = new oebsWrapper();
        Object parsed = JSON.deserializeUntyped(responseBody);
        if (parsed instanceof List<Object>) {
            List<SOWrapper> wrappers = (List<SOWrapper>) JSON.deserialize(responseBody, List<SOWrapper>.class);
            wrapper.serviceOrderList = wrappers;
        } else if (parsed instanceof Map<String, Object>) {
            SOWrapper result = (SOWrapper) JSON.deserialize(responseBody, SOWrapper.class);
            wrapper.serviceOrderList = new List<SOWrapper>{ result };
        }
        return wrapper;
    }
}
