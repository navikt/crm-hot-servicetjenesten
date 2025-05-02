public without sharing class HOT_CallFlowController {
    private static final List<String> QUERY_FIELDS = new List<String>{ 'puzzel__SessionId__c', 'puzzel__Caller__c' };
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
        label='Get Caller and Call queue'
        description='Use the Puzzel Session ID to collect the Caller, and matches the Puzzel queue name from enquiry log to determine the caller context'
        category='Call Flow'
    )
    public static List<CallerResponse> getCallerInfo(List<String> sessionIds) {
        List<CallerResponse> results = new List<CallerResponse>();

        Boolean isFallback = getEnquiryLogObject() == null && !Test.isRunningTest();
        if (isFallback) {
            for (String sid : sessionIds) {
                results.add(new CallerResponse('', 'PERSON', 'TEST QUEUE', ''));
            }
            return results;
        }

        List<Object> logs = getEnquiryLogs(sessionIds);

        // collect all queue names for metadata lookup
        Set<String> queueNames = new Set<String>();
        for (Object record : logs) {
            Map<String, Object> recMap = (Map<String, Object>) record;
            if (recMap.containsKey('puzzel__Queue__c')) {
                queueNames.add((String) recMap.get('puzzel__Queue__c'));
            }
        }

        // load metadata
        Map<String, Puzzel_Queue_Mapping__mdt> mappings = new Map<String, Puzzel_Queue_Mapping__mdt>();
        for (Puzzel_Queue_Mapping__mdt md : getQueueMappings(queueNames)) {
            mappings.put(md.Puzzel_Queue_Name__c, md);
        }

        // build response
        for (Object record : logs) {
            Map<String, Object> recMap = (Map<String, Object>) record;
            String caller = recMap.containsKey('puzzel__Caller__c') ? (String) recMap.get('puzzel__Caller__c') : '';
            String queueName = recMap.containsKey('puzzel__Queue__c') ? (String) recMap.get('puzzel__Queue__c') : '';
            Puzzel_Queue_Mapping__mdt md = mappings.get(queueName);

            String themeGroup = (md != null) ? md.Theme_Group_Code__c : 'PERSON';
            String callerContext = (md != null) ? md.Caller_Context__c : 'TEST QUEUE';

            results.add(new CallerResponse(caller, themeGroup, callerContext, queueName));
        }

        return results;
    }

    private static List<Object> getEnquiryLogs(List<String> sessionIds) {
        fflib_QueryFactory qf = new fflib_QueryFactory(getEnquiryLogObject());
        String soql = qf.selectFields(QUERY_FIELDS)
            .setCondition('puzzel__SessionId__c IN :sessionIds')
            .toSOQL();

        if (Test.isRunningTest()) {
            return (List<Object>) JSON.deserializeUntyped(HOT_CallFlowControllerTest.MOCK_ENQUIRY_LOG);
        }
        return (List<Object>) JSON.deserializeUntyped(JSON.serialize(Database.query(soql)));
    }

    private static List<Puzzel_Queue_Mapping__mdt> getQueueMappings(Set<String> queueNames) {
        if (queueNames == null || queueNames.isEmpty()) {
            return new List<Puzzel_Queue_Mapping__mdt>();
        }
        return [
            SELECT Puzzel_Queue_Name__c, Theme_Group_Code__c, Caller_Context__c
            FROM Puzzel_Queue_Mapping__mdt
            WHERE Puzzel_Queue_Name__c IN :queueNames
        ];
    }

    public class CallerResponse {
        @InvocableVariable
        public String callerNumber;
        @InvocableVariable
        public String themeGroup;
        @InvocableVariable
        public String callerContext;
        @InvocableVariable
        public String queueName;

        public CallerResponse(String callerNumber, String themeGroup, String callerContext, String queueName) {
            this.callerNumber = callerNumber;
            this.themeGroup = themeGroup;
            this.callerContext = callerContext;
            this.queueName = queueName;
        }
    }
}
