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

        // Default constructor
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
        public String p_fodsels_nummer { get; set; }
        @AuraEnabled
        public brukerNrInnerWrapper p_Brukerinfojson { get; set; }

        // Parameterized constructor
        public brukerNrWrapper(String p_fodsels_nummer, brukerNrInnerWrapper p_Brukerinfojson) {
            this.p_fodsels_nummer = p_fodsels_nummer;
            this.p_Brukerinfojson = p_Brukerinfojson;
        }
    }

    public class brukerNrInnerWrapper {
        @AuraEnabled
        public String brukerNummer { get; set; }
        @AuraEnabled
        public String brukerStatus { get; set; }
        @AuraEnabled
        public String fnr { get; set; }
        @AuraEnabled
        public String fnrStatus { get; set; }

        // Parameterized constructor
        public brukerNrInnerWrapper(String brukerNummer, String brukerStatus, String fnr, String fnrStatus) {
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
        public List<orderLineWrapper> orderLineList { get; set; }

        // Default constructor
        public orderWrapper() {
            orderLineList = new List<orderLineWrapper>();
        }

        // Parameterized constructor
        public orderWrapper(
            String orgId,
            String ordreNummer,
            String fnr,
            String brukerNummer,
            String ordreDato,
            String status,
            List<orderLineWrapper> orderLineList
        ) {
            this.orgId = orgId;
            this.ordreNummer = ordreNummer;
            this.fnr = fnr;
            this.brukerNummer = brukerNummer;
            this.ordreDato = ordreDato;
            this.status = status;
            this.orderLineList = (orderLineList == null) ? new List<orderLineWrapper>() : orderLineList;
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
        public List<notatWrapper> sfNotaterList { get; set; }

        // Default constructor
        public SFWrapper() {
            sfNotaterList = new List<notatWrapper>();
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
            List<orderLineWrapper> sfNotater
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
            this.sfNotaterList = (sfNotaterList == null) ? new List<notatWrapper>() : sfNotaterList;
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
            return null;
        }

        // gjennomfør callout og hent ut responsen
        String responseBody = performCallout(pathParamMap, apiName);
        if (String.isBlank(responseBody) || responseBody == null) {
            return null;
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
            //.setSystemContext()
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
            system.debug('Brukernr: ' + result);
        } else {
            brukerPassWrapper result = (brukerPassWrapper) JSON.deserialize(responseBody, brukerPassWrapper.class);
            wrapper.brukerPass = result;
            system.debug('Brukerass: ' + result);
        }
        return wrapper;
    }

    private static oebsWrapper deserializeOrderResponse(String responseBody) {
        /*oebsWrapper wrapper = new oebsWrapper();
        List<orderWrapper> orderList = new List<orderWrapper>();
        List<Object> outerList = new List<Object>();
        List<Object> innerList = new List<Object>();

        Object rawOuterOrder = JSON.deserializeUntyped(responseBody);
        if (rawOuterOrder != null) {
            if (rawOuterOrder instanceof List<Object>) {
                outerList = (List<Object>) rawOuterOrder;
            } else {
                outerList.add(rawOuterOrder);
            }
        }
        if (outerList.size() == 0) {
            return null;
        } else {
            for (Object outerOrder : outerList) {
                Map<String, Object> outerMap = (Map<String, Object>) outerOrder;
                orderWrapper oWrapper = new orderWrapper();
                oWrapper.orgId = (String) outerMap.get('orgId');
                oWrapper.ordreNummer = (String) outerMap.get('ordreNummer');
                oWrapper.fnr = (String) outerMap.get('fnr');
                oWrapper.brukerNummer = (String) outerMap.get('brukerNummer');
                oWrapper.ordreDato = (String) outerMap.get('ordreDato');
                oWrapper.status = (String) outerMap.get('status');

                // Order Inner (liste eller enkeltobjekt)
                Object rawInnerOrder = outerMap.get('ordreLinjer');
                if (rawInnerOrder != null) {
                    if (rawInnerOrder instanceof List<Object>) {
                        innerList = (List<Object>) rawInnerOrder;
                    } else {
                        innerList.add(rawInnerOrder);
                    }
                }
                for (Object innerOrder : innerList) {
                    Map<String, Object> innerMap = (Map<String, Object>) innerOrder;
                    orderLineWrapper lWrapper;
                    lWrapper.ordreLinjeNummer = (String) innerMap.get('ordreLinjeNummer');
                    lWrapper.artikkel = (String) innerMap.get('artikkel');
                    lWrapper.artikkelBeskrivelse = (String) innerMap.get('artikkelBeskrivelse');
                    lWrapper.antall = (String) innerMap.get('antall');
                    lWrapper.ordreLinjeDato = (String) innerMap.get('ordreLinjeDato');
                    lWrapper.lovetDato = (String) innerMap.get('lovetDato');
                    lWrapper.planlagtSkipningsDato = (String) innerMap.get('planlagtSkipningsDato');
                    lWrapper.statusOrdreLinje = (String) innerMap.get('statusOrdreLinje');
                    lWrapper.anmodningsNummer = (String) innerMap.get('anmodningsNummer');
                    lWrapper.bestillingsNummer = (String) innerMap.get('bestillingsNummer');
                    lWrapper.leveringsadresse = (String) innerMap.get('leveringsadresse');
                    lWrapper.city = (String) innerMap.get('by');
                    lWrapper.postNummer = (String) innerMap.get('postNummer');
                    lWrapper.kommune = (String) innerMap.get('kommune');
                    lWrapper.bydel = (String) innerMap.get('bydel');
                    oWrapper.orderLineList.add(lWrapper);
                }
                orderList.add(oWrapper);
            }
            if (orderList.isEmpty()) {
                return null;
            } else {
                wrapper.orderList = orderList;
                return wrapper;
            }
        }*/

        oebsWrapper wrapper = new oebsWrapper();
        orderWrapper result = (orderWrapper) JSON.deserialize(responseBody, orderWrapper.class);
        system.debug('result: ' + result);
        //wrapper.orderList = result;
        return wrapper;
    }

    private static oebsWrapper deserializeServiceReqResponse(String responseBody) {
        oebsWrapper wrapper = new oebsWrapper();
        List<SFWrapper> SFList = new List<SFWrapper>();
        List<Object> outerList = new List<Object>();
        List<Object> innerList = new List<Object>();

        Object rawOuterOrder = JSON.deserializeUntyped(responseBody);
        if (rawOuterOrder != null) {
            if (rawOuterOrder instanceof List<Object>) {
                outerList = (List<Object>) rawOuterOrder;
            } else {
                outerList.add(rawOuterOrder);
            }
        }
        if (outerList.size() == 0) {
            return null;
        } else {
            for (Object outerOrder : outerList) {
                Map<String, Object> outerMap = (Map<String, Object>) outerOrder;
                SFWrapper sfWrapper = new SFWrapper();
                sfWrapper.orgId = (String) outerMap.get('orgId');
                sfWrapper.sfNummer = (String) outerMap.get('sfNummer');
                sfWrapper.sfType = (String) outerMap.get('sfType');
                sfWrapper.problemSammendrag = (String) outerMap.get('problemSammendrag');
                sfWrapper.losningSammendrag = (String) outerMap.get('løsningSammendrag');
                sfWrapper.fnr = (String) outerMap.get('fnr');
                sfWrapper.brukerNummer = (String) outerMap.get('brukerNummer');
                sfWrapper.sfOpprettetDato = (String) outerMap.get('sfOpprettetDato');
                sfWrapper.status = (String) outerMap.get('status');

                // Service Forespørsel Inner (liste eller enkeltobjekt)
                Object rawInnerOrder = outerMap.get('sfNotater');
                if (rawInnerOrder != null) {
                    if (rawInnerOrder instanceof List<Object>) {
                        innerList = (List<Object>) rawInnerOrder;
                    } else {
                        innerList.add(rawInnerOrder);
                    }
                }
                for (Object innerOrder : innerList) {
                    Map<String, Object> innerMap = (Map<String, Object>) innerOrder;
                    notatWrapper nWrapper;
                    nWrapper.notat = (String) innerMap.get('notat');
                    nWrapper.opprettetDato = (String) innerMap.get('opprettetDato');
                    nWrapper.opprettetAvNavn = (String) innerMap.get('opprettetAvNavn');
                    nWrapper.opprettetAvIdent = (String) innerMap.get('opprettetAvIdent');
                    sfWrapper.sfNotaterList.add(nWrapper);
                }
                SFList.add(sfWrapper);
            }
            if (SFList.isEmpty()) {
                return null;
            } else {
                wrapper.serviceRequestList = SFList;
                return wrapper;
            }
        }
    }

    private static oebsWrapper deserializeServiceOrderResponse(String responseBody) {
        oebsWrapper wrapper = new oebsWrapper();
        List<SOWrapper> SOList = new List<SOWrapper>();
        List<Object> innerList = new List<Object>();

        Object rawInnerSO = JSON.deserializeUntyped(responseBody);
        if (rawInnerSO != null) {
            if (rawInnerSO instanceof List<Object>) {
                innerList = (List<Object>) rawInnerSO;
            } else {
                innerList.add(rawInnerSO);
            }
        }
        if (innerList.size() == 0) {
            return null;
        } else {
            for (Object innerSO : innerList) {
                Map<String, Object> innerMap = (Map<String, Object>) innerSO;
                SOWrapper soWrapper;
                soWrapper.serviceOrdreNummer = (String) innerMap.get('serviceOrdreNummer');
                soWrapper.serviceType = (String) innerMap.get('serviceType');
                soWrapper.sfNummer = (String) innerMap.get('sfNummer');
                soWrapper.opprettelsesDato = (String) innerMap.get('opprettelsesDato');
                soWrapper.artikkel = (String) innerMap.get('artikkel');
                soWrapper.artikkelBeskrivelse = (String) innerMap.get('artikkelBeskrivelse');
                soWrapper.serviceOrdreStatus = (String) innerMap.get('serviceOrdreStatus');
                soWrapper.fnr = (String) innerMap.get('fnr');
                soWrapper.brukernr = (String) innerMap.get('brukernr');
                SOList.add(soWrapper);
            }
            if (SOList.isEmpty()) {
                return null;
            } else {
                wrapper.serviceOrderList = SOList;
                return wrapper;
            }
        }
    }
}
