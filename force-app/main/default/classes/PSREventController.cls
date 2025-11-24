public with sharing class PSREventController {
    @AuraEnabled
    public static String PSREventController(String responseJson) {
        String calloutResponse;
        final string sender = 'salesforce@puzzel.com';
        final string subject = 'New Chat';
        if (String.isBlank(responseJson)) {
            throw new AuraHandledException('Response cannot be empty.');
        }

        Map<String, Object> incoming;
        try {
            incoming = (Map<String, Object>) JSON.deserializeUntyped(responseJson);
        } catch (Exception e) {
            throw new AuraHandledException('Invalid JSON structure: ' + e.getMessage());
        }

        Map<String, Object> data = (Map<String, Object>) incoming.get('data');
        Map<String, Object> innerData = (Map<String, Object>) data.get('sobject');

        String groupId = (String) innerData.get('GroupId');
        String idVal = (String) innerData.get('Id');
        String workItemId = (String) innerData.get('WorkItemId');
        String serviceChannelId = (String) innerData.get('ServiceChannelId');
        String uri = idVal + '#$' + workItemId + '#$' + serviceChannelId;

        /*** Hente ut mapping informasjonen med kø navn fra Puzzel ***/
        Puzzel_Chat_Mapping__mdt queueMap = [
            SELECT Puzzel_chat_Name__c, Puzzel_Queue_Api__c
            FROM Puzzel_Chat_Mapping__mdt
            WHERE Salesforce_GroupId__c = :groupId
            LIMIT 1
        ];
        String to = queueMap.Puzzel_chat_Name__c;
        String queueKey = queueMap.Puzzel_Queue_Api__c;

        Map<String, Object> eTask = new Map<String, Object>{
            'from' => sender,
            'to' => to,
            'subject' => subject,
            'uri' => uri,
            'queueKey' => queueKey
        };

        Map<String, Object> finalBody = new Map<String, Object>{ 'eTask' => eTask };
        system.debug('Outgoing: ' + finalBody);
        try {
            calloutResponse = puzzelCallout(JSON.serialize(finalBody));
        } catch (Exception ex) {
            throw new AuraHandledException('Callout failed: ' + ex.getMessage());
        }
        /*** Return er bare brukt for debugging purpose. Om dette skal aktiveres bør klassen gjøres ***/
        return calloutResponse;
    }

    private static String puzzelCallout(String bodyJson) {
        Http http = new Http();
        /*** Hent bearer token (forbedres til å ikke hente ny pr gang?) ***/
        String token = getBearerToken();
        if (String.isBlank(token)) {
            throw new AuraHandledException('Bearer token is missing.');
        }

        /*** Bygg opp request for eTask og ta imot responsen ***/
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.puzzel.com/ContactCentre5/4115509/etasks');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setBody(bodyJson);

        HttpResponse res = http.send(req);

        return res.getBody();
    }

    private static String getBearerToken() {
        Http http = new Http();
        /*** Hent opp client id og secret fra custom setting ***/
        Puzzel_Auth_Config__c cfg = Puzzel_Auth_Config__c.getOrgDefaults();
        String clientId = cfg.client_id__c;
        String clientSecret = cfg.client_secret__c;

        /*** Bygg opp request for å generere token ***/
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://app.puzzel.com/id/connect/token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('Accept', 'application/json');
        req.setBody(
            'grant_type=client_credentials' +
                '&client_id=' +
                EncodingUtil.urlEncode(clientId, 'UTF-8') +
                '&client_secret=' +
                EncodingUtil.urlEncode(clientSecret, 'UTF-8')
        );

        /*** Send request og håndter response ved å lagre bearer token ***/
        HttpResponse res = http.send(req);
        if (res.getStatusCode() != 200) {
            throw new CalloutException('Failed to retrieve token: ' + res.getStatusCode() + ' — ' + res.getBody());
        }
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        return (String) jsonMap.get('access_token');
    }
}
