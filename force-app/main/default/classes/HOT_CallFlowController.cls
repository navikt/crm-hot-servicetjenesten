public without sharing class HOT_CallFlowController {
    private static final List<String> QueryFields = new List<String>{ 'puzzel__SessionId__c', 'puzzel__Caller__c' };
    private static Map<String, Schema.SObjectType> globalDesc = Schema.getGlobalDescribe();

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

        List<SObject> enqLogs = getEnquiryLogs(sessionIds);

        Map<String, String> sessionToCallerMap = new Map<String, String>();
        for (SObject log : enqLogs) {
            String sId = (String) log.get('puzzel__SessionId__c');
            String caller = (String) log.get('puzzel__Caller__c');
            
            if (sId != null) {
                if (String.isNotBlank(caller)) {
                     sessionToCallerMap.put(sId, caller);
                }
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
     * Endret returtype til List<SObject> for å unngå type-feil
     */
    private static List<SObject> getEnquiryLogs(List<String> sessionIds) {
        // Hvis test, returner mock direkte som SObjects (krever at mock-stringen er gyldig JSON for objektet)
        if (Test.isRunningTest() && HOT_CallFlowControllerTest.MOCK_ENQUIRY_LOG != null) {
            return (List<SObject>) JSON.deserialize(HOT_CallFlowControllerTest.MOCK_ENQUIRY_LOG, List<SObject>.class);
        }

        fflib_QueryFactory queryFactory = new fflib_QueryFactory(getEnquiryLogObject());

        return Database.query(
            queryFactory.selectFields(QueryFields).setCondition('puzzel__SessionId__c in :sessionIds').toSOQL()
        );
    }

    public class CallerResponse {
        @invocableVariable
        public String callerNumber;

        public CallerResponse(String callerNumber) {
            this.callerNumber = callerNumber;
        }
    }
}
