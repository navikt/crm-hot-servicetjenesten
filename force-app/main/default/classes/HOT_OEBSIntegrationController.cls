public with sharing class HOT_OEBSIntegrationController {
    // Topp-nivå wrapper for hver "integrasjon"
    public class oebsWrapper {
        public brukerNrWrapper brukerNr;
        public brukerPassWrapper brukerPass;
        public List<orderWrapper> orderList;
        public List<SFWrapper> serviceRequestList;
        public List<SOWrapper> serviceOrderList;
    }

    public class brukerNrWrapper {
        public String brukerNummer;
        public String brukerStatus;
        public String fnr;
        public String fnrStatus;
    }

    public class brukerPassWrapper {
        public String fnr;
        public String brukerNummer;
        public String kontrakt_nummer;
        public String sjekk_navn;
        public String start_date;
        public String end_date;
        public String status;
    }

    public class orderWrapper {
        public String orgId;
        public String ordreNummer;
        public String fnr;
        public String brukerNummer;
        public String ordreDato;
        public String status;
        public List<orderLineWrapper> orderLineList { get; set; }

        public orderWrapper() {
            orderLineList = new List<orderLineWrapper>();
        }
    }

    public class SOWrapper {
        public String serviceOrdreNummer;
        public String serviceType;
        public String sfNummer;
        public String opprettelsesDato;
        public String artikkel;
        public String artikkelBeskrivelse;
        public String serviceOrdreStatus;
        public String fnr;
        public String brukernr;
    }

    public class SFWrapper {
        public String orgId;
        public String sfNummer;
        public String sfType;
        public String problemSammendrag;
        public String losningSammendrag;
        public String fnr;
        public String brukerNummer;
        public String sfOpprettetDato;
        public String status;
        public List<notatWrapper> sfNotater { get; set; }

        public SFWrapper() {
            sfNotater = new List<notatWrapper>();
        }
    }

    public class orderLineWrapper {
        public String ordreLinjeNummer;
        public String artikkel;
        public String artikkelBeskrivelse;
        public String antall;
        public String ordreLinjeDato;
        public String lovetDato;
        public String planlagtSkipningsDato;
        public String statusOrdreLinje;
        public String anmodningsNummer;
        public String bestillingsNummer;
        public String leveringsadresse;
        public String city;
        public String postNummer;
        public String kommune;
        public String bydel;
    }

    public class notatWrapper {
        public String notat;
        public String opprettetDato;
        public String opprettetAvNavn;
        public String opprettetAvIdent;
    }

    public static List<oebsWrapper> HOT_OEBS_Integration(Id recordId, String objectApiName, String apiName) {
        List<oebsWrapper> wrapperList = new List<oebsWrapper>();
        List<orderWrapper> orderList = new List<orderWrapper>();
        List<SOWrapper> SOList = new List<SOWrapper>();
        List<SFWrapper> SFList = new List<SFWrapper>();
        Map<String, Object> rootMap = new Map<String, Object>();
        Map<String, Object> dataMap = new Map<String, Object>();
        List<Object> innerList = new List<Object>();
        List<Object> outerList = new List<Object>();

        // Henter fnr nummer basert på objekt type og bygger opp path parameter for API callout med fnr
        String fnr = fetchPersonIdent(recordId, objectApiName);
        Map<String, String> pathParamMap = new Map<String, String>();
        pathParamMap.put('fnr', fnr);
        if (String.isBlank(fnr)) {
            // Hvis vi ikke finner fnr, returner en tom liste
            return wrapperList;
        }

        // 2) Opprett og konfigurer ApiController
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

        // 3) Utfør kall
        ac.doCallout();
        String responseBody = ac.getResponse().getBody();

        // 4) Analyser og bygg wrapper-objekter
        // Sjekk for tom/blank respons før parsing
        if (String.isBlank(responseBody)) {
            return wrapperList;
        }

        //deserialize og bygg wrapper basert på callout
        if (apiName == 'GET_OEBS_Brukernr') {
            // Deserialize
            rootMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            dataMap = (Map<String, Object>) rootMap.get('p_Brukerinfojson');

            // Set up output
            if (dataMap == null) {
                return wrapperList;
            } else {
                brukerNrWrapper bWrapper = new brukerNrWrapper();
                oebsWrapper Wrapper = new oebsWrapper();
                bWrapper.brukerNummer = (String) dataMap.get('brukerNummer');
                bWrapper.brukerStatus = (String) dataMap.get('brukerStatus');
                bWrapper.fnr = (String) dataMap.get('fnr');
                bWrapper.fnrStatus = (String) dataMap.get('fnrStatus');
                wrapper.brukerNr = bWrapper;
                wrapperList.add(wrapper);
            }
        } else if (apiName == 'GET_OEBS_BrukerPass') {
            // Deserialize
            rootMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            // Set up output
            if (rootMap == null) {
                return wrapperList;
            } else {
                oebsWrapper wrapper = new oebsWrapper();
                brukerPassWrapper bWrapper = new brukerPassWrapper();
                bWrapper.fnr = (String) rootMap.get('fnr');
                bWrapper.brukerNummer = (String) rootMap.get('brukerNummer');
                bWrapper.kontrakt_nummer = (String) rootMap.get('kontrakt_nummer');
                bWrapper.sjekk_navn = (String) rootMap.get('sjekk_navn');
                bWrapper.start_date = (String) rootMap.get('start_date');
                bWrapper.end_date = (String) rootMap.get('end_date');
                bWrapper.status = (String) rootMap.get('status');
                wrapper.brukerPass = bWrapper;
                wrapperList.add(wrapper);
            }
        } else if (apiName == 'GET_OEBS_Ordre') {
            // Deserialize
            rootMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            // Order outer (liste eller enkeltobjekt)
            Object rawOuterOrder = rootMap.get('p_Ordreinfojson');
            if (rawOuterOrder != null) {
                if (rawOuterOrder instanceof List<Object>) {
                    outerList = (List<Object>) rawOuterOrder;
                } else {
                    outerList.add(rawOuterOrder);
                }
            }
            if (outerList.size() == 0) {
                return wrapperList;
            } else {
                for (Object outerOrder : outerList) {
                    Map<String, Object> outerMap = (Map<String, Object>) outerOrder;
                    orderWrapper wrapper = new orderWrapper();
                    wrapper.orgId = (String) outerMap.get('orgId');
                    wrapper.ordreNummer = (String) outerMap.get('ordreNummer');
                    wrapper.fnr = (String) outerMap.get('fnr');
                    wrapper.brukerNummer = (String) outerMap.get('brukerNummer');
                    wrapper.ordreDato = (String) outerMap.get('ordreDato');
                    wrapper.status = (String) outerMap.get('status');

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
                        lWrapper.city = (String) innerMap.get('by');
                        lWrapper.postNummer = (String) innerMap.get('postNummer');
                        lWrapper.kommune = (String) innerMap.get('kommune');
                        lWrapper.bydel = (String) innerMap.get('bydel');
                        wrapper.orderLineList.add(lWrapper);
                    }
                    orderList.add(wrapper);
                }
                if (orderList.isEmpty()) {
                    return null;
                } else {
                    oebsWrapper wrapper = new oebsWrapper();
                    wrapper.orderList = orderList;
                    wrapperList.add(wrapper);
                }
            }
        } else if (apiName == 'GET_OEBS_SF') {
            // Deserialize
            rootMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            // Service Forespørsel outer (liste eller enkeltobjekt)
            Object rawOuterOrder = rootMap.get('p_SFinfojson');
            if (rawOuterOrder != null) {
                if (rawOuterOrder instanceof List<Object>) {
                    outerList = (List<Object>) rawOuterOrder;
                } else {
                    outerList.add(rawOuterOrder);
                }
            }
            if (outerList.size() == 0) {
                return wrapperList;
            } else {
                for (Object outerOrder : outerList) {
                    Map<String, Object> outerMap = (Map<String, Object>) outerOrder;
                    SFWrapper wrapper = new SFWrapper();
                    wrapper.orgId = (String) outerMap.get('orgId');
                    wrapper.sfNummer = (String) outerMap.get('sfNummer');
                    wrapper.sfType = (String) outerMap.get('sfType');
                    wrapper.problemSammendrag = (String) outerMap.get('problemSammendrag');
                    wrapper.losningSammendrag = (String) outerMap.get('løsningSammendrag');
                    wrapper.fnr = (String) outerMap.get('fnr');
                    wrapper.brukerNummer = (String) outerMap.get('brukerNummer');
                    wrapper.sfOpprettetDato = (String) outerMap.get('sfOpprettetDato');
                    wrapper.status = (String) outerMap.get('status');

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
                        wrapper.sfNotater.add(nWrapper);
                    }
                    SFList.add(wrapper);
                }
                if (SFList.isEmpty()) {
                    return null;
                } else {
                    oebsWrapper wrapper = new oebsWrapper();
                    wrapper.serviceRequestList = SFList;
                    wrapperList.add(wrapper);
                }
            }
        } else if (apiName == 'GET_OEBS_SO') {
            // Deserialize
            rootMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            // Service Order Inner (liste eller enkeltobjekt)
            Object rawInnerSO = rootMap.get('p_ServiceOrdrejson');
            if (rawInnerSO != null) {
                if (rawInnerSO instanceof List<Object>) {
                    innerList = (List<Object>) rawInnerSO;
                } else {
                    innerList.add(rawInnerSO);
                }
            }
            if (innerList.size() == 0) {
                return wrapperList;
            } else {
                for (Object innerSO : innerList) {
                    Map<String, Object> innerMap = (Map<String, Object>) innerSO;
                    SOWrapper wrapper = new SOWrapper();
                    wrapper.serviceOrdreNummer = (String) innerMap.get('serviceOrdreNummer');
                    wrapper.serviceType = (String) innerMap.get('serviceType');
                    wrapper.sfNummer = (String) innerMap.get('sfNummer');
                    wrapper.opprettelsesDato = (String) innerMap.get('opprettelsesDato');
                    wrapper.artikkel = (String) innerMap.get('artikkel');
                    wrapper.artikkelBeskrivelse = (String) innerMap.get('artikkelBeskrivelse');
                    wrapper.serviceOrdreStatus = (String) innerMap.get('serviceOrdreStatus');
                    wrapper.fnr = (String) innerMap.get('fnr');
                    wrapper.brukernr = (String) innerMap.get('brukernr');
                    SOList.add(wrapper);
                }
                if (SOList.isEmpty()) {
                    return null;
                } else {
                    oebsWrapper wrapper = new oebsWrapper();
                    wrapper.serviceOrderList = SOList;
                    wrapperList.add(wrapper);
                }
            }
        }
        if (wrapperList.size() == 0) {
            return null;
        } else {
            return wrapperList;
        }
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
}
