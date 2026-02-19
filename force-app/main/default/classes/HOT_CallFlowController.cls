public without sharing class HOT_CallFlowController {
    private static final List<String> QueryFields = new List<String>{ 'puzzel__SessionId__c', 'puzzel__Caller__c' };
    private static Map<String, Schema.SObjectType> globalDesc = Schema.getGlobalDescribe();

    // Allows the test class to inject mock data without JSON or cross-referencing
    @TestVisible
    private static List<Map<String, Object>> mockEnquiryLogs;

    /**
     * @description: Returns the Enquiry log SObject type if it exists
     */
    private static Schema.SObjectType getEnquiryLogObject() {
        return globalDesc.containsKey('puzzel__EnquiryLog__c') ? globalDesc.get('puzzel__EnquiryLog__c') : null;
    }

    @InvocableMethod(
        label='Get Caller'
        description='Use the Puzzel Session ID to collect the Caller.'
        category='Call Flow'
    )
    public static List<CallerResponse> getCallerInfo(List<String> sessionIds) {
        List<CallerResponse> respList = new List<CallerResponse>();
        LoggerUtility logger = new LoggerUtility(CRM_ApplicationDomain.Domain.HOT, 'HOT_getCallerInfo');

        // Sjekk om objektet finnes
        if (getEnquiryLogObject() == null && !Test.isRunningTest()) {
            for (String puzSessionId : sessionIds) {
                respList.add(new CallerResponse(''));
            }
            logger.errorAndPublish('Kunne ikke finne puzzel__EnquiryLog__c record');
            return respList;
        }

        // Fetch logs as Maps instead of SObjects to avoid Schema restrictions during testing
        List<Map<String, Object>> enqLogs = getEnquiryLogs(sessionIds);

        Map<String, String> sessionToCallerMap = new Map<String, String>();
        for (Map<String, Object> log : enqLogs) {
            String sId = (String) log.get('puzzel__SessionId__c');
            String caller = (String) log.get('puzzel__Caller__c');

            if (sId != null && String.isNotBlank(caller)) {
                sessionToCallerMap.put(sId, caller);
            }
        }

        for (String sessId : sessionIds) {
            if (sessionToCallerMap.containsKey(sessId)) {
                respList.add(new CallerResponse(sessionToCallerMap.get(sessId)));
            } else {
                respList.add(new CallerResponse(''));
            }
        }

        return respList;
    }

    /**
     * @description: Queries the enquiry logs matching the sessionId set.
     * Endret returtype til List<Map<String, Object>> for å unngå type-feil og gjøre testing uavhengig av SObject.
     */
    private static List<Map<String, Object>> getEnquiryLogs(List<String> sessionIds) {
        // Return injected mock data during tests
        if (Test.isRunningTest() && mockEnquiryLogs != null) {
            return mockEnquiryLogs;
        }

        List<Map<String, Object>> results = new List<Map<String, Object>>();

        if (getEnquiryLogObject() != null) {
            fflib_QueryFactory queryFactory = new fflib_QueryFactory(getEnquiryLogObject());
            List<SObject> logs = Database.query(
                queryFactory.selectFields(QueryFields).setCondition('puzzel__SessionId__c in :sessionIds').toSOQL()
            );

            // Convert SObjects to generic maps dynamically
            for (SObject log : logs) {
                results.add(log.getPopulatedFieldsAsMap());
            }
        }

        return results;
    }

    public class CallerResponse {
        @invocableVariable
        public String callerNumber;

        public CallerResponse(String callerNumber) {
            this.callerNumber = callerNumber;
        }
    }
}
