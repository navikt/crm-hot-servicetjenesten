public without sharing class HOT_GetStoUtilityController {
    private final static Integer MAX_ATTEMPTS = 5;
    public class TooManyAttemptsException extends Exception {
    }
    public class NoCasesFoundException extends Exception {
    }

    private static final List<String> confidentialitySkills = new List<String>{
        'Fortrolig_addresse',
        'Skjermede_personer'
    };
    private static final List<String> originSkills = new List<String>{'STO' };

    // Since Omni channel skills are org based, we want to only include skills that are used in STO
    public static final List<String> allRelevantSkills {
        get {
            Schema.DescribeFieldResult fieldResult = Case.STO_Category__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            List<String> retList = new List<String>();
            for (Schema.PicklistEntry pl : ple) {
                    retList.add(pl.getLabel());
            }
            retList.addAll(confidentialitySkills);
            retList.addAll((originSkills));
            return retList;
        }
    }

    private static Id filteredSkillId;

    private static GroupedSkills allUserSkills = new GroupedSkills();

    @AuraEnabled
    public static List<Record> getStoWithSkill(Id skillId) {
        filteredSkillId = skillId;
        return getSto();
    }

    @AuraEnabled
    public static List<Record> getSto() {
        List<Record> records = new List<Record>();
        if (hasInProgress())
            throw new AuraHandledException('hasInProgress');

        Record newStoRecord = new Record();
        newStoRecord.recordId = getNewSTO();
        newStoRecord.status = 'In Progress';
        records.add(newStoRecord);
        Set<Id> relatedStoIds = new Set<Id>();
        try {
            relatedStoIds.addAll(getRelatedSTO(newStoRecord.recordId));
        } catch (Exception e) {
            // exception on finding related stos
        }
        for (Id relatedStoId : relatedStoIds) {
            Record relatedStoRecord = new Record();
            relatedStoRecord.recordId = relatedStoId;
            relatedStoRecord.status = 'Reserved';
            records.add(relatedStoRecord);
        }
        return records;
    }

    @AuraEnabled
    public static Id getNewSTO() {
        try {
            Integer attempt = 0;
            Id userId = UserInfo.getUserId();
            allUserSkills = getServiceResourceSkillIds();

            do {
                Id nextCaseId = getNextSTOCase();
                if (takeOwnership(nextCaseId, userId)) {
                    return nextCaseId;
                }
                attempt += 1;
            } while (attempt < MAX_ATTEMPTS);
            throw new TooManyAttemptsException('Max Attempt Count Exceeded: ' + MAX_ATTEMPTS);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static Boolean takeOwnership(Id caseId, Id userId) {
        try {
            Case c = [SELECT Id, OwnerId, Owner.Type, Status FROM Case WHERE Id = :caseId LIMIT 1 FOR UPDATE];
            if (c.Owner.Type != 'Queue') {
                return false;
            }
            c.OwnerId = userId;
            c.Status = 'In progress';
            update c;
        } catch (Exception e) {
            return false;
        }
        return true;
    }

    @AuraEnabled
    public static List<Id> getRelatedSTO(Id caseId) {
        List<Id> relatedCaseIds = new List<Id>();
        try {
            Map<String, Object> flowParams = new Map<String, Object>();
            flowParams.put('CaseId', caseId);
            if (Test.isRunningTest()) {
                allUserSkills.userOriginMap.put('001xa000003DIlo', 'STO');
            }
            flowParams.put('UserOriginSkills', allUserSkills.userOriginMap.values());

            Flow.Interview.STO_Case_Set_Owner setOwnerFlow = new Flow.Interview.STO_Case_Set_Owner(flowParams);
            setOwnerFlow.start();
            List<Case> relatedCases = (List<Case>) setOwnerFlow.getVariableValue('ReturnVar');
            if (relatedCases == null)
                return relatedCaseIds;
            for (Case c : relatedCases) {
                relatedCaseIds.add(c.Id);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return relatedCaseIds;
    }

    @AuraEnabled
    public static List<Record> getList(String limitNumber) {
        List<Record> records = new List<Record>();
        List<Case> listtoreturn = [
            SELECT LastModifiedDate, CreatedDate, toLabel(Status), STO_Category__c, CaseNumber
            FROM Case
            WHERE
                Status IN ('New', 'In progress', 'Reserved')
                AND RecordType.DeveloperName = 'STO_Case'
                AND OwnerId = :UserInfo.getUserID()
            ORDER BY CreatedDate DESC
            LIMIT :Integer.valueOf(limitNumber)
        ];
        records = createRecords(listtoreturn);
        return records;
    }

    private static Boolean hasInProgress() {
        List<Case> casesInProgress = [
            SELECT Id
            FROM Case
            WHERE
                Status IN ('New', 'In progress')
                AND RecordType.DeveloperName = 'STO_Case'
                AND OwnerId = :UserInfo.getUserID()
            LIMIT 1
        ];
        return casesInProgress.size() > 0 ? true : false;
    }

    public class Record {
        @AuraEnabled
        public String recordId;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public Datetime modifiedDate;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String casenumber;
    }

    private static List<Record> createRecords(List<Case> listofrecords) {
        List<Record> records = new List<Record>();
        for (Case r : listofrecords) {
            Record record = new Record();
            record.recordId = r.Id;
            record.name = r.STO_Category__c;
            record.modifiedDate = Datetime.valueOf(r.CreatedDate);
            record.status = r.Status;
            record.casenumber = r.CaseNumber;
            records.add(record);
        }
        return records;
    }

    @AuraEnabled(cacheable=true)
    public static GroupedSkills getServiceResourceSkillIds() {
        Id userId = UserInfo.getUserId();
        GroupedSkills retSkills = new GroupedSkills();

        for (ServiceResourceSkill srs : [
            SELECT SkillId,  Skill.DeveloperName, Skill.MasterLabel
            FROM ServiceResourceSkill
            WHERE
                ServiceResource.RelatedRecordId = :userId
                AND Skill.DeveloperName IN :allRelevantSkills
                AND EffectiveStartDate <= TODAY
                AND (EffectiveEndDate >= TODAY
                OR EffectiveEndDate = NULL)
                AND ServiceResource.IsActive = TRUE
        ]) {
            //Separating domain skills and person access skills
            if (confidentialitySkills.contains(srs.Skill.DeveloperName)) {
                retSkills.userConfidentialMap.put(srs.SkillId, srs.Skill.DeveloperName);
            } else if (originSkills.contains(srs.Skill.DeveloperName)) {
                retSkills.userOriginMap.put(srs.SkillId, srs.Skill.DeveloperName);
            } else {
                if (filteredSkillId == null || filteredSkillId == srs.SkillId) {
                    retSkills.skillMap.put(srs.SkillId, srs.Skill.MasterLabel);
                }
            }
        }
        return retSkills;
    }

    private static Id getNextSTOCase() {
        try {
            List<PendingServiceRouting> psr = getPendingServiceRouting();
            if (Test.isRunningTest()) {
                return [SELECT Id FROM Case LIMIT 1]?.Id;
            } else if (psr.size() == 0)
                throw new NoCasesFoundException('NotFound');
            return psr[0].WorkItemId;
        } catch (QueryException queryEx) {
            throw new AuraHandledException('En feil oppsto ved henting av ny STO, prøv igjen.');
        }
    }

    /**
     * Queries the PSR with highest priority within your skill pool and ensures you have access to the person,
     * that the case relates to
     **/
    private static List<PendingServiceRouting> getPendingServiceRouting() {
        String userId = '%' + UserInfo.getUserID() + '%';
        return [
            SELECT Id, WorkItemId
            FROM PendingServiceRouting
            WHERE
                Id IN (SELECT RelatedRecordId FROM SkillRequirement WHERE SkillId IN :allUserSkills.skillMap.keySet())
                AND ID NOT IN (
                    SELECT RelatedRecordId
                    FROM SkillRequirement
                    WHERE
                        (Skill.DeveloperName NOT IN :allUserSkills.userConfidentialMap.values()
                        AND Skill.DeveloperName IN :confidentialitySkills)
                        OR (Skill.DeveloperName NOT IN :allUserSkills.userOriginMap.values()
                        AND Skill.DeveloperName IN :originSkills)
                )
                AND ServiceChannel.DeveloperName = 'Skriv_til_oss'
                AND IsReadyForRouting = TRUE
                AND isPushed = FALSE
                AND (NOT WorkItem.NKS_Incompetent_IDs__c LIKE :userId)
            ORDER BY RoutingPriority, SecondaryRoutingPriority DESC NULLS LAST, CreatedDate
            LIMIT 1
        ];
    }

    public class GroupedSkills {
        @AuraEnabled
        public Map<Id, String> skillMap = new Map<Id, String>();
        @AuraEnabled
        public Map<Id, String> userConfidentialMap = new Map<Id, String>();
        @AuraEnabled
        public Map<Id, String> userOriginMap = new Map<Id, String>();
    }
}
