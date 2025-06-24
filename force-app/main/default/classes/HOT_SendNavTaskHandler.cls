public with sharing class HOT_SendNavTaskHandler {
    @AuraEnabled
    public static Boolean invokeSendNavTaskFlow(NavTask__c navTask) {
        Boolean res = false;
        try {
            Map<String, Object> flowInputs = new Map<String, Object>{
                'NAV_Task' => navTask,
                'Created_By_Unit_Number' => getCurrentUserDepartment()
            };

            Flow.Interview flowInv = Flow.Interview.createInterview('CRM_Send_NAV_Task_Auto', flowInputs);
            flowInv.start();

            res = (Boolean) flowInv.getVariableValue('SUCCESSFUL_POST');
        } catch (Exception e) {
            System.debug('Error in invokeSendNavTaskFlow: ' + e.getMessage());
            throw new AuraHandledException('An error occurred while processing the NAV task.');
        }
        return res;
    }

    @AuraEnabled(cacheable=true)
    public static String getCurrentUserDepartment() {
        Id currentUserId = UserInfo.getUserId();
        return [SELECT Department FROM User WHERE Id = :currentUserId LIMIT 1]?.Department;
    }

    @AuraEnabled
    public static String getProcessingId(Id recordId) {
        return [SELECT NKS_Henvendelse_BehandlingsId__c FROM Case WHERE Id = :recordId LIMIT 1]
        ?.NKS_Henvendelse_BehandlingsId__c;
    }

    @AuraEnabled
    public static NavUnit__c getNavUnitInfo(Id navUnitId) {
        try {
            return [SELECT Name, INT_UnitNumber__c FROM NavUnit__c WHERE Id = :navUnitId LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving NavUnit information: ' + e.getMessage());
        }
    }
}
