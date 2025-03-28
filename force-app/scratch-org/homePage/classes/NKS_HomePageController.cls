public with sharing class NKS_HomePageController {
    @AuraEnabled(cacheable=true)
    public static List<String> getUserSkills() {
        try {
            List<String> skills = new List<String>();
            for (String skill : getUserSkills(UserInfo.getUserId())) {
                skills.add(skill.replaceAll('NKS_Skill_', ''));
            }
            return skills;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static Set<String> getUserSkills(Id userId) {
        Set<String> skills = new Set<String>();
        skills.addAll(getChatSkills(userId));
        skills.addAll(getServiceResourceSkills(userId));
        return skills;
    }

    public static Set<String> getServiceResourceSkills(Id userId) {
        Set<String> skills = new Set<String>();

        for (ServiceResourceSkill srSkill : [
            SELECT Skill.DeveloperName
            FROM ServiceResourceSkill
            WHERE ServiceResource.RelatedRecordId = :userId
        ]) {
            skills.add(srSkill.Skill.DeveloperName);
        }
        return skills;
    }

    public static Set<String> getChatSkills(Id userId) {
        Set<String> skills = new Set<String>();
        for (Group g : [
            SELECT DeveloperName
            FROM Group
            WHERE
                DeveloperName LIKE 'NKS_Skill_%'
                AND Group.Type = 'Regular'
                AND Id IN (SELECT GroupId FROM GroupMember WHERE UserOrGroupId = :userId)
        ]) {
            skills.add(g.DeveloperName);
        }
        return skills;
    }

    @AuraEnabled(cacheable=true)
    public static String getField(String type) {
        List<NKS_Announcement__c> announcement = [
            SELECT NKS_Information__c
            FROM NKS_Announcement__c
            WHERE RecordType.DeveloperName = :type AND CreatedDate = LAST_N_DAYS:15
            ORDER BY SystemModstamp DESC
            LIMIT 1
        ];
        if (announcement.isEmpty() || String.isBlank(announcement[0].NKS_Information__c)) {
            return '';
        }
        return announcement[0].NKS_Information__c.replace('<img', '<img style="max-height: 100px"');
    }

    @AuraEnabled(cacheable=true)
    public static List<RecordWrapper> getCaseList(
        String title,
        String content,
        String filter,
        String orderBy,
        String limitNumber,
        String dateField
    ) {
        String query = 'SELECT toLabel(Status), ' + title;
        if (String.isNotBlank(dateField)) {
            query += ', ' + dateField;
        }
        if (String.isNotBlank(content)) {
            query += ', ' + content;
        }
        query += ' FROM Case';

        if (String.isNotBlank(filter)) {
            query += ' WHERE ' + filter;
        }

        if (String.isNotBlank(orderBy)) {
            query += ' ORDER BY ' + orderBy;
        }

        if (String.isNotBlank(limitNumber)) {
            query += ' LIMIT ' + limitNumber;
        }

        return createWrapperRecords(Database.query(query), 'Case', title, content, dateField, false);
    }

    @AuraEnabled(cacheable=true)
    public static List<RecordWrapper> getAnnouncementList(
        String title,
        String content,
        String filter,
        String orderBy,
        String limitNumber,
        String dateField,
        Boolean showImage,
        Boolean filterBySkills,
        List<String> skills
    ) {
        String query = 'SELECT Id, NKS_News_Pin__c, NKS_News_Publish_Date__c, NKS_News_Update_Date__c, ' + title;
        if (String.isNotBlank(dateField) && dateField != 'NKS_News_Publish_Date__c') {
            query += ', ' + dateField;
        }
        if (String.isNotBlank(content)) {
            query += ', ' + content;
        }
        query += ' FROM NKS_Announcement__c';

        if (filterBySkills && skills != null && !skills.isEmpty()) {
            String skillStringAnnouncement = String.join(skills, '\',\'');
            filter +=
                (String.isBlank(filter) ? '' : ' AND ') +
                '(Skills__c = \'\' OR Skills__c INCLUDES (\'' +
                skillStringAnnouncement +
                '\'))';
        }

        if (String.isNotBlank(filter)) {
            query += ' WHERE ' + filter;
        }

        if (String.isNotBlank(orderBy)) {
            query += ' ORDER BY ' + orderBy;
        }

        if (String.isNotBlank(limitNumber)) {
            query += ' LIMIT ' + limitNumber;
        }

        return createWrapperRecords(Database.query(query), 'NKS_Announcement__c', title, content, dateField, showImage);
    }

    @AuraEnabled(cacheable=true)
    public static List<RecordWrapper> getKnowledgeList(
        String title,
        String content,
        String filter,
        String orderBy,
        String limitNumber,
        String dateField,
        Boolean showImage,
        Boolean filterBySkills,
        List<String> skills
    ) {
        String query = 'SELECT Id, ' + title;
        if (String.isNotBlank(dateField)) {
            query += ', ' + dateField;
        }
        if (String.isNotBlank(content)) {
            query += ', ' + content;
        }
        query += ' FROM Knowledge__kav';

        if (filterBySkills && skills != null && !skills.isEmpty()) {
            String skillStringKnowledge = String.join(skills, '__c,') + '__c';
            filter +=
                (String.isBlank(filter) ? '' : ' AND ') +
                'WITH DATA CATEGORY Tema__c ABOVE_OR_BELOW (' +
                skillStringKnowledge +
                ')';
        }
        if (String.isNotBlank(filter)) {
            query += ' WHERE ' + filter;
        }

        if (String.isNotBlank(orderBy)) {
            query += ' ORDER BY ' + orderBy;
        }

        if (String.isNotBlank(limitNumber)) {
            query += ' LIMIT ' + limitNumber;
        }

        return createWrapperRecords(Database.query(query), 'Knowledge__kav', title, content, dateField, showImage);
    }

    @AuraEnabled(cacheable=true)
    public static List<RecordWrapper> getList(
        String title,
        String content,
        String objectName,
        String filter,
        String orderBy,
        String limitNumber,
        String dateField
    ) {
        String query = 'SELECT Id, ' + title;
        if (String.isNotBlank(dateField)) {
            query += ', ' + dateField;
        }
        if (String.isNotBlank(content)) {
            query += ', ' + content;
        }
        query += ' FROM ' + objectName;

        if (String.isNotBlank(filter)) {
            query += ' WHERE ' + filter;
        }

        if (String.isNotBlank(orderBy)) {
            query += ' ORDER BY ' + orderBy;
        }

        if (String.isNotBlank(limitNumber)) {
            query += ' LIMIT ' + limitNumber;
        }

        return createWrapperRecords(Database.query(query), objectName, title, content, dateField, false);
    }

    public static Map<Id, String> getImageUrls(Set<Id> recordIds) {
        Map<Id, String> urlMap = new Map<Id, String>();
        for (ContentDocumentLink cdl : [
            SELECT
                Id,
                ContentDocumentId,
                ContentDocument.LatestPublishedVersionId,
                ContentDocument.ContentModifiedDate,
                ContentDocument.FileType,
                LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :recordIds
            ORDER BY ContentDocument.ContentModifiedDate DESC
        ]) {
            if (urlMap.containsKey(cdl.LinkedEntityId)) {
                continue;
            }

            String urlString =
                '/sfc/servlet.shepherd/version/renditionDownload?rendition=' +
                (cdl.ContentDocument?.FileType == 'PDF' ? 'SVGZ' : 'ORIGINAL_Png') +
                '&versionId=' +
                cdl.ContentDocument?.LatestPublishedVersionId;

            urlMap.put(cdl.LinkedEntityId, urlString);
        }
        return urlMap;
    }

    public static String getImageUrl(Id recordId) {
        return getImageUrls(new Set<Id>{ recordId }).get(recordId);
    }

    @AuraEnabled(cacheable=true)
    public static NKS_Announcement__c getCampaign() {
        List<NKS_Announcement__c> campaigns = [
            SELECT
                Id,
                Name,
                NKS_Campaign_Image_Alt__c,
                NKS_ImageURL__c,
                NKS_Campaign_From_Date__c,
                NKS_Campaign_To_Date__c
            FROM NKS_Announcement__c
            WHERE RecordType.Name = 'Campaign' AND NKS_Campaign_To_Date__c >= TODAY
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (campaigns.isEmpty() || (String.isBlank(campaigns[0].NKS_ImageURL__c))) {
            return null;
        }
        campaigns[0].NKS_ImageURL__c = getImageUrl(campaigns[0].Id);
        return campaigns[0];
    }

    @AuraEnabled(cacheable=true)
    public static NKS_Announcement__c getNews(Id recordId) {
        List<NKS_Announcement__c> news = [
            SELECT
                Id,
                Name,
                NKS_News_Author__c,
                NKS_News_Other_Authors__c,
                NKS_News_Publish_Date__c,
                NKS_News_Update_Date__c,
                LastModifiedDate,
                NKS_Information__c,
                NKS_ImageURL__c
            FROM NKS_Announcement__c
            WHERE Id = :recordId
        ];
        if (news.isEmpty()) {
            return null;
        }
        news[0].NKS_ImageURL__c = getImageUrl(news[0].Id);
        return news[0];
    }

    @AuraEnabled(cacheable=true)
    public static List<Knowledge__kav> getReadyResponses() {
        List<Knowledge__kav> readyResponses = [
            SELECT Id, Title, Ready_Response_Title__c
            FROM Knowledge__kav
            WHERE
                RecordType.DeveloperName = 'Response_Readiness'
                AND NKS_Publish_On_Home_Page__c = TRUE
                AND PublishStatus = 'Online'
            ORDER BY LastModifiedDate DESC
            LIMIT 5
        ];
        return readyResponses.isEmpty() ? null : readyResponses;
    }

    public class RecordWrapper {
        @AuraEnabled
        public String recordId;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String content;
        @AuraEnabled
        public String summary;
        @AuraEnabled
        public Datetime modifiedDate;
        @AuraEnabled
        public String imageurl;
        @AuraEnabled
        public Boolean pin;
        @AuraEnabled
        public Datetime publishDate;
        @AuraEnabled
        public Datetime lastUpdatedDate;
        @AuraEnabled
        public String status;
    }

    private static List<RecordWrapper> createWrapperRecords(
        List<sObject> listOfWrapperRecords,
        String objectName,
        String title,
        String content,
        String dateField,
        Boolean showImage
    ) {
        List<RecordWrapper> records = new List<RecordWrapper>();
        Map<Id, String> urlMap = new Map<Id, String>();

        if (listOfWrapperRecords.isEmpty()) {
            return records;
        }

        if (showImage) {
            Set<Id> recordIds = new Set<Id>();
            for (sObject wrapperRecord : listOfWrapperRecords) {
                recordIds.add(wrapperRecord.Id);
            }
            urlMap = getImageUrls(recordIds);
        }

        for (sObject wrapperRecord : listOfWrapperRecords) {
            RecordWrapper record = new RecordWrapper();
            record.recordId = wrapperRecord.Id;
            record.name = String.valueOf(wrapperRecord.get(title));
            record.modifiedDate = Datetime.valueOf(wrapperRecord.get(dateField));

            if (showImage) {
                record.imageurl = urlMap.get(wrapperRecord.Id);
            }

            if (String.isNotBlank(content) && String.isNotBlank((String) wrapperRecord.get(content))) {
                record.content = String.valueOf(wrapperRecord.get(content)).replaceAll('\\<.*?\\>', '');
                record.summary = (record.content.length() > 600) ? record.content.mid(0, 600) + '...' : record.content;
            }

            if (objectName == 'NKS_Announcement__c') {
                record.pin = Boolean.valueOf(wrapperRecord.get('NKS_News_Pin__c'));
                record.publishDate = Datetime.valueOf(wrapperRecord.get('NKS_News_Publish_Date__c'));
                record.lastUpdatedDate = Datetime.valueOf(wrapperRecord.get('NKS_News_Update_Date__c'));
            }
            record.status = objectName == 'Case' ? record.status : '';
            records.add(record);
        }
        return records;
    }

    @invocableMethod(label='Remove HTML Tags')
    public static List<String> removeHtmlTags(List<String> richTextList) {
        String richText = richTextList[0];
        List<String> plainTextList = new List<String>();
        richText = richText.stripHtmlTags();
        plainTextList.add(richText);
        return plainTextList;
    }

    /*
        Used with nksDefaultUserApplication to track users switching default apps
    */
    @AuraEnabled
    public static String getUsersCurrentApp() {
        try {
            UserAppInfo userAppInfo = [
                SELECT AppDefinitionId
                FROM UserAppInfo
                WHERE UserId = :UserInfo.getUserId()
                LIMIT 1
            ];
            AppDefinition appDefinition = [
                SELECT DeveloperName
                FROM AppDefinition
                WHERE DurableId = :userAppInfo.AppDefinitionId
                LIMIT 1
            ];
            return appDefinition.DeveloperName;
        } catch (Exception e) {
            System.debug(e.getMessage());
            return null;
        }
    }

    // When navigating with NavigationMixin, the user's current app does not update unless manually updated
    @AuraEnabled
    public static void updateUsersCurrentApp(String appTarget) {
        try {
            UserAppInfo userAppInfo = [
                SELECT AppDefinitionId
                FROM UserAppInfo
                WHERE UserId = :UserInfo.getUserId()
                LIMIT 1
            ];
            AppDefinition appDefinition = [
                SELECT DurableId
                FROM AppDefinition
                WHERE DeveloperName = :appTarget
                LIMIT 1
            ];
            userAppInfo.AppDefinitionId = appDefinition.DurableId;
            update userAppInfo;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static NKS_Announcement__c getNksStatus(String title) {
        try {
            NKS_Announcement__c status = [
                SELECT Id, Name, NKS_Information__c
                FROM NKS_Announcement__c
                WHERE Name = :title AND RecordType.DeveloperName = 'NKS_Status'
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            return status;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving NKS status: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateNksStatus(Map<String, String> fields) {
        if (fields == null || !fields.containsKey('Id')) {
            throw new AuraHandledException('Record ID is required');
        }

        NKS_Announcement__c status = new NKS_Announcement__c(Id = fields.get('Id'));

        if (fields.containsKey('NKS_Information__c')) {
            status.NKS_Information__c = fields.get('NKS_Information__c');
        }

        try {
            Database.SaveResult result = Database.update(status, false);

            if (result.isSuccess()) {
                NKS_Home_Page_Event__e event = new NKS_Home_Page_Event__e(RecordId__c = status.Id);
                EventBus.publish(event);
            } else {
                throw new AuraHandledException('Failed to update the NKS status.');
            }
        } catch (DmlException e) {
            throw new AuraHandledException('Update failed: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<NKS_Announcement__c> getNksCurrents() {
        List<NKS_Announcement__c> currents = [
            SELECT Id, Name, NKS_Link_URL__c
            FROM NKS_Announcement__c
            WHERE RecordType.DeveloperName = 'NKS_Current'
            ORDER BY LastModifiedDate DESC
            LIMIT 5
        ];
        return currents.isEmpty() ? null : currents;
    }

    @AuraEnabled
    public static void createNksCurrent(String title, String URL) {
        try {
            RecordType rt = [
                SELECT Id
                FROM RecordType
                WHERE SObjectType = 'NKS_Announcement__c' AND DeveloperName = 'NKS_Current'
                LIMIT 1
            ];

            NKS_Announcement__c current = new NKS_Announcement__c(
                Name = title,
                NKS_Link_URL__c = URL,
                RecordTypeId = rt.Id
            );

            Database.SaveResult sr = Database.insert(current, false);
            if (!sr.isSuccess()) {
                throw new AuraHandledException('Failed to create NKS current record.');
            }
        } catch (DmlException e) {
            throw new AuraHandledException('Creation failed: ' + e.getMessage());
        }
    }
}
