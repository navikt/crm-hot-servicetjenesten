public with sharing class HOT_OEBSIntegrationController {
    // Topp-nivå wrapper for hver "sak"
    public class oebsWrapper {
        public String brukerNummer;
        public String brukerStatus;
        public String fnr;
        public String fnrStatus;
    }

    public static List<oebsWrapper> HOT_OEBS_Brukernummer(Id recordId, String objectApiName) {
        // Henter fnr nummer basert på objekt type
        String fnr = fetchPersonIdent(recordId, objectApiName);
        Map<String, String> pathParamMap = new Map<String, String>();
        pathParamMap.put('fnr', fnr);
        List<oebsWrapper> wrapperList = new List<oebsWrapper>();
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
            .setLogDomain(CRM_ApplicationDomain.Domain.HOT)
            .setSystemContext();

        ac.initRequest('OEBS', 'GET_OEBS_Brukernr', pathParamMap);
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
        system.debug('Response: ' + responseBody);
        Map<String, Object> rootMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        system.debug('rootMap: ' + rootMap);
        Map<String, Object> dataMap = (Map<String, Object>) rootMap.get('p_Brukerinfojson');
        system.debug('dataMap: ' + dataMap);
        //Map<String, Object> testMap = (Map<String, Object>) dataMap.get('p_Brukerinfojson');
        if (dataMap == null) {
            return wrapperList;
        } else {
            oebsWrapper wrapper = new oebsWrapper();
            wrapper.brukerNummer = (String) dataMap.get('brukerNummer');
            wrapper.brukerStatus = (String) dataMap.get('brukerStatus');
            wrapper.fnr = (String) dataMap.get('fnr');
            wrapper.fnrStatus = (String) dataMap.get('fnrStatus');
            wrapperList.add(wrapper);
        }
        system.debug('wrapperList: ' + wrapperList);
        return wrapperList;
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
