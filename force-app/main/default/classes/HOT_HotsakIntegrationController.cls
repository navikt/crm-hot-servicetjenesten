public with sharing class HOT_HotsakIntegrationController {
    // Topp-nivå wrapper for hver "sak"
    public class SakWrapper {
        @AuraEnabled
        public String saksid;
        @AuraEnabled
        public String saksstatus;
        @AuraEnabled
        public String sakstype;
        @AuraEnabled
        public Date opprettet;
        @AuraEnabled
        public Date endret;

        @AuraEnabled
        public Behovsmelding behovsmelding;
        @AuraEnabled
        public List<Hendelse> hendelser = new List<Hendelse>();
        @AuraEnabled
        public List<Saksbehandler> saksbehandler = new List<Saksbehandler>();
        @AuraEnabled
        public List<Oppgave> oppgaver = new List<Oppgave>();
        @AuraEnabled
        public List<Vedtak> vedtak = new List<Vedtak>();
    }

    public class Behovsmelding {
        @AuraEnabled
        public String behovsmeldingId;
        @AuraEnabled
        public String gjelder;
        @AuraEnabled
        public String mottatt;
    }

    public class Hendelse {
        @AuraEnabled
        public String sakshendelseId;
        @AuraEnabled
        public String detaljer;
        @AuraEnabled
        public String hendelse;
        @AuraEnabled
        public String opprettet;
        @AuraEnabled
        public Saksbehandler saksbehandler;
    }

    public class Saksbehandler {
        @AuraEnabled
        public String epost;
        @AuraEnabled
        public String navn;
        @AuraEnabled
        public String saksbehandlerId;
    }

    public class Oppgave {
        @AuraEnabled
        public Boolean feilregistrert;
        @AuraEnabled
        public Boolean ferdigstilt;
        @AuraEnabled
        public String oppgaveId;
        @AuraEnabled
        public String oppgavetype;
        @AuraEnabled
        public String opprettet;
    }

    public class Vedtak {
        @AuraEnabled
        public String vedtakId;
        @AuraEnabled
        public String vedtaksdato;
        @AuraEnabled
        public String vedtaksstatus;
    }

    @AuraEnabled(cacheable=true)
    public static List<SakWrapper> getCases(Id recordId, String objectApiName) {
        // Henter fnr nummer basert på objekt type
        String fnr = fetchPersonIdent(recordId, objectApiName);
        if (String.isBlank(fnr)) {
            // Hvis vi ikke finner fnr, returner en tom liste
            return new List<SakWrapper>();
        }

        // 1) Bygg GraphQL-variabler/operasjoner
        GQLVariable fnrVar = new GQLVariable('fnr', new GQLVariableType('FNR', false, true, false));
        GQLOperation operation = new GQLOperation(
            new GQLOperationType(),
            'MyQuery',
            new GQLVariableDefinitions().addVariable(fnrVar),
            new GQLSelectionSet()
                .addItem(
                    new GQLField('saksoversiktInnbygger')
                        .addArgument(new GQLArgument('fnr', new GQLValue(fnrVar)))
                        .addSelectionSetItem(
                            new GQLField('saker')
                                .addSelectionSetItem(new GQLField('endret'))
                                .addSelectionSetItem(new GQLField('saksstatus'))
                                .addSelectionSetItem(new GQLField('sakstype'))
                                .addSelectionSetItem(new GQLField('opprettet'))
                                .addSelectionSetItem(new GQLField('sakId'))
                                .addSelectionSetItem(
                                    new GQLField('behovsmelding')
                                        .addSelectionSetItem(new GQLField('behovsmeldingId'))
                                        .addSelectionSetItem(new GQLField('gjelder'))
                                        .addSelectionSetItem(new GQLField('mottatt'))
                                )
                                .addSelectionSetItem(
                                    new GQLField('hendelser')
                                        .addSelectionSetItem(new GQLField('detaljer'))
                                        .addSelectionSetItem(new GQLField('hendelse'))
                                        .addSelectionSetItem(new GQLField('opprettet'))
                                        .addSelectionSetItem(
                                            new GQLField('saksbehandler')
                                                .addSelectionSetItem(new GQLField('epost'))
                                                .addSelectionSetItem(new GQLField('navn'))
                                                .addSelectionSetItem(new GQLField('saksbehandlerId'))
                                        )
                                        .addSelectionSetItem(new GQLField('sakshendelseId'))
                                )
                                .addSelectionSetItem(
                                    new GQLField('oppgaver')
                                        .addSelectionSetItem(new GQLField('feilregistrert'))
                                        .addSelectionSetItem(new GQLField('ferdigstilt'))
                                        .addSelectionSetItem(new GQLField('oppgaveId'))
                                        .addSelectionSetItem(new GQLField('oppgavetype'))
                                        .addSelectionSetItem(new GQLField('opprettet'))
                                )
                                .addSelectionSetItem(
                                    new GQLField('vedtak')
                                        .addSelectionSetItem(new GQLField('vedtakId'))
                                        .addSelectionSetItem(new GQLField('vedtaksdato'))
                                        .addSelectionSetItem(new GQLField('vedtaksstatus'))
                                )
                        )
                )
        );

        GQLQuery query = new GQLQuery(operation, (Object) new Map<String, Object>{ fnrVar.getName() => fnr });
        String gqlQueryString = query.build();

        // 2) Opprett og konfigurer ApiController
        LoggerUtility logger = new LoggerUtility('HOT');
        ApiController ac = new ApiController()
            .setLogCategory('HOT')
            .setLogger(logger)
            .setLogCalloutRequest()
            .publishLogAfterCallout()
            .setLogDomain(CRM_ApplicationDomain.Domain.HOT);

        ac.initRequest('HOTSAK', 'POST_HOTSAK_GRAPHQL');
        ac.addServiceAuthHeader('gcpsaasproxy');
        ac.setBody(gqlQueryString);

        // Legg til ekstra headers
        String transactionId = String.valueOf(Crypto.getRandomLong());
        ac.setLogUuid(transactionId);
        ac.setHeaders(new Map<String, String>{ 'Nav-CallId' => transactionId, 'Content-Type' => 'application/json' });

        // 3) Utfør kall
        ac.doCallout();
        String responseBody = ac.getResponse().getBody();

        // 4) Analyser og bygg wrapper-objekter
        // Sjekk for tom/blank respons før parsing
        if (String.isBlank(responseBody)) {
            return new List<SakWrapper>();
        }

        Map<String, Object> rootMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        Map<String, Object> dataMap = (Map<String, Object>) rootMap.get('data');
        if (dataMap == null) {
            return new List<SakWrapper>();
        }

        Map<String, Object> saksoversiktInnbygger = (Map<String, Object>) dataMap.get('saksoversiktInnbygger');
        if (saksoversiktInnbygger == null) {
            return new List<SakWrapper>();
        }

        List<Object> sakerList = (List<Object>) saksoversiktInnbygger.get('saker');
        if (sakerList == null) {
            return new List<SakWrapper>();
        }

        List<SakWrapper> sakWrappers = new List<SakWrapper>();

        for (Object sakObj : sakerList) {
            Map<String, Object> sakMap = (Map<String, Object>) sakObj;

            SakWrapper sw = new SakWrapper();
            sw.saksid = (String) sakMap.get('sakId');
            sw.saksstatus = (String) sakMap.get('saksstatus');
            sw.sakstype = (String) sakMap.get('sakstype');

            // Konverter til Dato hvis ikke tom
            String rawOpprettet = (String) sakMap.get('opprettet');
            if (!String.isBlank(rawOpprettet)) {
                sw.opprettet = Date.valueOf(rawOpprettet.substring(0, 10));
            }

            String rawEndret = (String) sakMap.get('endret');
            if (!String.isBlank(rawEndret)) {
                sw.endret = Date.valueOf(rawEndret.substring(0, 10));
            }

            // Enkeltobjekt behovsmelding
            Map<String, Object> behovsmeldingMap = (Map<String, Object>) sakMap.get('behovsmelding');
            if (behovsmeldingMap != null) {
                Behovsmelding bm = new Behovsmelding();
                bm.behovsmeldingId = (String) behovsmeldingMap.get('behovsmeldingId');
                bm.gjelder = (String) behovsmeldingMap.get('gjelder');
                bm.mottatt = (String) behovsmeldingMap.get('mottatt');
                sw.behovsmelding = bm;
            }

            // Hendelser (liste eller enkeltobjekt)
            List<Object> hendelserList = new List<Object>();
            Object rawHendelser = sakMap.get('hendelser');
            if (rawHendelser != null) {
                if (rawHendelser instanceof List<Object>) {
                    hendelserList = (List<Object>) rawHendelser;
                } else {
                    hendelserList.add(rawHendelser);
                }
            }
            for (Object hObj : hendelserList) {
                Map<String, Object> hMap = (Map<String, Object>) hObj;
                Hendelse hendelse = new Hendelse();
                hendelse.sakshendelseId = (String) hMap.get('sakshendelseId');
                hendelse.detaljer = (String) hMap.get('detaljer');
                hendelse.hendelse = (String) hMap.get('hendelse');
                hendelse.opprettet = (String) hMap.get('opprettet');

                // Saksbehandler inne i Hendelse
                Map<String, Object> sbMap = (Map<String, Object>) hMap.get('saksbehandler');
                if (sbMap != null) {
                    Saksbehandler sb = new Saksbehandler();
                    sb.epost = (String) sbMap.get('epost');
                    sb.navn = (String) sbMap.get('navn');
                    sb.saksbehandlerId = (String) sbMap.get('saksbehandlerId');
                    hendelse.saksbehandler = sb;
                }
                sw.hendelser.add(hendelse);
            }

            // Oppgaver (liste eller enkeltobjekt)
            List<Object> oppgaverList = new List<Object>();
            Object rawOppgaver = sakMap.get('oppgaver');
            if (rawOppgaver != null) {
                if (rawOppgaver instanceof List<Object>) {
                    oppgaverList = (List<Object>) rawOppgaver;
                } else {
                    oppgaverList.add(rawOppgaver);
                }
            }
            for (Object oObj : oppgaverList) {
                Map<String, Object> oMap = (Map<String, Object>) oObj;
                Oppgave oppg = new Oppgave();
                oppg.feilregistrert = (Boolean) oMap.get('feilregistrert');
                oppg.ferdigstilt = (Boolean) oMap.get('ferdigstilt');
                oppg.oppgaveId = (String) oMap.get('oppgaveId');
                oppg.oppgavetype = (String) oMap.get('oppgavetype');
                oppg.opprettet = (String) oMap.get('opprettet');
                sw.oppgaver.add(oppg);
            }

            // Vedtak (liste eller enkeltobjekt)
            List<Object> vedtakList = new List<Object>();
            Object rawVedtak = sakMap.get('vedtak');
            if (rawVedtak != null) {
                if (rawVedtak instanceof List<Object>) {
                    vedtakList = (List<Object>) rawVedtak;
                } else {
                    vedtakList.add(rawVedtak);
                }
            }
            for (Object vObj : vedtakList) {
                Map<String, Object> vMap = (Map<String, Object>) vObj;
                Vedtak v = new Vedtak();
                v.vedtakId = (String) vMap.get('vedtakId');
                v.vedtaksdato = (String) vMap.get('vedtaksdato');
                v.vedtaksstatus = (String) vMap.get('vedtaksstatus');
                sw.vedtak.add(v);
            }

            sakWrappers.add(sw);
        }
        return sakWrappers;
    }

    @TestVisible
    private static String fetchPersonIdent(Id recordId, String objectApiName) {
        Id personId = getPersonId(recordId, objectApiName);
        if (personId == null) {
            return null;
        }
        return [SELECT Name FROM Person__c WHERE Id = :personId].Name;
    }

    private static Id getPersonId(Id recordId, String objectApiName) {
        if (objectApiName == 'Case') {
            return [SELECT Account.CRM_Person__c FROM Case WHERE Id = :recordId].Account.CRM_Person__c;
        } else if (objectApiName == 'Account') {
            return [SELECT CRM_Person__c FROM Account WHERE Id = :recordId].CRM_Person__c;
        } else if (objectApiName == 'Person__c') {
            return recordId;
        }
        return null;
    }
}
