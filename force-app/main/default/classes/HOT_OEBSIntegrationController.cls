public with sharing class HOT_OEBSIntegrationController {
    // Topp-nivå wrapper for hver "integrasjon"
    public class oebsWrapper {
        @AuraEnabled
        public brukerNrWrapper brukerNr;
        @AuraEnabled
        public brukerPassWrapper brukerPass;
        @AuraEnabled
        public List<orderWrapper> orderList;
        @AuraEnabled
        public List<SFWrapper> serviceRequestList;
        @AuraEnabled
        public List<SOWrapper> serviceOrderList;
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
        public List<orderLineWrapper> orderLineList { get; set; }

        public orderWrapper() {
            orderLineList = new List<orderLineWrapper>();
        }
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

        public SFWrapper() {
            sfNotater = new List<notatWrapper>();
        }
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
        brukerNrWrapper bWrapper = new brukerNrWrapper();
        brukerPassWrapper bpWrapper = new brukerPassWrapper();
        oebsWrapper wrapper = new oebsWrapper();
        Map<String, Object> rootMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        if (rootMap == null) {
            return wrapper;
        } else {
            if (apiName == 'GET_OEBS_Brukernr') {
                bWrapper.brukerNummer = (String) rootMap.get('brukerNummer');
                bWrapper.brukerStatus = (String) rootMap.get('brukerStatus');
                bWrapper.fnr = (String) rootMap.get('fnr');
                bWrapper.fnrStatus = (String) rootMap.get('fnrStatus');
                wrapper.brukerNr = bWrapper;
            } else if (apiName == 'GET_OEBS_BrukerPass') {
                bpWrapper.fnr = (String) rootMap.get('fnr');
                bpWrapper.brukerNummer = (String) rootMap.get('brukerNummer');
                bpWrapper.kontrakt_nummer = (String) rootMap.get('kontrakt_nummer');
                bpWrapper.sjekk_navn = (String) rootMap.get('sjekk_navn');
                bpWrapper.start_date = (String) rootMap.get('start_date');
                bpWrapper.end_date = (String) rootMap.get('end_date');
                bpWrapper.status = (String) rootMap.get('status');
                wrapper.brukerPass = bpWrapper;
            }
        }
        return wrapper;
    }

    private static oebsWrapper deserializeOrderResponse(String responseBody) {
        oebsWrapper wrapper = new oebsWrapper();
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
            return wrapper;
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
                    orderLineWrapper lWrapper = new orderLineWrapper();
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
                    lWrapper.city = (String) innerMap.get('city');
                    lWrapper.postNummer = (String) innerMap.get('postNummer');
                    lWrapper.kommune = (String) innerMap.get('kommune');
                    lWrapper.bydel = (String) innerMap.get('bydel');
                    oWrapper.orderLineList.add(lWrapper);
                }
                orderList.add(oWrapper);
            }
            if (orderList.isEmpty()) {
                return wrapper;
            } else {
                wrapper.orderList = orderList;
                return wrapper;
            }
        }
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
            return wrapper;
        } else {
            for (Object outerOrder : outerList) {
                Map<String, Object> outerMap = (Map<String, Object>) outerOrder;
                SFWrapper sfWrapper = new SFWrapper();
                sfWrapper.orgId = (String) outerMap.get('orgId');
                sfWrapper.sfNummer = (String) outerMap.get('sfNummer');
                sfWrapper.sfType = (String) outerMap.get('sfType');
                sfWrapper.problemSammendrag = (String) outerMap.get('problemSammendrag');
                String tempLos = (String) outerMap.get('losningSammendrag');
                if (tempLos == null || tempLos == '') {
                    sfWrapper.losningSammendrag = (String) outerMap.get('løsningSammendrag');
                } else {
                    sfWrapper.losningSammendrag = tempLos;
                }
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
                    notatWrapper nWrapper = new notatWrapper();
                    nWrapper.notat = (String) innerMap.get('notat');
                    nWrapper.opprettetDato = (String) innerMap.get('opprettetDato');
                    nWrapper.opprettetAvNavn = (String) innerMap.get('opprettetAvNavn');
                    nWrapper.opprettetAvIdent = (String) innerMap.get('opprettetAvIdent');
                    sfWrapper.sfNotater.add(nWrapper);
                }
                SFList.add(sfWrapper);
            }
            if (SFList.isEmpty()) {
                return wrapper;
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
            return wrapper;
        } else {
            for (Object innerSO : innerList) {
                Map<String, Object> innerMap = (Map<String, Object>) innerSO;
                SOWrapper soWrapper = new SOWrapper();
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
                return wrapper;
            } else {
                wrapper.serviceOrderList = SOList;
                return wrapper;
            }
        }
    }
}
