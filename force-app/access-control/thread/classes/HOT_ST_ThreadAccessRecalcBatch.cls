public with sharing class HOT_ST_ThreadAccessRecalcBatch implements Database.Batchable<sObject> {
    private final static String QUERY =
        'SELECT Id, CRM_Account__c, CRM_Henvendelse_BehandlingsId__c, CRM_Office_Restriction__c, ' +
        'STO_Category__c, ' +
        'CRM_Theme_Code__c, ' +
        'CRM_Thread_Type__c, ' +
        'CRM_Theme_Group_Name__c ' +
        'FROM Thread__c ' +
        'WHERE CRM_Account__c != null AND (STO_Category__c IN :categories OR CRM_Theme_Group_Name__c IN :themeGroups) AND  CRM_Thread_Type__c IN :threadTypes';
    @TestVisible
    private final static List<String> DEFAULT_THREAD_TYPES = new List<String>{ 'STO', 'BTO', 'STB', 'CHAT' };
    @TestVisible
    private final static List<String> DEFAULT_CATEGORIES = new List<String>{ 'Hjelpemidler' };
    @TestVisible
    private final static List<String> DEFAULT_THEME_GROUPS = new List<String>{ 'Hjelpemidler' };
    private List<String> customThreadTypes;
    private List<String> customCategories;
    private List<String> customThemeGroups;

    public HOT_ST_ThreadAccessRecalcBatch() {
    }
    public HOT_ST_ThreadAccessRecalcBatch setCustomThreadTypes(List<String> customThreadTypes) {
        this.customThreadTypes = customThreadTypes;
        return this;
    }
    public HOT_ST_ThreadAccessRecalcBatch setCustomCategories(List<String> customCategories) {
        this.customCategories = customCategories;
        return this;
    }
    public HOT_ST_ThreadAccessRecalcBatch setCustomThemeGroups(List<String> customThemeGroups) {
        this.customThemeGroups = customThemeGroups;
        return this;
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocatorWithBinds(QUERY, getBindings(), AccessLevel.SYSTEM_MODE);
    }
    public void execute(Database.BatchableContext bc, List<Thread__c> scope) {
        new HOT_ST_ThreadAccessHandler().grantAccessToNewThreads(scope);
    }
    public void finish(Database.BatchableContext bc) {
    }
    @TestVisible
    private Map<String, Object> getBindings() {
        if (this.customThreadTypes == null) {
            this.customThreadTypes = DEFAULT_THREAD_TYPES;
        }
        if (this.customCategories == null) {
            this.customCategories = DEFAULT_CATEGORIES;
        }
        if (this.customThemeGroups == null) {
            this.customThemeGroups = DEFAULT_THEME_GROUPS;
        }
        return new Map<String, Object>{
            'categories' => this.customCategories,
            'themeGroups' => this.customThemeGroups,
            'threadTypes' => this.customThreadTypes
        };
    }
}
