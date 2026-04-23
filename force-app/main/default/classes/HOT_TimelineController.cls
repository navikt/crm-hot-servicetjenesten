public with sharing class HOT_TimelineController {
    @AuraEnabled(cacheable=true)
    public static List<TimelineGroup> getRecords(String recordId, Integer recordLimit) {
        if (String.isBlank(recordId)) {
            return new List<TimelineGroup>();
        }

        List<TimelineRecord> records = new List<TimelineRecord>();
        Integer effectiveLimit = recordLimit != null && recordLimit > 0 ? recordLimit : 50;

        String threadQuery =
            'SELECT Id, Name, CreatedDate, CRM_Latest_Message_Datetime__c, CRM_Thread_Type__c, ' +
            'CRM_Conversation_Summary__c, HOT_Timeline_Icon__c, HOT_Timeline_Name__c, CRM_Theme_Group_Name__c ' +
            'FROM Thread__c ' +
            'WHERE CRM_Account__c = :recordId ' +
            'ORDER BY CRM_Latest_Message_Datetime__c DESC NULLS LAST ' +
            'LIMIT :effectiveLimit';

        for (SObject obj : Database.query(threadQuery)) {
            records.add(new ThreadTimelineRecord(obj));
        }

        String noteQuery =
            'SELECT Id, Name, CreatedDate, CRM_Date_Time_Registered__c, CRM_Conversation_Note__c, CRM_Created_By_Ident__c, HOT_Timeline_Name__c, CRM_Journal_Status_Formula_Icons__c, CRM_Theme_Group_Name__c ' +
            'FROM Conversation_Note__c ' +
            'WHERE CRM_Account__c = :recordId ' +
            'ORDER BY CRM_Date_Time_Registered__c DESC NULLS LAST ' +
            'LIMIT :effectiveLimit';

        for (SObject obj : Database.query(noteQuery)) {
            records.add(new ConvNoteTimelineRecord(obj));
        }

        if (Schema.getGlobalDescribe().containsKey('NKS_Call_Log__c')) {
            String callLogQuery =
                'SELECT Id, Name, CreatedDate, NKS_Call_Time__c, NKS_Timeline_Name__c, NKS_Advisor_Ident__c, NKS_Timeline_Phone__c ' +
                'FROM NKS_Call_Log__c ' +
                'WHERE NKS_Account__c = :recordId ' +
                'ORDER BY NKS_Call_Time__c DESC NULLS LAST ' +
                'LIMIT :effectiveLimit';

            for (SObject obj : Database.query(callLogQuery)) {
                records.add(new CallLogTimelineRecord(obj));
            }
        }

        records.sort();

        Integer threadCount = 0;
        Integer noteCount = 0;
        Integer callLogCount = 0;
        Datetime threadOldest = null;
        Datetime noteOldest = null;
        Datetime callLogOldest = null;

        for (TimelineRecord rec : records) {
            if (rec.sObjectType == 'Thread__c') {
                threadCount++;
                if (threadOldest == null || rec.dateValue < threadOldest) {
                    threadOldest = rec.dateValue;
                }
            } else if (rec.sObjectType == 'Conversation_Note__c') {
                noteCount++;
                if (noteOldest == null || rec.dateValue < noteOldest) {
                    noteOldest = rec.dateValue;
                }
            } else if (rec.sObjectType == 'NKS_Call_Log__c') {
                callLogCount++;
                if (callLogOldest == null || rec.dateValue < callLogOldest) {
                    callLogOldest = rec.dateValue;
                }
            }
        }

        Datetime cutoffDate = null;
        List<Integer> counts = new List<Integer>{ threadCount, noteCount, callLogCount };
        List<Datetime> oldestDates = new List<Datetime>{ threadOldest, noteOldest, callLogOldest };
        for (Integer i = 0; i < counts.size(); i++) {
            if (counts[i] == effectiveLimit && oldestDates[i] != null) {
                if (cutoffDate == null || oldestDates[i] > cutoffDate) {
                    cutoffDate = oldestDates[i];
                }
            }
        }

        if (cutoffDate != null) {
            List<TimelineRecord> withinWindow = new List<TimelineRecord>();
            for (TimelineRecord rec : records) {
                if (rec.dateValue >= cutoffDate) {
                    withinWindow.add(rec);
                }
            }
            records = withinWindow;
        }

        return groupRecordsByMonth(records);
    }

    private static final Map<Integer, String> NORWEGIAN_MONTHS = new Map<Integer, String>{
        1 => 'Januar',
        2 => 'Februar',
        3 => 'Mars',
        4 => 'April',
        5 => 'Mai',
        6 => 'Juni',
        7 => 'Juli',
        8 => 'August',
        9 => 'September',
        10 => 'Oktober',
        11 => 'November',
        12 => 'Desember'
    };

    private static List<TimelineGroup> groupRecordsByMonth(List<TimelineRecord> records) {
        Map<String, List<TimelineRecord>> groupMap = new Map<String, List<TimelineRecord>>();

        for (TimelineRecord rec : records) {
            Integer month = rec.dateValue.month();
            Integer year = rec.dateValue.year();
            String monthKey = NORWEGIAN_MONTHS.get(month) + ' ' + year;

            if (!groupMap.containsKey(monthKey)) {
                groupMap.put(monthKey, new List<TimelineRecord>());
            }
            groupMap.get(monthKey).add(rec);
        }

        List<TimelineGroup> groups = new List<TimelineGroup>();
        for (String monthKey : groupMap.keySet()) {
            List<TimelineRecord> monthRecords = groupMap.get(monthKey);

            List<TimelineModel> wrappedModels = new List<TimelineModel>();
            for (TimelineRecord rec : monthRecords) {
                if (rec.headers != null && !rec.headers.isEmpty()) {
                    rec.headers[rec.headers.size() - 1].isLast = true;
                }
                wrappedModels.add(new TimelineModel(rec));
            }

            TimelineGroup timelineGroup = new TimelineGroup();
            timelineGroup.id = monthKey;
            timelineGroup.name = monthKey;
            timelineGroup.models = wrappedModels;
            timelineGroup.size = wrappedModels.size();
            groups.add(timelineGroup);
        }

        groups.sort();
        return groups;
    }

    public class TimelineGroup implements Comparable {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public List<TimelineModel> models;
        @AuraEnabled
        public Integer size;

        public TimelineGroup() {
            this.models = new List<TimelineModel>();
            this.size = 0;
        }

        public Integer compareTo(Object other) {
            TimelineGroup otherGroup = (TimelineGroup) other;
            if (models == null || models.isEmpty() || otherGroup.models == null || otherGroup.models.isEmpty()) {
                return 0;
            }
            Datetime thisDate = models[0].record.dateValueDb;
            Datetime otherDate = otherGroup.models[0].record.dateValueDb;
            return thisDate > otherDate ? -1 : (thisDate < otherDate ? 1 : 0);
        }
    }

    public class TimelineModel {
        @AuraEnabled
        public RecordData record;
        @AuraEnabled
        public Theme theme;
        @AuraEnabled
        public FilterData filter;

        public TimelineModel(TimelineRecord rec) {
            this.record = new RecordData(rec);
            this.theme = new Theme(rec.icon, rec.color);
            this.filter = new FilterData(rec.sObjectType, rec.themeGroupName);
        }
    }

    public class RecordData {
        @AuraEnabled
        public Id recordId;
        @AuraEnabled
        public Datetime dateValueDb;
        @AuraEnabled
        public String sObjectKind;
        @AuraEnabled
        public String subtitleOverride;
        @AuraEnabled
        public String customComponent;
        @AuraEnabled
        public Integer clampLines;
        @AuraEnabled
        public Boolean isDate;
        @AuraEnabled
        public List<Header> headers;
        @AuraEnabled
        public String slickBackgroundColor;
        @AuraEnabled
        public String slickIconColor;

        public RecordData(TimelineRecord rec) {
            this.recordId = rec.recordId;
            this.dateValueDb = rec.dateValue;
            this.sObjectKind = rec.sObjectType;
            this.subtitleOverride = rec.subtitleOverride;
            this.customComponent = rec.customComponent;
            this.clampLines = rec.clampLines;
            this.isDate = false;
            this.headers = rec.headers;
            this.slickBackgroundColor = rec.slickBackgroundColor;
            this.slickIconColor = rec.slickIconColor;
        }
    }

    public class Theme {
        @AuraEnabled
        public String icon;
        @AuraEnabled
        public String sldsTimelineItemColor;

        public Theme(String icon, String color) {
            this.icon = icon;
            this.sldsTimelineItemColor = color;
        }
    }

    public class FilterData {
        @AuraEnabled
        public String picklistValue1;
        @AuraEnabled
        public String picklistValue2;
        @AuraEnabled
        public String checkBoxValue;
        @AuraEnabled
        public Boolean shown;

        public FilterData(String sObjectType, String themeGroupName) {
            if (sObjectType == 'Thread__c' || sObjectType == 'Conversation_Note__c') {
                this.picklistValue1 = themeGroupName;
            }
            this.shown = (sObjectType == 'NKS_Call_Log__c');
        }
    }

    private class ThreadTimelineRecord extends TimelineRecord {
        public ThreadTimelineRecord(SObject obj) {
            super();
            this.recordId = obj.Id;
            this.sObjectType = 'Thread__c';
            this.sObjectLabel = 'Thread';
            Datetime latestMessageDate = (Datetime) obj.get('CRM_Latest_Message_Datetime__c');
            Datetime effectiveDate = latestMessageDate != null ? latestMessageDate : (Datetime) obj.get('CreatedDate');
            this.headers.add(new Header((String) obj.get('HOT_Timeline_Name__c'), true));
            this.headers.add(new Header(effectiveDate, false));
            this.dateValue = effectiveDate;
            String iconValue = (String) obj.get('HOT_Timeline_Icon__c');
            this.icon = String.isNotBlank(iconValue) ? iconValue : 'standard:messaging_user';
            this.color = '7D7D7D';
            this.subtitleOverride = (String) obj.get('CRM_Conversation_Summary__c');
            this.customComponent = 'ThreadExpandedTimeline';
            this.clampLines = 2;
            this.themeGroupName = (String) obj.get('CRM_Theme_Group_Name__c');
        }
    }

    private class ConvNoteTimelineRecord extends TimelineRecord {
        public ConvNoteTimelineRecord(SObject obj) {
            super();
            this.recordId = obj.Id;
            this.sObjectType = 'Conversation_Note__c';
            this.sObjectLabel = 'Conversation Note';
            Datetime registeredDate = (Datetime) obj.get('CRM_Date_Time_Registered__c');
            Datetime effectiveDate = registeredDate != null ? registeredDate : (Datetime) obj.get('CreatedDate');
            this.headers.add(new Header((String) obj.get('HOT_Timeline_Name__c'), true));
            this.headers.add(new Header(effectiveDate, false));
            this.headers.add(new Header((String) obj.get('CRM_Journal_Status_Formula_Icons__c'), true));
            this.dateValue = effectiveDate;
            this.icon = 'standard:voice_call';
            this.color = '7D7D7D';
            this.subtitleOverride = (String) obj.get('CRM_Conversation_Note__c');
            this.customComponent = 'ConvNoteExpandedTimeline';
            this.clampLines = 1;
            this.themeGroupName = (String) obj.get('CRM_Theme_Group_Name__c');
        }
    }

    private class CallLogTimelineRecord extends TimelineRecord {
        public CallLogTimelineRecord(SObject obj) {
            super();
            this.recordId = obj.Id;
            this.sObjectType = 'NKS_Call_Log__c';
            this.sObjectLabel = 'Call Log';
            Datetime callTime = (Datetime) obj.get('NKS_Call_Time__c');
            Datetime effectiveDate = callTime != null ? callTime : (Datetime) obj.get('CreatedDate');
            this.headers.add(new Header((String) obj.get('NKS_Timeline_Name__c'), true));
            this.headers.add(new Header(effectiveDate, false));
            String advisorIdent = (String) obj.get('NKS_Advisor_Ident__c');
            if (String.isNotBlank(advisorIdent)) {
                this.headers.add(new Header(advisorIdent, true));
            }
            this.headers.add(new Header((String) obj.get('NKS_Timeline_Phone__c'), true));
            this.dateValue = effectiveDate;
            this.icon = 'standard:voice_call';
            this.color = '7D7D7D';
            this.customComponent = null;
            this.clampLines = 0;
            this.slickBackgroundColor = 'EFEFEF';
            this.slickIconColor = 'e3e3e3';
        }
    }

    public virtual class TimelineRecord implements Comparable {
        @AuraEnabled
        public Id recordId;
        @AuraEnabled
        public Datetime dateValue;
        @AuraEnabled
        public String sObjectType;
        @AuraEnabled
        public String sObjectLabel;
        @AuraEnabled
        public String icon;
        @AuraEnabled
        public String color;
        @AuraEnabled
        public String subtitleOverride;
        @AuraEnabled
        public String customComponent;
        @AuraEnabled
        public Integer clampLines;
        @AuraEnabled
        public List<Header> headers;
        @AuraEnabled
        public String slickBackgroundColor;
        @AuraEnabled
        public String slickIconColor;
        @AuraEnabled
        public String themeGroupName;

        public TimelineRecord() {
            this.headers = new List<Header>();
        }

        public Integer compareTo(Object other) {
            TimelineRecord otherRec = (TimelineRecord) other;
            if (dateValue == otherRec.dateValue) {
                return 0;
            }
            return dateValue > otherRec.dateValue ? -1 : 1;
        }
    }

    public class Header {
        @AuraEnabled
        public Object header;
        @AuraEnabled
        public Boolean isString;
        @AuraEnabled
        public Boolean isDatetime;
        @AuraEnabled
        public Boolean isDate;
        @AuraEnabled
        public Boolean isLast;

        public Header(Object headerValue, Boolean isStringType) {
            this.header = headerValue;
            this.isString = isStringType;
            this.isDatetime = !isStringType && headerValue instanceof Datetime;
            this.isDate = false;
            this.isLast = false;
        }
    }
}
