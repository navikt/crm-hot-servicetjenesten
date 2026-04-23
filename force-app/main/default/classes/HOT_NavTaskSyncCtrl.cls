public without sharing class HOT_NavTaskSyncCtrl {
    @AuraEnabled
    public static void syncOpenAndAssigned() {
        try {
            User runningUser = [SELECT Id, CRM_NAV_Ident__c FROM User WHERE Id = :UserInfo.getUserId()];
            CRM_OppgaveQuery oppgQuery = new CRM_OppgaveQuery();
            oppgQuery.tilordnetRessurs = runningUser.CRM_NAV_Ident__c;
            oppgQuery.statuskategori = OppgaveStatuskategori.AAPEN;

            CRM_OppgaveSyncController.doOppgaveSync(JSON.serialize(oppgQuery));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
