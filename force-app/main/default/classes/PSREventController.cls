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
        return calloutResponse;
    }

    private static String puzzelCallout(String bodyJson) {
        /*** Dette er bare bygget for POC, benytt Named Credentials om dette skal taes i bruk ***/
        String token = getBearerToken();
        system.debug('Token found? ' + token);
        if (String.isBlank(token)) {
            throw new AuraHandledException('Bearer token is missing.');
        }

        Http http = new Http();
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
        system.debug('was here');
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://app.puzzel.com/id/connect/token');
        req.setMethod('POST');

        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('Accept', 'application/json');

        /*** husk å flytte hemmelig data ut av koden, bare brukt i PoC ***/
        req.setBody(
            'grant_type=client_credentials' +
            '&client_id=41155-violet-535' +
            '&client_secret=JcZfjcZrLLkjJqRgSY5fLLByzXhN0c7pdgsIrIg8' +
            '&scope=contact-centre:4115509:793327'
        );

        Http http = new Http();
        HttpResponse res = http.send(req);
        system.debug('Response: ' + res);

        if (res.getStatusCode() != 200) {
            throw new CalloutException('Failed to retrieve token: ' + res.getStatusCode() + ' — ' + res.getBody());
        }

        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        system.debug('jsonMap Bearer: ' + jsonMap);

        return (String) jsonMap.get('access_token');
    }
}
