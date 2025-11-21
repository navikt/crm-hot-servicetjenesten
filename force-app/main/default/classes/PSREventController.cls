public with sharing class PSREventController {
    /*** Midlertidig for testing, foreslår custom metadata eller lignende ***/
    private static final Map<String, RoutingInfo> GROUP_ROUTING = new Map<String, RoutingInfo>{
        //'00GKI000001fGti2AE' => new RoutingInfo('SF_Chat_Hjelpemiddelsentralen', 'q_sf_chat_hjelpemiddelsentralen'),
        '00GKI000001fGti2AE' => new RoutingInfo('SF_Chat_Hjelpemiddelsentralen', 'q_etask_chat_queue'),
        '00GXY0000099ABC2DE' => new RoutingInfo('support@example.com', 'SupportQueue')
    };

    public class RoutingInfo {
        public String toEmail;
        public String queueKey;
        public RoutingInfo(String toEmail, String queueKey) {
            this.toEmail = toEmail;
            this.queueKey = queueKey;
        }
    }

    @AuraEnabled
    public static String PSREventController(String responseJson) {
        String calloutResponse;
        if (String.isBlank(responseJson)) {
            throw new AuraHandledException('Response cannot be empty.');
        }

        Map<String, Object> incoming;
        try {
            incoming = (Map<String, Object>) JSON.deserializeUntyped(responseJson);
        } catch (Exception e) {
            throw new AuraHandledException('Invalid JSON structure: ' + e.getMessage());
        }

        // Extract the sobject payload
        Map<String, Object> data = (Map<String, Object>) incoming.get('data');
        Map<String, Object> innerData = (Map<String, Object>) data.get('sobject');

        String groupId = (String) innerData.get('GroupId');
        String idVal = (String) innerData.get('Id');
        String workItemId = (String) innerData.get('WorkItemId');
        String serviceChannelId = (String) innerData.get('ServiceChannelId');
        String uri = idVal + '#$' + workItemId + '#$' + serviceChannelId;

        /*** Hente ut mapping informasjonen - Custom metadata eller egen klasse ***/
        RoutingInfo route = GROUP_ROUTING.get(groupId);
        if (route == null) {
            throw new AuraHandledException('No routing configuration found for GroupId: ' + groupId);
        }

        Map<String, Object> eTask = new Map<String, Object>{
            'from' => 'salesforce@puzzel.com',
            'to' => 'SF_Chat_Hjelpemiddelsentralen',
            //'to' => route.toEmail,
            'subject' => 'New Chat',
            'uri' => uri,
            'queueKey' => 'q_etask_chat_queue'
            //'queueKey' => route.queueKey
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

    // -----------------------------
    // BEARER AUTHENTICATED CALLOUT
    // -----------------------------
    private static String puzzelCallout(String bodyJson) {
        /*** Dette er bare bygget for POC, benytt Named Credentials om dette skal taes i bruk ***/
        String token = getBearerToken();
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

    // -----------------------------
    // TOKEN RETRIEVAL
    // -----------------------------
    private static String getBearerToken() {
        /*** for test purpose er denne hardkodet. Bruk Named Credentials eller lignende etter POC****/
        return 'eyJhbGciOiJSUzI1NiIsImtpZCI6IjUyNzVBQzAyMDNFNDdGODJDQ0Y3RjZDODFCQ0M3MDgzIiwidHlwIjoiYXQrand0In0.eyJpc3MiOiJodHRwczovL2FwcC5wdXp6ZWwuY29tL2lkIiwibmJmIjoxNzYzNzE0NDI2LCJpYXQiOjE3NjM3MTQ0MjYsImV4cCI6MTc2MzcxNTMyNiwiYXVkIjoidXJuOnB1enplbDpjb250YWN0LWNlbnRyZSIsInNjb3BlIjpbImNvbnRhY3QtY2VudHJlIl0sImNsaWVudF9pZCI6IjQxMTU1LXZpb2xldC01MzUiLCJ1cm46cHV6emVsOmNpZCI6IjQxMTU1IiwidXJuOnB1enplbDpjbmFtZSI6Ik5BViBLb250YWt0c2VudGVyIFB1enplbCIsInVybjpwdXp6ZWw6Y2NhdCI6IkEiLCJ1cm46cHV6emVsOmNjOm1zbGlkIjoiYTZwN1UwMDAwMDAwMGlBUUFRIiwidXJuOnB1enplbDpjYzpzbGlkIjoiNDExNTUwOSIsInVybjpwdXp6ZWw6Y2M6c2xuYW1lIjoiTkFWIFJlc2VydmUgaW5zdGFucyAxIiwidXJuOnB1enplbDpjYzpzbHVpZCI6Ijc5MzMyNyIsImp0aSI6IjIyQzE0NkExNzM1RTZFNjE4RjAwRUEzNERDNTM2NkY1In0.TDYxjUmDJDPPtjfFcpYrYzUCzsRUSKnPMYCYGK1o7HZWz9gVwOOvTZOVSh07G3383XGTnUZ1pmZucZwjU-IXm98dWkHYv-hDjDO1hIJ7o3gE4t_oEnCErNOaJTrcP38zAgvwSIP3erTBhPmrO-PrG3PW_cUZ9yzoTLbJ8kJaYEYmxM-nm11be8UhuOEbdHx8IuT55w0gIP8CtLMSzN0I_b8P4h9Yr1rHhIOoWNWSOaOkse4ZCyKds6PjO8RCyYIGlwKfk2sfpmmN6qNZ_2g98gmc5ZEclsbo5BBcqMkq1d_Z5Zln_JNGHKTj4CkIAn8i7PR89ls3xsVHozIvBaIKRg';
    }
}
