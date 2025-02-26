public with sharing class HOT_FamilyViewController {
    /* Variables */
    private static final List<PDL_Sivilstandstype> maritalStatusOfInterest = new List<PDL_Sivilstandstype>{
        PDL_Sivilstandstype.GIFT,
        PDL_Sivilstandstype.ENKE_ELLER_ENKEMANN,
        PDL_Sivilstandstype.SEPARERT,
        PDL_Sivilstandstype.REGISTRERT_PARTNER,
        PDL_Sivilstandstype.SEPARERT_PARTNER,
        PDL_Sivilstandstype.GJENLEVENDE_PARTNER
    };

    private final static Map<PDL_AdressebeskyttelseGradering, Integer> gradeWeight = new Map<PDL_AdressebeskyttelseGradering, Integer>{
        PDL_AdressebeskyttelseGradering.STRENGT_FORTROLIG_UTLAND => 2,
        PDL_AdressebeskyttelseGradering.STRENGT_FORTROLIG => 2,
        PDL_AdressebeskyttelseGradering.FORTROLIG => 1,
        PDL_AdressebeskyttelseGradering.UGRADERT => 0
    };

    private static final List<PDL_ForelderBarnRelasjonRolle> parentTypes = new List<PDL_ForelderBarnRelasjonRolle>{
        PDL_ForelderBarnRelasjonRolle.MOR,
        PDL_ForelderBarnRelasjonRolle.FAR,
        PDL_ForelderBarnRelasjonRolle.MEDMOR
    };

    /* Class Relation */
    public class Relation {
        @AuraEnabled
        public String personIdent; //personal identification number(FNR/DNR)
        @AuraEnabled
        public String recordType; //record type marital/child/parent/stillborn/error
        @AuraEnabled
        public String role; //(GIFT/UGIFT...), (BARN), (FAR,MOR...), -
        @AuraEnabled
        public String name; //related person name
        @AuraEnabled
        public String birthDate;
        @AuraEnabled
        public String dateOfDeath;
        @AuraEnabled
        public Boolean deceased = false;
        @AuraEnabled
        public String eventDate; //date if separated/ stillborn date
        @AuraEnabled
        public String ageString;
        @AuraEnabled
        public Integer age;
        @AuraEnabled
        public String sex;
        @AuraEnabled
        public String responsible;
        @AuraEnabled
        public Boolean livesWith = false;
        @AuraEnabled
        public Boolean unauthorized = false;
        @AuraEnabled
        public Boolean confidential = false;
        @AuraEnabled
        public Boolean employee = false;
        @AuraEnabled
        public String confidentialStatus; //fortrolig/strengt_fortrolig
    }

    /* Queries */
    @TestVisible
    private static PDL_API_Response queryMaritalStatusFromPDL(String ident) {
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.navn.fornavn = true;
        query.hentPerson.navn.mellomnavn = true;
        query.hentPerson.navn.etternavn = true;
        query.hentPerson.foedselsdato.foedselsaar = true;
        query.hentPerson.foedselsdato.foedselsdato = true;
        query.hentPerson.kjoenn.kjoenn = true;
        query.hentPerson.doedsfall.doedsdato = true;
        query.hentPerson.adressebeskyttelse.gradering = true;
        query.hentIdenter.historikk = true;
        query.hentIdenter.selectAll();
        return query.execute();
    }

    @TestVisible
    private static PDL_API_Response queryRelationsFromPDL(String ident) {
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.sivilstand.selectAll();
        query.hentPerson.forelderbarnrelasjon.selectAll();
        query.hentPerson.doedfoedtBarn.selectAll();
        query.hentPerson.adressebeskyttelse.gradering = true;
        query.hentPerson.foreldreansvar.selectAll();
        query.hentPerson.foedselsdato.foedselsdato = true;
        query.hentPerson.foedselsdato.foedselsaar = true;
        query.hentPerson.bostedsadresse.vegadresse.selectAll();
        query.hentPerson.bostedsadresse.matrikkeladresse.selectAll();
        query.hentPerson.deltBosted.vegadresse.selectAll();
        query.hentPerson.deltBosted.matrikkeladresse.selectAll();
        query.hentIdenter.historikk = true;
        query.hentIdenter.selectAll();
        return query.execute();
    }

    private static PDL_API_Response queryChildFromPDL(String ident) {
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.navn.fornavn = true;
        query.hentPerson.navn.mellomnavn = true;
        query.hentPerson.navn.etternavn = true;
        query.hentPerson.foedselsdato.foedselsaar = true;
        query.hentPerson.foedselsdato.foedselsdato = true;
        query.hentPerson.kjoenn.kjoenn = true;
        query.hentPerson.doedsfall.doedsdato = true;
        query.hentPerson.adressebeskyttelse.gradering = true;
        query.hentPerson.foreldreansvar.selectAll();
        query.hentPerson.bostedsadresse.vegadresse.selectAll();
        query.hentPerson.bostedsadresse.matrikkeladresse.selectAll();
        query.hentPerson.deltBosted.vegadresse.selectAll();
        query.hentPerson.deltBosted.matrikkeladresse.selectAll();
        query.hentIdenter.historikk = true;
        query.hentIdenter.selectAll();
        return query.execute();
    }

    /**
     * @brief  Function to get relations for a person
     * @param recordId:Id
     * @param objectApiName:String
     * @return relations:List<Relation>
     */
    @AuraEnabled(cacheable=true)
    public static List<Relation> getRelations(Id recordId, String objectApiName) {
        Id personId;
        if (objectApiName == 'Case') {
            personId = [SELECT Account.CRM_Person__c FROM Case WHERE Id = :recordId]?.Account?.CRM_Person__c;
        } else if (objectApiName == 'Account') {
            personId = [SELECT CRM_Person__c FROM Account WHERE Id = :recordId]?.CRM_Person__c;
        } else if (objectApiName == 'LiveChatTranscript') {
            personId = [SELECT Account.CRM_Person__c FROM LiveChatTranscript WHERE Id = :recordId]
                ?.Account
                ?.CRM_Person__c;
        }

        List<Relation> relations = new List<Relation>();
        Boolean access = false;
        String personIdent = null;

        if (personId != null) {
            access = [
                SELECT RecordId, HasReadAccess
                FROM UserRecordAccess
                WHERE UserId = :UserInfo.getUserId() AND RecordId = :personId
            ]
            .HasReadAccess;
            personIdent = [SELECT Id, Name FROM Person__c WHERE Id = :personId]?.Name;
        }

        if (!access) {
            Relation r = new Relation();
            r.recordType = 'ERROR';
            r.name = 'Ikke tilgang til å se relasjoner.';
            relations.add(r);
            return relations;
        }

        if (personIdent == null) {
            Relation r = new Relation();
            r.recordType = 'ERROR';
            r.name = 'Person Ident ikke funnet.';
            relations.add(r);
            return relations;
        }

        PDL_API_Response relationsData;
        try {
            relationsData = queryRelationsFromPDL(personIdent);
        } catch (Exception e) {
            Relation r = new Relation();
            r.recordType = 'ERROR';
            r.name = e.getMessage();
            relations.add(r);
            return relations;
        }

        if (relationsData?.data?.hentPerson == null) {
            Relation r = new Relation();
            r.recordType = 'ERROR';
            if (relationsData?.errors != null && !relationsData.errors.isEmpty()) {
                r.name = relationsData.errors[0].message;
            }
            relations.add(r);
            return relations;
        }

        Relation person = new Relation();
        person.employee = isNavEmployee(relationsData);
        person.confidentialStatus = getConfidentialStatus(relationsData);
        person.confidential = isConfidential(person.confidentialStatus);
        relations.addAll(getMaritalStatus(relationsData, person));
        relations.addAll(getStillBorns(relationsData));
        relations.addAll(getChildren(relationsData, person));
        relations.addAll(getParents(relationsData, person));

        return relations;
    }

    /* Help functions to get relations */
    @TestVisible
    private static List<Relation> getMaritalStatus(PDL_API_Response relationsData, Relation person) {
        List<Relation> maritalPersonList = new List<Relation>();
        Relation r = new Relation();
        r.recordType = 'marital';
        List<PDL_Sivilstand> sivilstand = relationsData?.data?.hentPerson?.sivilstand;
        if (sivilstand == null || sivilstand.isEmpty()) {
            r.role = PDL_Sivilstandstype.UOPPGITT.name();
        } else if (
            sivilstand[0].type == PDL_Sivilstandstype.UOPPGITT ||
            sivilstand[0].type == PDL_Sivilstandstype.UGIFT
        ) {
            r.role = sivilstand[0].type.name();
        } else if (
            sivilstand[0].type == PDL_Sivilstandstype.SKILT ||
            sivilstand[0].type == PDL_Sivilstandstype.SKILT_PARTNER
        ) {
            r.role = sivilstand[0].type.name();
            if (sivilstand[0].gyldigFraOgMed != null) {
                r.eventDate = formatDate(sivilstand[0].gyldigFraOgMed);
            }
        } else if (maritalStatusOfInterest.contains(sivilstand[0].type)) {
            if (sivilstand[0].relatertVedSivilstand != null) {
                PDL_API_Response response = queryMaritalStatusFromPDL(sivilstand[0].relatertVedSivilstand);
                if (isUnauthorized(response)) {
                    Person__c relationPerson = getPerson(getIdentsSet(response));
                    if (!isVisible(person, relationPerson)) {
                        r.unauthorized = true;
                    } else {
                        r.personIdent = getPersonIdent(response);
                        fillRelationFromPerson(r, relationPerson);
                    }
                } else {
                    fillRelationFromResponse(r, response);
                }
            }
            r.role = sivilstand[0].type.name();
            if (sivilstand[0].gyldigFraOgMed != null) {
                r.eventDate = formatDate(sivilstand[0].gyldigFraOgMed);
            }
        }
        maritalPersonList.add(r);
        return maritalPersonList;
    }

    @TestVisible
    private static List<Relation> getStillBorns(PDL_API_Response relationsData) {
        List<Relation> stillBorns = new List<Relation>();
        if (relationsData?.data?.hentPerson?.doedfoedtBarn == null) {
            return stillBorns;
        }
        if (relationsData.data.hentPerson.doedfoedtBarn.isEmpty()) {
            return stillBorns;
        }
        for (PDL_DoedfoedtBarn relation : relationsData.data.hentPerson.doedfoedtBarn) {
            Relation stillBorn = new Relation();
            stillBorn.recordType = 'stillborn';
            stillBorn.role = 'DØDFØDT BARN';
            stillBorn.eventDate = formatDate(relation.dato);
            stillBorns.add(stillBorn);
        }
        return stillBorns;
    }

    @TestVisible
    private static List<Relation> getChildren(PDL_API_Response relationsData, Relation person) {
        List<Relation> children = new List<Relation>();
        // query PDL for child relations
        List<PDL_API_Response> childrenResponse = getChildrenList(getChildrenIdentsSet(relationsData));
        // sort responses by birthdate
        childrenResponse = sortResponseByBirthdate(childrenResponse);
        for (PDL_API_Response childResponse : childrenResponse) {
            Relation child = new Relation();
            child.recordType = 'child';
            child.role = PDL_ForelderBarnRelasjonRolle.BARN.name();

            if (isUnauthorized(childResponse)) {
                Person__c childPerson = getPerson(getIdentsSet(childResponse));

                /* cheking reason for unauthorized response from pdl
                if the reason was employee status
                then show relation */
                if (!isVisible(person, childPerson)) {
                    child.unauthorized = true;
                    children.add(child);
                    continue;
                }
                child.personIdent = getPersonIdent(childResponse);
                fillRelationFromPerson(child, childPerson);
                if (isOver21(child)) {
                    continue;
                }
                child.livesWith = hasSameAddress(relationsData, childPerson);
                child.responsible = getResponsibility(relationsData, child.personIdent);
            } else {
                fillRelationFromResponse(child, childResponse);
                if (isOver21(child)) {
                    continue;
                }
                child.livesWith = hasSameAddress(relationsData, childResponse);
                child.responsible = getResponsibility(relationsData, childResponse);
            }
            children.add(child);
        }
        return children;
    }

    /* Help functions to get children */
    private static List<PDL_API_Response> getChildrenList(Set<String> identsList) {
        List<PDL_API_Response> relationsList = new List<PDL_API_Response>();
        for (String ident : identsList) {
            relationsList.add(queryChildFromPDL(ident));
        }
        return relationsList;
    }

    private static Set<String> getChildrenIdentsSet(PDL_API_Response relationsData) {
        Set<String> children = new Set<String>();
        if (relationsData?.data?.hentPerson?.forelderbarnrelasjon == null) {
            return children;
        }
        for (PDL_Forelderbarnrelasjon relation : relationsData.data.hentPerson.forelderbarnrelasjon) {
            if (
                relation.relatertpersonsrolle == PDL_ForelderBarnRelasjonRolle.BARN &&
                relation.relatertpersonsident != null
            ) {
                children.add(relation.relatertpersonsident);
            }
        }
        return children;
    }

    @TestVisible
    private static List<PDL_API_Response> sortResponseByBirthdate(List<PDL_API_Response> relations) {
        List<PDL_API_Response> result = new List<PDL_API_Response>();
        while (relations.size() > 0) {
            Integer youngest = getYoungest(relations);
            result.add(relations[youngest]);
            relations.remove(youngest);
        }
        return result;
    }

    /**
    * @brief Getting list of parents for person
    * @param relationsData - data queried from PDL with info about relations for person
    @ @param person - Relation object, where employee, confidential and confidentialStatus should be filled
    */
    @TestVisible
    private static List<Relation> getParents(PDL_API_Response relationsData, Relation person) {
        List<Relation> parents = new List<Relation>();
        if (getAge(getAgeDate(relationsData)) >= 21) {
            // if person is 21 or older, then return empty list
            return parents;
        }
        if (relationsData?.data?.hentPerson?.forelderbarnrelasjon == null) {
            // if person does not have relations, return empty list
            return parents;
        }
        Set<String> uniqRelations = new Set<String>();
        for (PDL_Forelderbarnrelasjon relation : relationsData.data.hentPerson.forelderbarnrelasjon) {
            if (parentTypes.contains(relation.relatertpersonsrolle)) {
                Relation parent = new Relation();
                parent.recordType = 'parent';
                parent.role = relation.relatertpersonsrolle.name();
                if (relation.relatertpersonsident != null) {
                    if (!uniqRelations.add(relation.relatertpersonsident)) {
                        continue;
                    }
                    PDL_API_Response parentResponse = queryChildFromPDL(relation.relatertpersonsident);
                    if (isUnauthorized(parentResponse)) {
                        Person__c parentPerson = getPerson(getIdentsSet(parentResponse));
                        // checking reason for unauthorized status
                        // if because of employee status
                        // then show relation
                        if (!isVisible(person, parentPerson)) {
                            person.unauthorized = true;
                            parents.add(parent);
                            continue;
                        }
                        parent.unauthorized = false;
                        parent.personIdent = getPersonIdent(parentResponse);
                        fillRelationFromPerson(parent, parentPerson);
                        parent.livesWith = hasSameAddress(parentPerson, relationsData);
                        parent.responsible = getResponsibility(parent.personIdent, relationsData);
                    } else {
                        fillRelationFromResponse(parent, parentResponse);
                        parent.livesWith = hasSameAddress(parentResponse, relationsData);
                        parent.responsible = getResponsibility(parentResponse, relationsData);
                    }
                }
                parents.add(parent);
            }
        }
        return parents;
    }

    /**
     * @brief Void function to set values on Relation from PDL-response
     * @param relation:Relation
     * @param response:PDL_API_Response
     */
    @TestVisible
    private static void fillRelationFromResponse(Relation relation, PDL_API_Response response) {
        if (relation == null || response == null)
            return;
        relation.name = getFullName(response);
        relation.birthDate = getBirthdate(response);
        relation.age = getAge(getAgeDate(response));
        relation.ageString = getAgeString(getAgeDate(response));
        relation.sex = getSex(response);
        relation.dateOfDeath = getDateOfDeath(response);
        relation.deceased = (relation.dateOfDeath != null) ? true : false;
        relation.confidentialStatus = getConfidentialStatus(response);
        relation.confidential = isConfidential(relation.confidentialStatus);
        relation.employee = isNavEmployee(response);
        relation.personIdent = getPersonIdent(response);
        return;
    }

    /* Help functions for Relation with data from PDL-response */
    @TestVisible
    private static String getFullName(PDL_API_Response response) {
        List<PDL_Navn> navn = response.data?.hentPerson?.navn;
        if (navn == null || navn.isEmpty()) {
            return null;
        }
        List<String> nameParts = new List<String>();
        if (navn[0]?.fornavn != null) {
            nameParts.add(navn[0].fornavn);
        }
        if (navn[0]?.mellomnavn != null) {
            nameParts.add(navn[0].mellomnavn);
        }
        if (navn[0]?.etternavn != null) {
            nameParts.add(navn[0].etternavn);
        }
        if (nameParts.isEmpty()) {
            return null;
        }
        String fullName = String.join(nameParts, ' ');
        if (String.isBlank(fullName)) {
            return null;
        }
        return fullName;
    }

    @TestVisible
    private static String getBirthdate(PDL_API_Response response) {
        List<PDL_Foedselsdato> foedselsdato = response.data?.hentPerson?.foedselsdato;
        if (foedselsdato == null || foedselsdato.isEmpty()) {
            return null;
        }
        if (foedselsdato[0]?.foedselsdato == null) {
            return null;
        }
        return formatDate(foedselsdato[0].foedselsdato);
    }

    @TestVisible
    private static Date getAgeDate(PDL_API_Response response) {
        Date birthDate;
        List<PDL_Foedselsdato> foedselsdato = response.data?.hentPerson?.foedselsdato;
        if (foedselsdato == null || foedselsdato.isEmpty()) {
            return null;
        }
        if (foedselsdato[0]?.foedselsdato != null) {
            birthDate = foedselsdato[0].foedselsdato;
        } else if (foedselsdato[0]?.foedselsaar != null) {
            birthDate = Date.newInstance(foedselsdato[0].foedselsaar, 1, 1);
        } else {
            return null;
        }
        List<PDL_Doedsfall> doedsfall = response.data?.hentPerson?.doedsfall;
        Date d;
        if (doedsfall != null && !doedsfall.isEmpty() && doedsfall[0]?.doedsdato != null) {
            d = doedsfall[0].doedsdato;
        } else {
            d = Date.today();
        }
        // dates starts form 0001.01.01, so doing some math
        return d.addDays(-birthDate.day() + 1).addMonths(-birthDate.month() + 1).addYears(-birthDate.year() + 1);
    }

    @TestVisible
    private static String getSex(PDL_API_Response response) {
        List<PDL_Kjoenn> kjoenn = response.data?.hentPerson?.kjoenn;
        if (kjoenn == null || kjoenn.isEmpty()) {
            return null;
        }
        if (kjoenn[0]?.kjoenn == null) {
            return null;
        }
        return kjoenn[0].kjoenn.name();
    }

    @TestVisible
    private static String getDateOfDeath(PDL_API_Response response) {
        List<PDL_Doedsfall> doedsfall = response.data?.hentPerson?.doedsfall;
        if (doedsfall == null || doedsfall.isEmpty()) {
            return null;
        }
        if (doedsfall[0]?.doedsdato == null) {
            return null;
        }
        return formatDate(doedsfall[0].doedsdato);
    }

    @TestVisible
    private static String getPersonIdent(PDL_API_Response response) {
        if (response.data?.hentIdenter?.identer == null) {
            return null;
        }
        List<String> idents = new List<String>();
        for (PDL_IdentInformasjon ident : response.data.hentIdenter.identer) {
            if (ident.ident != null && ident.historisk != true && ident.gruppe == PDL_IdentGruppe.FOLKEREGISTERIDENT) {
                idents.add(ident.ident);
            }
        }
        if (!idents.isEmpty()) {
            return String.join(idents, ', ');
        }
        return null;
    }

    /**
     * @brief Void function to set values on Relation from Person
     * @param relation:Relation
     * @param relationPerson:Person__c
     */
    @TestVisible
    private static void fillRelationFromPerson(Relation relation, Person__c relationPerson) {
        if (relationPerson == null) {
            return;
        }
        relation.name = getFullName(relationPerson);
        relation.birthDate = getBirthdate(relationPerson);
        relation.age = getAge(getAgeDate(relationPerson));
        relation.ageString = getAgeString(getAgeDate(relationPerson));
        relation.sex = getSex(relationPerson);
        relation.dateOfDeath = getDateOfDeath(relationPerson);
        relation.deceased = (relation.dateOfDeath != null);
        relation.employee = relationPerson.INT_IsNavEmployee__c;
        relation.confidentialStatus = relationPerson.INT_Confidential__c;
        relation.confidential = isConfidential(relation.confidentialStatus);
    }

    /* Help functions for Relation with data from Person */
    @TestVisible
    private static String getFullName(Person__c p) {
        return p.NKS_Full_Name__c;
    }

    @TestVisible
    private static String getBirthdate(Person__c p) {
        if (p?.INT_DateOfBirth__c == null)
            return null;
        return formatDate(Date.valueOf(p.INT_DateOfBirth__c));
    }

    @TestVisible
    private static Date getAgeDate(Person__c p) {
        Date birthDate = p?.INT_DateOfBirth__c != null ? Date.valueOf(p.INT_DateOfBirth__c) : null;
        if (birthDate == null) {
            return null;
        }
        Date d = p?.INT_DateOfDeath__c != null ? Date.valueOf(p.INT_DateOfDeath__c) : Date.today();
        return d.addDays(-birthDate.day() + 1).addMonths(-birthDate.month() + 1).addYears(-birthDate.year() + 1);
    }

    private static String getSex(Person__c p) {
        return p.INT_Sex__c;
    }

    @TestVisible
    private static String getDateOfDeath(Person__c p) {
        if (p?.INT_DateOfDeath__c == null)
            return null;
        return formatDate(Date.valueOf(p.INT_DateOfDeath__c));
    }

    /* Functions related to address */
    @TestVisible
    public static Boolean hasSameAddress(PDL_API_Response parent, PDL_API_Response child) {
        if (parent?.data?.hentPerson?.bostedsadresse == null || parent.data.hentPerson.bostedsadresse.isEmpty()) {
            return false;
        }
        PDL_Vegadresse parentAddress = parent.data.hentPerson.bostedsadresse[0]?.vegadresse;
        if (parentAddress == null) {
            return false;
        }
        PDL_Vegadresse childAddress1;
        PDL_Vegadresse childAddress2;
        if (child?.data?.hentPerson?.bostedsadresse != null && !child.data.hentPerson.bostedsadresse.isEmpty()) {
            childAddress1 = child.data.hentPerson.bostedsadresse[0].vegadresse;
        }
        if (child?.data?.hentPerson?.deltBosted != null && !child.data.hentPerson.deltBosted.isEmpty()) {
            childAddress2 = child.data.hentPerson.deltBosted[0].vegadresse;
        }
        Boolean childAddress1Match = true;
        Boolean childAddress2Match = true;

        childAddress1Match &= (parentAddress.matrikkelId == childAddress1?.matrikkelId);
        childAddress2Match &= (parentAddress.matrikkelId == childAddress2?.matrikkelId);

        childAddress1Match &= compareAddressPartsRequired(parentAddress.husnummer, childAddress1?.husnummer);
        childAddress2Match &= compareAddressPartsRequired(parentAddress.husnummer, childAddress2?.husnummer);

        childAddress1Match &= compareAddressParts(parentAddress.husbokstav, childAddress1?.husbokstav);
        childAddress2Match &= compareAddressParts(parentAddress.husbokstav, childAddress2?.husbokstav);

        childAddress1Match &= compareAddressParts(parentAddress.bruksenhetsnummer, childAddress1?.bruksenhetsnummer);
        childAddress2Match &= compareAddressParts(parentAddress.bruksenhetsnummer, childAddress2?.bruksenhetsnummer);

        childAddress1Match &= compareAddressPartsRequired(parentAddress.adressenavn, childAddress1?.adressenavn);
        childAddress2Match &= compareAddressPartsRequired(parentAddress.adressenavn, childAddress2?.adressenavn);

        childAddress1Match &= compareAddressPartsRequired(parentAddress.kommunenummer, childAddress1?.kommunenummer);
        childAddress2Match &= compareAddressPartsRequired(parentAddress.kommunenummer, childAddress2?.kommunenummer);

        childAddress1Match &= compareAddressParts(parentAddress.bydelsnummer, childAddress1?.bydelsnummer);
        childAddress2Match &= compareAddressParts(parentAddress.bydelsnummer, childAddress2?.bydelsnummer);

        childAddress1Match &= compareAddressPartsRequired(parentAddress.postnummer, childAddress1?.postnummer);
        childAddress2Match &= compareAddressPartsRequired(parentAddress.postnummer, childAddress2?.postnummer);

        childAddress1Match &= compareAddressParts(parentAddress.tilleggsnavn, childAddress1?.tilleggsnavn);
        childAddress2Match &= compareAddressParts(parentAddress.tilleggsnavn, childAddress2?.tilleggsnavn);

        return childAddress1Match || childAddress2Match;
    }

    @TestVisible
    private static Boolean hasSameAddress(PDL_API_Response parent, Person__c child) {
        if (parent?.data?.hentPerson?.bostedsadresse == null || parent.data.hentPerson.bostedsadresse.isEmpty()) {
            return false;
        }
        PDL_Vegadresse parentAddress = parent.data.hentPerson.bostedsadresse[0]?.vegadresse;
        if (parentAddress == null) {
            return false;
        }
        Boolean childAddress1Match = true;

        String parentResidentialAddress = addressCreator(
            new List<String>{ parentAddress.adressenavn, parentAddress.husnummer, parentAddress.husbokstav }
        );
        childAddress1Match &= compareAddressPartsRequired(parentResidentialAddress, child.INT_ResidentialAddress__c);
        childAddress1Match &= compareAddressPartsRequired(
            parentAddress.kommunenummer,
            child?.INT_AddressMunicipalityNumber__c
        );
        childAddress1Match &= compareAddressParts(parentAddress.bydelsnummer, child?.INT_AddressDistrictNumber__c);
        childAddress1Match &= compareAddressPartsRequired(parentAddress.postnummer, child?.INT_ResidentialZipCode__c);

        return childAddress1Match;
    }

    @TestVisible
    private static Boolean hasSameAddress(Person__c parent, PDL_API_Response child) {
        PDL_Vegadresse childAddress1;
        PDL_Vegadresse childAddress2;
        Boolean childAddress1Match = false;
        Boolean childAddress2Match = false;
        if (child?.data?.hentPerson?.bostedsadresse != null && !child.data.hentPerson.bostedsadresse.isEmpty()) {
            childAddress1 = child.data.hentPerson.bostedsadresse[0].vegadresse;
            String childResidentialAddress1 = addressCreator(
                new List<String>{ childAddress1?.adressenavn, childAddress1?.husnummer, childAddress1?.husbokstav }
            );
            childAddress1Match = true;
            childAddress1Match &= compareAddressPartsRequired(
                parent.INT_ResidentialAddress__c,
                childResidentialAddress1
            );
            childAddress1Match &= compareAddressPartsRequired(
                parent.INT_AddressMunicipalityNumber__c,
                childAddress1.kommunenummer
            );
            childAddress1Match &= compareAddressParts(parent.INT_AddressDistrictNumber__c, childAddress1.bydelsnummer);
            childAddress1Match &= compareAddressPartsRequired(
                parent.INT_ResidentialZipCode__c,
                childAddress1.postnummer
            );
        }
        if (child?.data?.hentPerson?.deltBosted != null && !child.data.hentPerson.deltBosted.isEmpty()) {
            childAddress2 = child.data.hentPerson.deltBosted[0].vegadresse;
            String childResidentialAddress2 = addressCreator(
                new List<String>{ childAddress2?.adressenavn, childAddress2?.husnummer, childAddress2?.husbokstav }
            );
            childAddress2Match = true;
            childAddress2Match &= compareAddressPartsRequired(
                parent.INT_ResidentialAddress__c,
                childResidentialAddress2
            );
            childAddress2Match &= compareAddressPartsRequired(
                parent.INT_AddressMunicipalityNumber__c,
                childAddress2.kommunenummer
            );
            childAddress2Match &= compareAddressParts(parent.INT_AddressDistrictNumber__c, childAddress2.bydelsnummer);
            childAddress2Match &= compareAddressPartsRequired(
                parent.INT_ResidentialZipCode__c,
                childAddress2.postnummer
            );
        }
        return childAddress1Match || childAddress2Match;
    }

    // part of Address could be missing
    @TestVisible
    private static Boolean compareAddressParts(String parent, String child) {
        if (parent == child || (String.isBlank(parent) && String.isBlank(child)))
            return true;
        return false;
    }

    // part of Address is required
    @TestVisible
    private static Boolean compareAddressPartsRequired(String parent, String child) {
        if (parent != null && String.isNotBlank(parent) && parent == child) {
            return true;
        }
        return false;
    }

    @TestVisible
    private static String addressCreator(List<String> addressFields) {
        String addressString = '';
        for (String addressField : addressFields) {
            if (stringValidator(addressField) != '') {
                addressString += stringValidator(addressField) + ' ';
            }
        }
        return addressString.removeEnd(' ');
    }

    @TestVisible
    private static String stringValidator(String stringToCheck) {
        return String.isBlank(stringToCheck) || stringToCheck == null ? '' : stringToCheck.left(255);
    }

    /* Help functions */
    @TestVisible
    private static Person__c getPerson(Set<String> identsList) {
        return HOT_FamilyViewControllerHelper.getPerson(identsList);
    }

    @TestVisible
    private static Boolean isNavEmployee(PDL_API_Response response) {
        return HOT_FamilyViewControllerHelper.isNavEmployee(getIdentsSet(response));
    }

    @TestVisible
    private static Boolean isNavEmployee(String id) {
        Set<String> idents = new Set<String>();
        idents.add(id);
        return HOT_FamilyViewControllerHelper.isNavEmployee(idents);
    }

    @TestVisible
    public static String getConfidentialStatus(PDL_API_Response response) {
        List<PDL_Adressebeskyttelse> adressebeskyttelse = response.data?.hentPerson?.adressebeskyttelse;
        if (adressebeskyttelse == null || adressebeskyttelse.isEmpty()) {
            return null;
        }
        if (adressebeskyttelse[0]?.gradering != null) {
            return adressebeskyttelse[0].gradering.name();
        }
        return null;
    }

    @TestVisible
    private static Boolean isConfidential(String status) {
        if (status == null || status == 'UGRADERT') {
            return false;
        }
        return true;
    }

    @TestVisible
    private static Integer getAge(Date d) {
        if (d == null) {
            return null;
        }
        return d.year() - 1;
    }

    @TestVisible
    private static String getAgeString(Date d) {
        if (d == null) {
            return null;
        }

        if (d.year() - 1 < 2) {
            if (d.month() - 1 > 0 || (d.year() - 1) > 0) {
                return String.valueOf((d.year() - 1) * 12 + d.month() - 1) + ' mnd';
            }
            return String.valueOf(d.day() - 1) + ' d';
        }
        return String.valueOf(d.year() - 1) + ' år';
    }

    @TestVisible
    private static String formatDate(Date d) {
        if (d == null) {
            return null;
        }
        return DateTime.newInstance(d, Time.newInstance(0, 0, 0, 0)).format('dd.MM.yyyy');
    }

    private static Date getBirthdayDate(PDL_API_Response response) {
        List<PDL_Foedselsdato> foedselsdato = response.data?.hentPerson?.foedselsdato;
        if (foedselsdato == null || foedselsdato.isEmpty()) {
            return null;
        }
        if (foedselsdato[0]?.foedselsdato == null) {
            return null;
        }
         return foedselsdato[0].foedselsdato;
    }

    @TestVisible
    private static Boolean isOver21(PDL_API_Response response) {
        Integer age = getAge(getAgeDate(response));
        if (age == null || age <= 21) {
            return false;
        }
        return true;
    }

    @TestVisible
    private static Boolean isOver21(Relation r) {
        if (!r.deceased && r.age > 21) {
            return true;
        }
        return false;
    }

    @TestVisible
    private static Integer getYoungest(List<PDL_API_Response> relations) {
        Integer index = 0;
        for (Integer i = 0; i < relations.size(); i++) {
            if (compareBirthdayDates(relations[index], relations[i]) < 0)
                index = i;
        }
        return index;
    }

    @TestVisible
    private static Integer compareDates(Date d1, Date d2) {
        if (d1 == null && d2 == null)
            return 0;
        if (d1 == null && d2 != null)
            return -1;
        if (d1 != null && d2 == null)
            return 1;
        return d2.daysBetween(d1);
    }

    private static Integer compareBirthdayDates(PDL_API_Response r1, PDL_API_Response r2) {
        return compareDates(getBirthdayDate(r1), getBirthdayDate(r2));
    }

    @TestVisible
    private static Boolean isUnauthorized(PDL_API_Response response) {
        if (response.errors != null) {
            for (PDL_Error error : response.errors) {
                if (error.extensions?.code == 'unauthorized') {
                    return true;
                }
            }
        }
        return false;
    }

    @TestVisible
    private static Boolean isConfidentialRelation(PDL_API_Response person, PDL_API_Response relation) {
        PDL_AdressebeskyttelseGradering personGradering;
        PDL_AdressebeskyttelseGradering relationGradering;
        if (
            person?.data?.hentPerson?.adressebeskyttelse != null && !person.data.hentPerson.adressebeskyttelse.isEmpty()
        ) {
            personGradering = person.data.hentPerson.adressebeskyttelse[0].gradering;
        }
        if (
            relation?.data?.hentPerson?.adressebeskyttelse != null &&
            !relation.data.hentPerson.adressebeskyttelse.isEmpty()
        ) {
            relationGradering = relation.data.hentPerson.adressebeskyttelse[0].gradering;
        }
        return isConfidentialRelation(personGradering, relationGradering);
    }

    @TestVisible
    private static Boolean isConfidentialRelation(String person, String relation) {
        PDL_AdressebeskyttelseGradering personGradering = null;
        PDL_AdressebeskyttelseGradering relationGradering = null;
        try {
            personGradering = PDL_AdressebeskyttelseGradering.valueOf(person);
        } catch (Exception e) {
            // keep value as null
        }
        try {
            relationGradering = PDL_AdressebeskyttelseGradering.valueOf(relation);
        } catch (Exception e) {
            // keep value as null
        }
        return isConfidentialRelation(personGradering, relationGradering);
    }

    @TestVisible
    private static Boolean isConfidentialRelation(
        PDL_AdressebeskyttelseGradering person,
        PDL_AdressebeskyttelseGradering relation
    ) {
        Integer personGrade = (person != null) ? gradeWeight.get(person) : 0;
        Integer relationGrade = (relation != null) ? gradeWeight.get(relation) : 0;
        return (personGrade < relationGrade);
    }

    @TestVisible
    private static Boolean isVisible(Relation person, Person__c relation) {
        if (relation == null || !relation.INT_IsNavEmployee__c) {
            return false; //if the reason for unauthorized is not because of 'employee'
        }
        if (isConfidentialRelation(person.confidentialStatus, relation.INT_Confidential__c)) {
            return false; //if employee, but confidential
        }
        return true;
    }

    @TestVisible
    private static Set<String> getIdentsSet(PDL_API_Response response) {
        if (response.data?.hentIdenter?.identer == null) {
            return null;
        }
        Set<String> identer = new Set<String>();
        for (PDL_IdentInformasjon ident : response.data.hentIdenter.identer) {
            if (ident?.ident != null) {
                identer.add(ident.ident);
            }
        }
        if (identer.isEmpty()) {
            return null;
        }
        return identer;
    }

    /*Funcitons to get responsible from Foreldreansvar-table */
    @TestVisible
    private static String getResponsibility(PDL_API_Response parent, PDL_API_Response child) {
        Set<String> idents = getIdentsSet(parent);
        if (child?.data?.hentPerson?.foreldreansvar != null) {
            for (PDL_Foreldreansvar foreldreansvar : child.data.hentPerson.foreldreansvar) {
                if (idents.contains(foreldreansvar.ansvarlig)) {
                    return foreldreansvar.ansvar;
                }
            }
        }

        idents = getIdentsSet(child);
        if (parent?.data?.hentPerson?.foreldreansvar != null) {
            for (PDL_Foreldreansvar foreldreansvar : parent.data.hentPerson.foreldreansvar) {
                if (idents.contains(foreldreansvar.ansvarssubjekt)) {
                    return foreldreansvar.ansvar;
                }
            }
        }
        return null;
    }

    @TestVisible
    public static String getResponsibility(PDL_API_Response parent, String childId) {
        if (parent?.data?.hentPerson?.foreldreansvar != null) {
            for (PDL_Foreldreansvar foreldreansvar : parent.data.hentPerson.foreldreansvar) {
                if (foreldreansvar.ansvarssubjekt == childId) {
                    return foreldreansvar.ansvar;
                }
            }
        }
        return null;
    }

    @TestVisible
    private static String getResponsibility(String parentId, PDL_API_Response child) {
        if (child?.data?.hentPerson?.foreldreansvar != null) {
            for (PDL_Foreldreansvar foreldreansvar : child.data.hentPerson.foreldreansvar) {
                if (foreldreansvar.ansvarlig == parentId) {
                    return foreldreansvar.ansvar;
                }
            }
        }
        return null;
    }
}
