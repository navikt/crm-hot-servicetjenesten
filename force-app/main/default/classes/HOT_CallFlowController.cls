public without sharing class HOT_CallFlowController {
    private static final List<String> QueryFields = new List<String>{ 'puzzel__SessionId__c', 'puzzel__Caller__c' };
    private static Map<String, Schema.SObjectType> globalDesc = Schema.getGlobalDescribe();

    /**
     * @description: Returns the Enquiry log SObject type if it exists
     * @author Stian Ruud Schikora | 05-28-2021
     * @return Schema.SObjectType
     **/
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

        if (getEnquiryLogObject() == null && !Test.isRunningTest()) {
            for (String puzSessionId : sessionIds) {
                respList.add(new CallerResponse('')); //Blank Phonenumber as fallback when there is no match
            }
        } else {
            List<Object> enqLogs = getEnquiryLogs(sessionIds);
            system.debug('Enquirylog test' + getEnquiryLogs(sessionIds));
            for (Object enqLog : enqLogs) {
                Map<String, Object> enqMap = (Map<String, Object>) enqLog;
                if (enqMap.containsKey('puzzel__Caller__c'))
                    //String caller = (String) enqMap.get('puzzel__Caller__c');
                    respList.add(new CallerResponse((String) enqMap.get('puzzel__Caller__c')));
            }
        }
        return respList;
    }

    /**
     * @description: Queries the enquiry logs matching the sessionId set.
     * @author Stian Ruud Schikora | 05-28-2021
     * @param sessionIds
     * @return List<SObject>
     **/
    private static List<Object> getEnquiryLogs(List<String> sessionIds) {
        fflib_QueryFactory queryFactory = new fflib_QueryFactory(getEnquiryLogObject());

        return Test.isRunningTest()
            ? (List<Object>) JSON.deserializeUntyped(HOT_CallFlowControllerTest.MOCK_ENQUIRY_LOG)
            : (List<Object>) JSON.deserializeUntyped(JSON.serialize(Database.query(queryFactory.selectFields(QueryFields).setCondition('puzzel__SessionId__c in :sessionIds').toSOQL())));
    }

    public class CallerResponse {
        @invocableVariable
        public String callerNumber;

        public CallerResponse(String callerNumber) {
            this.callerNumber = callerNumber;
        }
    }
}