public with sharing class HOT_PersonBadgesController {
    private static Map<String, String> languageMap {
        get {
            if (languageMap == null) {
                languageMap = new Map<String, String>();
                for (Common_Code__c land : [
                    SELECT Id, Name, CRM_Code__c
                    FROM Common_Code__c
                    WHERE CRM_Code_set__c = 'Språk'
                ]) {
                    languageMap.put(land.CRM_Code__c, land.Name);
                }
            }
            return languageMap;
        }
        private set {
        }
    }
    /**
     * @description Get an apex type holding all the data we need for showing badges.
     */
    @AuraEnabled(cacheable=true)
    public static PersonBadgeData getPersonBadgesAndInfo(
        String field,
        String parentObject,
        String parentRecordId,
        Boolean filterOpenSTO
    ) {
        Id personId = getPersonId(field, parentObject, parentRecordId);
        Person__c person = getPerson(personId);
        PersonBadgeData badges = new PersonBadgeData(person);
        if (parentObject.equalsIgnoreCase('Case')) {
            if (filterOpenSTO == null)
                filterOpenSTO = false;
            badges.setOpenSTO(parentRecordId, filterOpenSTO);
        }
        return badges;
    }

    /**
     * @description Dynamically find the person ID
     * Example: field = 'Account.CRM_Person__c', parentObject = 'Case', parentRecordId = '5001X000007xMSuQAM'
     */
    private static Id getPersonId(String field, String parentObject, String parentRecordId) {
        String queryString = 'SELECT ' + field + ' FROM ' + parentObject + ' WHERE Id = :parentRecordId LIMIT 1';
        List<SObject> objList = Database.query(String.escapeSingleQuotes(queryString));
        return !objList.isEmpty() ? (Id) getFieldValue(objList[0], field) : null;
    }

    /**
     * @description recursive method for collecting the value of a field on a sObject
     */
    private static Object getFieldValue(SObject obj, String fieldName) {
        if (obj == null) {
            return null;
        }
        List<String> fieldNameList = fieldName.split('\\.');

        return fieldNameList.size() > 1
            ? getFieldValue(obj.getSObject(fieldNameList.remove(0)), String.join(fieldNameList, '.'))
            : obj.get(fieldNameList[0]);
    }

    /**
     * @description The get Person query is made dynamic in order to use some HOT fields without having a package dependency.
     */
    private static Person__c getPerson(Id personId) {
        Set<String> objectFields = Schema.SObjectType.Person__c.fields.getMap().keySet();
        Set<String> fields = new Set<String>{
            'Id',
            'INT_GuardianshipOrFuturePowerOfAttorney__c',
            'INT_IsDeceased__c',
            'INT_DateOfDeath__c',
            'INT_PowerOfAttorney__c',
            'INT_SpokenLanguageIntepreter__c',
            'INT_KRR_Reservation__c',
            'NKS_NumberOfSecurityMeasures__c'
        };
        Set<String> fieldsToLabel = new Set<String>{ 'HOT_DegreeOfHearingAndVisualImpairment__c' };

        String queryString = 'SELECT ';
        for (String str : fields) {
            if (objectFields.contains(str.toLowerCase())) {
                queryString += str += ', ';
            }
        }

        for (String str : fieldsToLabel) {
            if (objectFields.contains(str.toLowerCase())) {
                queryString += 'toLabel(' + str + '), ';
            }
        }

        queryString +=
            '(' +
            '	SELECT Id,' +
            '		INT_Person__c,' +
            '		toLabel(INT_SecurityMeasure__c),' +
            '		INT_ValidFromDate__c,' +
            '		INT_ValidToDate__c' +
            '	FROM SecurityMeasures__r' +
            ')';
        queryString += ' FROM Person__c WHERE Id = :personId';

        List<Person__c> personList = (List<Person__c>) Database.query(queryString);
        return personList.isEmpty() ? null : personList[0];
    }

    /**
     * @description Apex type as an inner class. The constructor accepts a person record to populate all the variables.
     */
    public class PersonBadgeData {
        @AuraEnabled
        public List<Badge> badges;
        @AuraEnabled
        public List<SecurityMeasure> securityMeasures;
        @AuraEnabled
        public List<String> spokenLanguagesIntepreter;
        @AuraEnabled
        public List<GuardianshipOrFuturePowerOfAttorney> guardianships;
        @AuraEnabled
        public List<PowerOfAttorney> powerOfAttorneys;
        @AuraEnabled
        public List<String> errors;
        @AuraEnabled
        public Date dateOfDeath;
        // @AuraEnabled
        // public List<String> entitlements;

        private Person__c person;
        private Set<String> fieldSet;
        private Map<String, String> personIdentNameMap;

        public PersonBadgeData(Person__c person) {
            this.badges = new List<Badge>();
            this.securityMeasures = new List<SecurityMeasure>();
            this.spokenLanguagesIntepreter = new List<String>();
            this.guardianships = new List<GuardianshipOrFuturePowerOfAttorney>();
            this.powerOfAttorneys = new List<PowerOfAttorney>();
            this.errors = new List<String>();
            this.personIdentNameMap = new Map<String, String>();
            // this.entitlements = new List<String>();

            if (person != null) {
                this.dateOfDeath = person.INT_DateOfDeath__c;
                this.person = person;
                //Get field set for use later in the class
                this.fieldSet = Schema.SObjectType.Person__c.fields.getMap().keySet();
                setBadgeData();
            }
        }

        private void setBadgeData() {
            setSecurityMeasures();
            setIsDeceased();
            setPowerOfAttorney();
            setGuardianshipOrFuturePowerOfAttorney();
            setSpokenLanguagesIntepreter();
            setDegreeOfHearingAndVisualImpairment();
            setPersonName();
            setKrrReservation();
            // setEntitlements();
        }

        private void setSecurityMeasures() {
            try {
                for (SecurityMeasure__c sm : person.SecurityMeasures__r) {
                    if (sm.INT_ValidToDate__c == null || sm.INT_ValidToDate__c >= Date.today()) {
                        securityMeasures.add(
                            new SecurityMeasure(
                                sm.Id,
                                sm.INT_ValidToDate__c,
                                sm.INT_ValidFromDate__c,
                                sm.INT_SecurityMeasure__c
                            )
                        );
                    }
                }
                if (person.NKS_NumberOfSecurityMeasures__c > 0 && !securityMeasures.isEmpty()) {
                    badges.add(
                        new Badge(
                                'securityMeasures',
                                person.NKS_NumberOfSecurityMeasures__c + ' sikkerhetstiltak',
                                'slds-theme_error slds-m-left_x-small slds-m-vertical_xx-small pointer redBadge',
                                '',
                                '',
                                true
                            )
                            .setBadgeContent(securityMeasures)
                    );
                }
            } catch (Exception e) {
                errors.add('Feil ved uthenting av sikkerhetstiltak');
            }
        }

        private void setSpokenLanguagesIntepreter() {
            if (String.isNotBlank(person.INT_SpokenLanguageIntepreter__c)) {
                List<SpokenLanguagesIntepreter> languages = new List<SpokenLanguagesIntepreter>();
                try {
                    for (String language : person.INT_SpokenLanguageIntepreter__c.split(';')) {
                        if (languageMap.containsKey(language)) {
                            String capCase = languageMap.get(language).toLowerCase().capitalize();
                            spokenLanguagesIntepreter.add(capCase + ' (' + language + ')');
                            languages.add(new SpokenLanguagesIntepreter(capCase + ' (' + language + ')'));
                        } else {
                            spokenLanguagesIntepreter.add(language);
                            languages.add(new SpokenLanguagesIntepreter(language));
                        }
                    }
                } catch (Exception e) {
                    errors.add('Feil ved uthenting av språk for talespråktolk');
                }

                badges.add(
                    new Badge(
                            'spokenLanguageIntepreter',
                            getFieldLabel('INT_SpokenLanguageIntepreter__c'),
                            'slds-theme_warning slds-m-left_x-small slds-m-vertical_xx-small pointer yellowBadge',
                            '',
                            '',
                            true
                        )
                        .setBadgeContent(languages)
                );
            }
        }

        private void setKrrReservation() {
            if (person.INT_KRR_Reservation__c) {
                badges.add(new Badge('krr', getFieldLabel('INT_KRR_Reservation__c')));
            }
        }

        private void setIsDeceased() {
            if (person.INT_IsDeceased__c) {
                badges.add(
                    new Badge(
                            'isDeceased',
                            getFieldLabel('INT_IsDeceased__c'),
                            'slds-theme_warning slds-m-left_x-small slds-m-vertical_xx-small pointer yellowBadge',
                            '',
                            '',
                            true
                        )
                        .setBadgeContent(new IsDeceased(person.INT_DateOfDeath__c))
                );
            }
        }

        private void setPowerOfAttorney() {
            try {
                List<NKS_FullmaktController.Fullmaktsgiver> fullmaktsgivere = (List<NKS_FullmaktController.Fullmaktsgiver>) NKS_FullmaktController.getFullmaktsgiver(
                    person.Id,
                    'Person__c'
                );
                filterFullmaktOmraade(fullmaktsgivere);

                if (fullmaktsgivere == null || fullmaktsgivere.isEmpty())
                    return;

                Date today = Date.today();
                for (Integer i = 0; i < fullmaktsgivere.size(); i++) {
                    NKS_FullmaktController.Fullmaktsgiver fullmaktsgiver = fullmaktsgivere[i];

                    if (
                        fullmaktsgiver.gyldigFraOgMed <= today &&
                        (fullmaktsgiver.gyldigTilOgMed >= today ||
                        fullmaktsgiver.gyldigTilOgMed == null)
                    ) {
                        PowerOfAttorney poa = new PowerOfAttorney();
                        poa.motpartsPersonident = fullmaktsgiver.motpartsPersonident;
                        poa.omraader = fullmaktsgiver.omraader;
                        poa.gyldigFraOgMed = fullmaktsgiver.gyldigFraOgMed;
                        poa.gyldigTilOgMed = fullmaktsgiver.gyldigTilOgMed;
                        poa.motpartsNavn = fullmaktsgiver.motpartsNavn;
                        poa.motpartsRolle = fullmaktsgiver.motpartsRolle;

                        poa.id = String.valueOf(i);
                        personIdentNameMap.put(poa.motpartsPersonident, '');
                        powerOfAttorneys.add(poa);
                    }
                }

                if (!powerOfAttorneys.isEmpty()) {
                    badges.add(
                        new Badge(
                                'powerOfAttorney',
                                'Fullmakt',
                                'slds-theme_warning slds-m-left_x-small slds-m-vertical_xx-small pointer yellowBadge',
                                '',
                                '',
                                true
                            )
                            .setBadgeContent(powerOfAttorneys)
                    );
                }
            } catch (Exception e) {
                errors.add('Feil ved uthenting av fullmakts detaljer:\n' + e.getMessage());
            }
        }

        private void filterFullmaktOmraade(List<NKS_FullmaktController.Fullmaktsgiver> fullmaktsgivere) {
            if (fullmaktsgivere == null || fullmaktsgivere.isEmpty())
                return;

            for (Integer i = (fullmaktsgivere.size() - 1); i >= 0; i--) {
                NKS_FullmaktController.Fullmaktsgiver fullmakt = fullmaktsgivere[i];
                for (Integer j = (fullmakt.omraader.size() - 1); j >= 0; j--) {
                    NKS_FullmaktController.Omraade omraade = fullmakt.omraader[j];
                    if (omraade.handling.contains('KOMMUNISER') || omraade.handling.contains('SKRIV')) {
                        continue;
                    }
                    fullmakt.omraader.remove(j);
                }
                if (fullmakt.omraader == null || fullmakt.omraader.isEmpty()) {
                    fullmaktsgivere.remove(i);
                }
            }
        }

        private void setGuardianshipOrFuturePowerOfAttorney() {
            if (String.isNotBlank(person.INT_GuardianshipOrFuturePowerOfAttorney__c)) {
                try {
                    List<GuardianShipOrFuturePowerOfAttorney> guardianshipList = (List<GuardianshipOrFuturePowerOfAttorney>) JSON.deserialize(
                        person.INT_GuardianshipOrFuturePowerOfAttorney__c,
                        List<GuardianshipOrFuturePowerOfAttorney>.class
                    );
                    for (Integer i = 0; i < guardianshipList.size(); i++) {
                        GuardianShipOrFuturePowerOfAttorney guardianship = guardianshipList[i];
                        guardianship.id = String.valueOf(i);
                        if (String.isNotBlank(guardianship.actualMotpartsPersonident)) {
                            personIdentNameMap.put(guardianship.actualMotpartsPersonident, '');
                        }
                        guardianships.add(guardianship);
                    }
                } catch (Exception e) {
                    errors.add('Feil ved uthenting av vergemål detaljer');
                }

                badges.add(
                    new Badge(
                            'guardianshipOrFuturePowerOfAttorney',
                            'Vergemål',
                            'slds-theme_warning slds-m-left_x-small slds-m-vertical_xx-small pointer yellowBadge',
                            '',
                            '',
                            true
                        )
                        .setBadgeContent(guardianships)
                );
            }
        }

        /**
         * @description We don't have the HOT fields in all sanboxes or scratch orgs, therefore we need to check if they exist before trying to add any badges;
         */
        private void setDegreeOfHearingAndVisualImpairment() {
            if (fieldSet.contains('hot_degreeofhearingandvisualimpairment__c')) {
                String degreeOfHearingAndVisualImpairment = (String) person.get(
                    'HOT_DegreeOfHearingAndVisualImpairment__c'
                );

                if (String.isNotBlank(degreeOfHearingAndVisualImpairment)) {
                    badges.add(new Badge('degreeOfHearingAndVisualImpairment', degreeOfHearingAndVisualImpairment));
                }
            }
        }

        /**
         * @description Setting badge for open STOs
         * This function could have been used to check Case instead of PSR, which means we probably could have removed
         * fetchSpecialSkills() and had a much easier query than the one that fetches PSR. However, since the
         * Case table of records is so big, the query likely would have timed out or taken too long.
         *
         * The code is mostly a duplication of the nksGetStoUtilityController class in crm-sto.
         */
        public void setOpenSTO(String caseId, Boolean filterSTO) {
            if (!filterSTO) {
                setOpenSTO(caseId);
                return;
            }

            Case currentCase = getCurrentCase(caseId);
            if (currentCase == null) {
                return;
            }

            List<String> confidentialitySkillsName = new List<String>{ 'Fortrolig_addresse', 'Skjermede_personer' };
            List<String> originSkillsName = new List<String>{ 'BTO', 'STO' };
            Map<String, String> stoThemeRenames = new Map<String, String>{ 'Ufør' => 'Ufoeretrygd' };

            // Since Omni channel skills are org based, we want to only include skills that are used in STO
            List<String> allRelevantSkills = getAllRelevantSkills(stoThemeRenames);
            allRelevantSkills.addAll(confidentialitySkillsName);
            allRelevantSkills.addAll(originSkillsName);

            Set<Id> skillIds = new Set<Id>();
            Map<Id, String> userConfidentialMap = new Map<Id, String>();
            Map<Id, String> userOriginMap = new Map<Id, String>();

            fetchUserSkills(
                allRelevantSkills,
                confidentialitySkillsName,
                originSkillsName,
                skillIds,
                userConfidentialMap,
                userOriginMap
            );

            List<Id> confidentialitySkillsIds = new List<Id>();
            List<Id> originSkillsIds = new List<Id>();
            fetchSpecialSkills(confidentialitySkillsName, originSkillsName, confidentialitySkillsIds, originSkillsIds);

            List<Id> casesInQueueList = fetchPendingServiceRoutings(
                currentCase,
                skillIds,
                userConfidentialMap.keySet(),
                confidentialitySkillsIds,
                userOriginMap.keySet(),
                originSkillsIds
            );

            if (casesInQueueList.isEmpty()) {
                return;
            }

            List<Thread__c> threadList = fetchThreads(casesInQueueList);

            if (threadList.isEmpty()) {
                return;
            }

            countThreadsAndAddBadges(threadList);
        }

        private List<String> getAllRelevantSkills(Map<String, String> stoThemeRenames) {
            List<String> allRelevantSkills = new List<String>();
            Schema.DescribeFieldResult fieldResult = Case.STO_Category__c.getDescribe();
            for (Schema.PicklistEntry pl : fieldResult.getPicklistValues()) {
                String label = pl.getLabel();
                if (stoThemeRenames.containsKey(label)) {
                    allRelevantSkills.add(stoThemeRenames.get(label));
                } else {
                    allRelevantSkills.add(label);
                }
            }
            return allRelevantSkills;
        }

        private Case getCurrentCase(String caseId) {
            return [
                SELECT Id, RecordType.DeveloperName, AccountId, STO_Category__c, NKS_Theme_Group__r.Name
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
            ];
        }

        private void fetchUserSkills(
            List<String> allRelevantSkills,
            List<String> confidentialitySkillsName,
            List<String> originSkillsName,
            Set<Id> skillIds,
            Map<Id, String> userConfidentialMap,
            Map<Id, String> userOriginMap
        ) {
            for (ServiceResourceSkill srs : [
                SELECT SkillId, Skill.DeveloperName, Skill.MasterLabel
                FROM ServiceResourceSkill
                WHERE
                    ServiceResource.RelatedRecordId = :UserInfo.getUserId()
                    AND Skill.DeveloperName IN :allRelevantSkills
                    AND EffectiveStartDate <= TODAY
                    AND (EffectiveEndDate >= TODAY
                    OR EffectiveEndDate = NULL)
                    AND ServiceResource.IsActive = TRUE
            ]) {
                //Separating domain skills and person access skills
                if (confidentialitySkillsName.contains(srs.Skill.DeveloperName)) {
                    userConfidentialMap.put(srs.SkillId, srs.Skill.DeveloperName);
                } else if (originSkillsName.contains(srs.Skill.DeveloperName)) {
                    userOriginMap.put(srs.SkillId, srs.Skill.DeveloperName);
                } else {
                    skillIds.add(srs.SkillId);
                }
            }
        }

        // Salesforce has a weird bug with filtering on skills, so we query them and add them to a list
        // for use in the PendingServiceRoutning query.
        private void fetchSpecialSkills(
            List<String> confidentialitySkillsName,
            List<String> originSkillsName,
            List<Id> confidentialitySkillsIds,
            List<Id> originSkillsIds
        ) {
            for (Skill skill : [
                SELECT Id, DeveloperName
                FROM Skill
                WHERE DeveloperName IN :confidentialitySkillsName OR DeveloperName IN :originSkillsName
            ]) {
                if (confidentialitySkillsName.contains(skill.DeveloperName)) {
                    confidentialitySkillsIds.add(skill.Id);
                }
                if (originSkillsName.contains(skill.DeveloperName)) {
                    originSkillsIds.add(skill.Id);
                }
            }
        }

        // Salesforce gives us a System.UnexpectedException: Illegal filter on SkillRequirement
        // if we use Skill.DeveloperName instead of SkillId in the filters, so we query the skills
        // as we did previously. For some unknown reason this works ¯\_(ツ)_/¯
        private List<Id> fetchPendingServiceRoutings(
            Case currentCase,
            Set<Id> skillIds,
            Set<Id> userConfidentialSkillIds,
            List<Id> confidentialitySkillsIds,
            Set<Id> userOriginSkillIds,
            List<Id> originSkillsIds
        ) {
            List<Id> casesInQueueList = new List<Id>();
            for (PendingServiceRouting psr : [
                SELECT WorkItemId
                FROM PendingServiceRouting
                WHERE
                    WorkItem.AccountId = :currentCase.AccountId
                    AND Id IN (
                        SELECT RelatedRecordId
                        FROM SkillRequirement
                        WHERE SkillId IN :skillIds
                    )
                    AND Id NOT IN (
                        SELECT RelatedRecordId
                        FROM SkillRequirement
                        WHERE
                            (SkillId NOT IN :userConfidentialSkillIds
                            AND SkillId IN :confidentialitySkillsIds)
                            OR (SkillId NOT IN :userOriginSkillIds
                            AND SkillId IN :originSkillsIds)
                    )
                    AND ServiceChannel.DeveloperName = 'Skriv_til_oss'
                    AND IsReadyForRouting = TRUE
                    AND IsPushed = FALSE
            ]) {
                casesInQueueList.add(psr.WorkItemId);
            }
            return casesInQueueList;
        }

        @TestVisible
        private List<Thread__c> fetchThreads(List<Id> casesInQueueList) {
            return [
                SELECT Id, STO_Category__c, CRM_Thread_Type__c, CRM_Latest_Message_Datetime__c
                FROM Thread__c
                WHERE
                    CRM_Case__c IN (
                        SELECT Id
                        FROM Case
                        WHERE
                            IsClosed = FALSE
                            AND STO_Category__c != NULL
                            AND Status NOT IN ('In progress', 'On Hold', 'Reserved')
                            AND Id IN :casesInQueueList
                    )
                ORDER BY STO_Category__c ASC, CRM_Latest_Message_Datetime__c DESC
            ];
        }

        @TestVisible
        private void countThreadsAndAddBadges(List<Thread__c> threadList) {
            Integer count = 0;
            Map<String, List<Thread__c>> threadsGroupedByQueue = new Map<String, List<Thread__c>>();
            for (Thread__c th : threadList) {
                String category = th.STO_Category__c;
                if (!threadsGroupedByQueue.containsKey(category)) {
                    threadsGroupedByQueue.put(category, new List<Thread__c>());
                }
                threadsGroupedByQueue.get(category).add(th);
                count++;
            }

            List<OpenSTO> openSTOList = new List<OpenSTO>();
            for (String queue : threadsGroupedByQueue.keySet()) {
                openSTOList.add(new OpenSTO(queue, threadsGroupedByQueue.get(queue)));
            }

            badges.add(
                new Badge(
                        'openSTO',
                        String.valueOf(count) + (count == 1 ? ' åpen STO' : ' åpne STO-er'),
                        'slds-theme_success slds-m-left_x-small slds-m-vertical_xx-small pointer greenBadge',
                        '',
                        '',
                        true
                    )
                    .setBadgeContent(openSTOList)
            );
        }

        public void setOpenSTO(String caseId) {
            Case c = [
                SELECT Id, RecordType.DeveloperName, AccountId, STO_Category__c, NKS_Theme_Group__r.Name
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
            ];

            if (c == null) {
                return;
            }

            List<AggregateResult> aggRes = [
                SELECT COUNT(Id) numHenv, STO_Category__c, Origin
                FROM Case
                WHERE
                    AccountId = :c.AccountId
                    AND IsClosed = FALSE
                    AND STO_Category__c != NULL
                    AND Status NOT IN ('In progress', 'On Hold', 'Reserved')
                GROUP BY STO_Category__c, Origin
            ];

            if (aggRes.isEmpty()) {
                return;
            }

            Integer count = 0;
            for (AggregateResult agg : aggRes) {
                count += Integer.valueOf(agg.get('numHenv'));
            }

            badges.add(
                new Badge(
                    'openSTO',
                    String.valueOf(count) + (count == 1 ? ' åpen STO' : ' åpne STO-er'),
                    'slds-theme_success slds-m-left_x-small slds-m-vertical_xx-small pointer greenBadge',
                    '',
                    '',
                    true,
                    JSON.serialize(aggRes)
                )
            );
        }

        private void setPersonName() {
            for (Account acc : [
                SELECT Name, CRM_Person__r.Name, CRM_Person__r.NKS_Full_Name__c
                FROM Account
                WHERE CRM_Person__c != NULL AND CRM_Person__r.Name IN :personIdentNameMap.keySet()
                WITH SYSTEM_MODE
            ]) {
                String name = String.isNotBlank(acc.CRM_Person__r.NKS_Full_Name__c)
                    ? acc.CRM_Person__r.NKS_Full_Name__c
                    : acc.Name;
                personIdentNameMap.put(acc.CRM_Person__r.Name, name);
            }

            for (GuardianshipOrFuturePowerOfAttorney gofoa : guardianships) {
                String name = personIdentNameMap.get(gofoa.actualMotpartsPersonident);
                if (String.isNotBlank(name)) {
                    gofoa.actualNavn = new Navn(name);
                }
            }

            for (PowerOfAttorney poa : powerOfAttorneys) {
                String name = personIdentNameMap.get(poa.motpartsPersonident);
                if (String.isNotBlank(name)) {
                    poa.motpartsNavn = name;
                }
            }
        }

        private String getFieldLabel(String fieldApiName) {
            SObjectType type = Person__c.sObjectType;
            Map<String, Schema.SObjectField> mfields = type.getDescribe().fields.getMap();
            return mfields.get(fieldApiName).getDescribe().getLabel();
        }
    }

    public class Badge {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String styling;
        @AuraEnabled
        public String iconName;
        @AuraEnabled
        public String iconAltText;
        @AuraEnabled
        public Boolean clickable;
        @AuraEnabled
        public String tabindex;
        @AuraEnabled
        public String badgeInfo; //Optional additional info to be sent to frontend
        @AuraEnabled
        public List<BadgeContent> badgeContent;
        @AuraEnabled
        public String badgeContentType {
            get {
                if (this.badgeContent == null || this.badgeContent?.size() == 0)
                    return null;
                return String.valueOf(this.badgeContent[0]).split(':')[0]; // Returns the name of the class instance
            }
        }

        /**
         * @description Constructor for only showing a badge without any formatting or logic
         * @param name name to use in the LWC to identify the badge
         * @param label the label for the badge
         *
         */
        public Badge(String name, String label) {
            this(
                name,
                label,
                'slds-theme_warning slds-m-left_x-small slds-m-vertical_xx-small yellowBadge',
                '',
                '',
                false
            );
        }

        /**
         * @description Constructor for showing badge with formatting or icons
         * @param name  name to use in the LWC to identify the badge
         * @param label the label for the badge
         * @param styling styling to use on the component in the LWC
         * @param iconName icon to use in the LWC, use the icons from SF
         * @param iconAltText alt text to add to the icon
         * @param clickable true if the user should be able to click on the badge to show more info
         */
        public Badge(
            String name,
            String label,
            String styling,
            String iconName,
            String iconAltText,
            Boolean clickable
        ) {
            this.name = name;
            this.label = label;
            this.styling = styling;
            this.iconName = iconName;
            this.iconAltText = iconAltText;
            this.clickable = clickable;
            this.tabindex = this.clickable ? '0' : '-1';
        }

        /**
         * @description Constructor for showing badge with formatting or icons
         * @param name  name to use in the LWC to identify the badge
         * @param label the label for the badge
         * @param styling styling to use on the component in the LWC
         * @param iconName icon to use in the LWC, use the icons from SF
         * @param iconAltText alt text to add to the icon
         * @param clickable true if the user should be able to click on the badge to show more info
         */
        public Badge(
            String name,
            String label,
            String styling,
            String iconName,
            String iconAltText,
            Boolean clickable,
            String badgeInfo
        ) {
            this(name, label, styling, iconName, iconAltText, clickable);
            this.badgeInfo = badgeInfo;
        }

        public Badge setBadgeContent(List<BadgeContent> content) {
            this.badgeContent = content;
            return this;
        }

        public Badge setBadgeContent(BadgeContent content) {
            this.badgeContent = new List<BadgeContent>{ content };
            return this;
        }
    }

    public interface BadgeContent {
    }

    public class IsDeceased implements BadgeContent {
        @AuraEnabled
        public Date dateOfDeath;

        public IsDeceased(Date dateOfDeath) {
            this.dateOfDeath = dateOfDeath;
        }
    }

    public class SpokenLanguagesIntepreter implements BadgeContent {
        @AuraEnabled
        public String language;

        public SpokenLanguagesIntepreter(String language) {
            this.language = language;
        }
    }

    public class PowerOfAttorney extends NKS_FullmaktController.Fullmaktsgiver implements BadgeContent {
    }

    public class Navn {
        @AuraEnabled
        public String fornavn;
        @AuraEnabled
        public String mellomnavn;
        @AuraEnabled
        public String etternavn;
        public Navn(String navn) {
            fornavn = navn;
        }
        @AuraEnabled
        public String fullName {
            get {
                return String.join(new List<String>{ this.fornavn, this.mellomnavn, this.etternavn }, ' ')
                    .normalizeSpace();
            }
        }
    }

    public class Tjenesteomraade {
        @AuraEnabled
        public String tjenesteoppgave;
        @AuraEnabled
        public String tjenestevirksomhet;
    }

    public class GuardianshipOrFuturePowerOfAttorney implements BadgeContent {
        // Common between both old and new
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String embete;
        @AuraEnabled
        public String id;

        // Old format
        @AuraEnabled
        public Navn navn;
        @AuraEnabled
        public String motpartsPersonident;
        @AuraEnabled
        public String omfang;
        @AuraEnabled
        public Boolean omfangetErInnenPersonligOmraade;

        // New format
        @AuraEnabled
        public VergeEllerFullmektig vergeEllerFullmektig;

        @AuraEnabled
        public String omfangLabel {
            get {
                String actualOmfang = vergeEllerFullmektig != null ? vergeEllerFullmektig.omfang : omfang;
                String label = this.omfangMap.get(actualOmfang);
                return String.isNotBlank(label) ? label : actualOmfang;
            }
        }

        @AuraEnabled
        public String omfangetErInnenPersonligOmraadeTxt {
            get {
                Boolean actualOmfangetErInnenPersonligOmraade = vergeEllerFullmektig != null ? vergeEllerFullmektig.omfangetErInnenPersonligOmraade : omfangetErInnenPersonligOmraade;
                return true == actualOmfangetErInnenPersonligOmraade ? 'Ja' : 'Nei';
            }
        }

        @AuraEnabled
        public Navn actualNavn {
            get {
                return vergeEllerFullmektig != null ? vergeEllerFullmektig.navn : navn;
            }
            set {
                if(vergeEllerFullmektig != null){
                    vergeEllerFullmektig.navn = value;
                } else {
                    navn = value;
                }
            }
        }

        @AuraEnabled
        public String actualMotpartsPersonident {
            get {
                return vergeEllerFullmektig != null ? vergeEllerFullmektig.motpartsPersonident : motpartsPersonident;
            }
        }

        @AuraEnabled
        public String motpartLabel {
            get {
                List<String> retString = new List<String>();
                if (String.isNotEmpty(this.actualNavn?.fullName)) {
                    retString.add(this.actualNavn.fullName);
                }
                if (String.isNotEmpty(this.actualMotpartsPersonIdent)) {
                    retString.add(this.actualMotpartsPersonident);
                }

                return String.join(retString, ' - ');
            }
        }

        private Map<String, String> typeMap {
            get {
                return new Map<String, String>{
                    'ensligMindreaarigAsylsoeker' => 'Enslig mindreårig asylsøker',
                    'ensligMindreaarigFlyktning' => 'Enslig mindreårig flyktning inklusive midlertidige saker for denne gruppen',
                    'voksen' => 'Voksen',
                    'midlertidigForVoksen' => 'Voksen midlertidig',
                    'mindreaarig' => 'Mindreårig (unntatt EMF)',
                    'midlertidigForMindreaarig' => 'Mindreårig midlertidig (unntatt EMF)',
                    'forvaltningUtenforVergemaal' => 'Forvaltning utenfor vergemål',
                    'stadfestetFremtidsfullmakt' => 'Fremtidsfullmakt'
                };
            }
        }

        @AuraEnabled
        public String typeLabel {
            get {
                String label = this.typeMap.get(this.type);
                return String.isNotBlank(label) ? label : this.type;
            }
        }

        private Map<String, String> omfangMap {
            get {
                return new Map<String, String>{
                    'utlendingssakerPersonligeOgOekonomiskeInteresser' => 'Ivareta personens interesser innenfor det personlige og økonomiske området herunder utlendingssaken (kun for EMA)',
                    'personligeOgOekonomiskeInteresser' => 'Ivareta personens interesser innenfor det personlige og økonomiske området',
                    'oekonomiskeInteresser' => 'Ivareta personens interesser innenfor det økonomiske området',
                    'personligeInteresser' => 'Ivareta personens interesser innenfor det personlige området'
                };
            }
        }

    }

    public class VergeEllerFullmektig {
        @AuraEnabled
        public String motpartsPersonident;
        @AuraEnabled
        public List<Tjenesteomraade> tjenesteomraade;
        @AuraEnabled
        public Navn navn;
        @AuraEnabled
        public String omfang;
        @AuraEnabled
        public Boolean omfangetErInnenPersonligOmraade;

        @AuraEnabled
        public String tjenesteomraadeLabel {
            get {
                String label = '';
                if (this.tjenesteomraade != null) {
                    for (Tjenesteomraade omraade : this.tjenesteomraade) {
                        if (omraade.tjenestevirksomhet == 'nav') {
                            label +=
                                omraade.tjenesteoppgave.replaceAll('([A-Z])', ' $1').toLowerCase().capitalize() + ', ';
                        }
                    }
                }
                return label.removeEnd(', ');
            }
        }
    }

    public class SecurityMeasure implements BadgeContent {
        @AuraEnabled
        public Id RecordId;
        @AuraEnabled
        public Date ToDate;
        @AuraEnabled
        public Date FromDate;
        @AuraEnabled
        public string SecurityMeasure;

        public SecurityMeasure(Id recordId, Date toDate, Date fromDate, String securityMeasure) {
            this.RecordId = recordId;
            this.ToDate = toDate;
            this.FromDate = fromDate;
            this.SecurityMeasure = securityMeasure;
        }
    }

    public class OpenSTO implements BadgeContent {
        @AuraEnabled
        public String queue;
        @AuraEnabled
        public List<Thread__c> threadList;
        @AuraEnabled
        public Integer threadSize;

        public OpenSTO(String queue, List<Thread__c> threadList) {
            this.queue = queue;
            this.threadList = threadList != null ? threadList : new List<Thread__c>();
            this.threadSize = this.threadList.size();
        }
    }
}