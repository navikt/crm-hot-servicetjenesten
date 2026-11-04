import { LightningElement } from 'lwc';

export default class HotDecisionTreeV1 extends LightningElement {
    // =========================================================
    // BESLUTNINGSTRE
    // =========================================================
    //
    // type:
    //
    // choice = kan velges
    // info   = informasjon, kan IKKE velges
    // result = sluttresultat
    //
    // =========================================================

    decisionTree = [
        // =====================================================
        // KOMMUNAL SAMARBEIDSPARTNER
        // =====================================================
        {
            id: 'bruker-pa-vegne-av-bruker',
            label: 'Bruker/ på vegne av bruker',
            type: 'choice',
            children: [
                {
                    id: 'over-18',
                    label: 'Over 18 år',
                    type: 'choice',
                    infoModal: 'over18',
                    children: [
                        {
                            id: 'er-bruker-selv',
                            label: 'Er bruker selv',
                            type: 'choice',
                            children: [
                                {
                                    id: 'over-18-identifiser',
                                    label: 'Identifiser/still kontrollspørsmål',
                                    type: 'info',
                                    children: [
                                        {
                                            id: 'over-18-identifisert-rett-person',
                                            label: 'Er identifisert',
                                            type: 'choice',
                                            children: [
                                                {
                                                    id: 'over-18-identifisert-rett-person-result',
                                                    label: 'Resultat',
                                                    type: 'result',
                                                    result: 'green',
                                                    resultText: 'Kan få opplysninger'
                                                }
                                            ]
                                        },
                                        {
                                            id: 'over-18-identifisert-feil-person',
                                            label: 'Er ikke identifisert',
                                            type: 'choice',
                                            children: [
                                                {
                                                    id: 'over-18-identifisert-feil-person-result',
                                                    label: 'Resultat',
                                                    type: 'result',
                                                    result: 'red',
                                                    resultText: 'Kan ikke få opplysninger'
                                                }
                                            ]
                                        }
                                    ]
                                }
                            ]
                        },
                        {
                            id: 'over-18-verge',
                            label: 'Verge',
                            type: 'choice',
                            infoModal: 'vergeForVoksneUmyndiggjorte',
                            children: [
                                {
                                    id: 'over-18-verge-identifiser',
                                    label: 'Identifiser/ sjekk vergemål',
                                    type: 'info',
                                    children: [
                                        {
                                            id: 'over-18-verge-har-vergemal',
                                            label: 'Har vergemål',
                                            type: 'choice',
                                            children: [
                                                {
                                                    id: 'over-18-verge-har-vergemal-result',
                                                    label: 'Resultat',
                                                    type: 'result',
                                                    result: 'green',
                                                    resultText: 'Kan få opplysninger'
                                                }
                                            ]
                                        },
                                        {
                                            id: 'over-18-verge-har-ikke-vergemal',
                                            label: 'Har ikke vergemål',
                                            type: 'choice',
                                            children: [
                                                {
                                                    id: 'over-18-verge-har-ikke-vergemal-result',
                                                    label: 'Resultat',
                                                    type: 'result',
                                                    result: 'red',
                                                    resultText: 'Kan ikke få opplysninger'
                                                }
                                            ]
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                },
                {
                    id: 'brukerErTolk',
                    label: 'Bruker = tolk',
                    type: 'choice',
                    infoModal: 'tolk',
                    children: [
                        {
                            id: 'over-18-identifiser',
                            label: 'Identifiser/still kontrollspørsmål',
                            description: 'Sjekk fødsels- og personnr. og still kontrollspørsmål. Se rutine for ',
                            descriptionLinkText: 'identifisering, sikkerhetsspørsmål og habilitet',
                            descriptionLinkUrl:
                                'https://navno.sharepoint.com/:w:/r/sites/ServicetorgetNAVHjelpemidlerogtilrettelegging/_layouts/15/Doc2.aspx?action=edit&sourcedoc=%7B7fa33ef8-448d-4ad0-9081-95ef0642d7e1%7D&wdOrigin=TEAMS-MAGLEV.teamsSdk_ns.rwc&wdExp=TEAMS-TREATMENT&wdhostclicktime=1773130354422&web=1',
                            type: 'info',
                            children: [
                                {
                                    id: 'over-18-identifisert-rett-person',
                                    label: 'Er identifisert',
                                    type: 'choice',
                                    children: [
                                        {
                                            id: 'over-18-identifisert-rett-person-result',
                                            label: 'Resultat',
                                            type: 'result',
                                            result: 'green',
                                            resultText: 'Kan få opplysninger'
                                        }
                                    ]
                                },
                                {
                                    id: 'over-18-identifisert-feil-person',
                                    label: 'Er ikke identifisert',
                                    type: 'choice',
                                    children: [
                                        {
                                            id: 'over-18-identifisert-feil-person-result',
                                            label: 'Resultat',
                                            type: 'result',
                                            result: 'red',
                                            resultText: 'Kan ikke få opplysninger'
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                },
                {
                    id: 'under-18',
                    label: 'Under 18',
                    type: 'choice',
                    infoModal: 'under18',
                    children: [
                        {
                            id: 'under-18-foreldre-med-foreldreansvar',
                            label: 'Foreldre med foreldreansvar / foresatte',
                            type: 'choice',
                            infoModal: 'foreldreForesatteVergeMindreaarige',
                            children: [
                                {
                                    id: 'under-18-foreldre-med-foreldreansvar-identifiser',
                                    label: 'Identifiser/ sjekk foreldreansvar',
                                    type: 'info',
                                    children: [
                                        {
                                            id: 'under-18-med-foreldreansvar-identifisert-rett-person',
                                            label: 'Har foreldreansvar / er foresatt',
                                            type: 'choice',
                                            children: [
                                                {
                                                    id: 'under-18-med-foreldreansvar-identifisert-rett-person-result',
                                                    label: 'Resultat',
                                                    type: 'result',
                                                    result: 'green',
                                                    resultText: 'Kan få opplysninger'
                                                }
                                            ]
                                        },
                                        {
                                            id: 'under-18-med-foreldreansvar-identifisert-feil-person',
                                            label: 'Har ikke foreldreansvar / er ikke foresatt',
                                            type: 'choice',
                                            children: [
                                                {
                                                    id: 'under-18-med-foreldreansvar-identifisert-feil-person-result',
                                                    label: 'Resultat',
                                                    type: 'result',
                                                    result: 'red',
                                                    resultText: 'Kan ikke få opplysninger'
                                                }
                                            ]
                                        }
                                    ]
                                }
                            ]
                        },
                        {
                            id: 'under-18-verge',
                            label: 'Verge',
                            type: 'choice',
                            infoModal: 'foreldreForesatteVergeMindreaarige',
                            children: [
                                {
                                    id: 'under-18-verge-identifiser',
                                    label: 'Identifiser/ sjekk vergemål',
                                    type: 'info',
                                    children: [
                                        {
                                            id: 'under-18-verge-identifisert-rett-person',
                                            label: 'Har vergemål',
                                            type: 'choice',
                                            children: [
                                                {
                                                    id: 'under-18-verge-identifisert-rett-person-result',
                                                    label: 'Resultat',
                                                    type: 'result',
                                                    result: 'green',
                                                    resultText: 'Kan få opplysninger'
                                                }
                                            ]
                                        },
                                        {
                                            id: 'under-18-verge-identifisert-feil-person',
                                            label: 'Har ikke vergemål',
                                            type: 'choice',
                                            children: [
                                                {
                                                    id: 'under-18-verge-identifisert-feil-person-result',
                                                    label: 'Resultat',
                                                    type: 'result',
                                                    result: 'red',
                                                    resultText: 'Kan ikke få opplysninger'
                                                }
                                            ]
                                        }
                                    ]
                                }
                            ]
                        },
                        {
                            id: 'under-18-fosterforeldre',
                            label: 'Fosterforeldre',
                            type: 'choice',
                            infoModal: 'fosterforeldre',
                            children: [
                                {
                                    id: 'under-18-fosterforeldre-identifiser',
                                    label: 'Identifiser',
                                    type: 'info',
                                    children: [
                                        {
                                            id: 'under-18-fosterforeldre-identifiser-fullmakt',
                                            label: 'Fullmakt fra barnevernet',
                                            type: 'choice',
                                            children: [
                                                {
                                                    id: 'under-18-fosterforeldre-identifiser-fullmakt-ja-resultat',
                                                    label: 'Kan få opplysninger',
                                                    type: 'result',
                                                    result: 'green',
                                                    resultText: 'Kan få opplysninger'
                                                }
                                            ]
                                        },
                                        {
                                            id: 'under-18-fosterforeldre-identifiser-fullmakt-nei',
                                            label: 'Har ikke fullmakt',
                                            type: 'choice',
                                            infoModal: 'personerUtenFullmakt',
                                            children: [
                                                {
                                                    id: 'under-18-fosterforeldre-identifiser-fullmakt-nei-resultat',
                                                    label: 'Kan ikke få opplysninger',
                                                    type: 'result',
                                                    result: 'red',
                                                    resultText: 'Kan ikke få opplysninger'
                                                }
                                            ]
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                },
                {
                    id: 'paaroorende',
                    label: 'Pårørende',
                    type: 'choice',
                    infoModal: 'paaroerende',
                    children: [
                        {
                            id: 'paaroorende-identifiser',
                            label: 'Identifiser',
                            type: 'info',
                            children: [
                                {
                                    id: 'paaroorende-fullmakt-samtykke',
                                    label: 'Har fullmakt/samtykke',
                                    type: 'choice',
                                    children: [
                                        {
                                            id: 'paaroorende-fullmakt-samtykke-ja',
                                            label: 'Ja',
                                            type: 'result',
                                            result: 'green',
                                            resultText: 'Kan få opplysninger'
                                        }
                                    ]
                                },
                                {
                                    id: 'paaroorende-fullmakt-ikke-fullmakt',
                                    label: 'Ikke fullmakt',
                                    type: 'choice',
                                    infoModal: 'personerUtenFullmakt',
                                    children: [
                                        {
                                            id: 'paaroorende-ikke-fullmakt-result',
                                            type: 'info',
                                            label: 'Konkret vurdering, må dokumenteres',
                                            children: [
                                                {
                                                    id: 'paaroorende-ikke-fullmakt-result-ja',
                                                    type: 'result',
                                                    result: 'green',
                                                    label: 'Ja',
                                                    resultText: 'Kan få opplysninger'
                                                },
                                                {
                                                    id: 'paaroorende-ikke-fullmakt-result-nei',
                                                    type: 'result',
                                                    result: 'red',
                                                    label: 'Nei',
                                                    resultText: 'Kan ikke få opplysninger'
                                                }
                                            ]
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                },
                {
                    id: 'advokat',
                    label: 'Advokat',
                    type: 'choice',
                    infoModal: 'advokat',
                    children: [
                        {
                            id: 'advokat-identifiser',
                            type: 'info',
                            label: 'Identifiser',
                            children: [
                                {
                                    id: 'advokat-identifiser-har-stillingsfullmakt',
                                    type: 'choice',
                                    label: 'Har stillingsfullmakt',
                                    children: [
                                        {
                                            id: 'advokat-identifiser-har-stillingsfullmakt-ja',
                                            type: 'result',
                                            result: 'green',
                                            label: 'Ja',
                                            resultText: 'Kan få opplysninger'
                                        }
                                    ]
                                },
                                {
                                    id: 'advokat-identifiser-har-stillingsfullmakt-nei',
                                    type: 'choice',
                                    label: 'Har ikke stillingsfullmakt',
                                    children: [
                                        {
                                            id: 'advokat-identifiser-har-stillingsfullmakt-nei-resultat',
                                            type: 'result',
                                            result: 'red',
                                            label: 'Nei',
                                            resultText: 'Kan ikke få opplysninger'
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                },
                {
                    id: 'bpa-personlig-assistent',
                    label: 'BPA / Personlig Assistent',
                    type: 'choice',
                    infoModal: 'personligAssistentBPA',
                    children: [
                        {
                            id: 'identifiser',
                            label: 'Identifiser',
                            type: 'info',
                            children: [
                                {
                                    id: 'identifiser-har-fullmakt',
                                    label: 'Har fullmakt / samtykke',
                                    type: 'choice',
                                    children: [
                                        {
                                            id: 'identifiser-har-fullmakt-ja',
                                            type: 'result',
                                            result: 'green',
                                            label: 'Ja',
                                            resultText: 'Kan få opplysninger'
                                        }
                                    ]
                                },
                                {
                                    id: 'identifiser-har-fullmakt-nei',
                                    type: 'choice',
                                    label: 'Har ikke fullmakt',
                                    infoModal: 'personerUtenFullmakt',
                                    children: [
                                        {
                                            id: 'identifiser-har-fullmakt-nei-resultat',
                                            type: 'result',
                                            result: 'red',
                                            label: 'Nei',
                                            resultText: 'Kan ikke få opplysninger'
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                },
                {
                    id: 'lese-og-sekreteaerhjelp',
                    label: 'Lese- og sekretærhjelp',
                    infoModal: 'leseOgSekretaerhjelp',
                    type: 'choice',
                    children: [
                        {
                            id: 'lese-og-sekreteaerhjelp-identifiser',
                            type: 'info',
                            label: 'Identifiser',
                            children: [
                                {
                                    id: 'lese-og-sekreteaerhjelp-paa-egne-vegne',
                                    type: 'choice',
                                    label: 'På egne vegne (regning)',
                                    children: [
                                        {
                                            id: 'lese-og-sekreteaerhjelp-paa-egne-vegne-resultat',
                                            type: 'result',
                                            result: 'green',
                                            label: 'Ja',
                                            resultText: 'Kan få opplysninger'
                                        }
                                    ]
                                },
                                {
                                    id: 'lese-og-sekreteaerhjelp-paa-vegne-av-bruker',
                                    type: 'choice',
                                    label: 'På vegne av bruker',
                                    children: [
                                        {
                                            id: 'lese-og-sekreteaerhjelp-paa-vegne-av-bruker-har-fullmakt',
                                            type: 'choice',
                                            label: 'Har fullmakt',
                                            children: [
                                                {
                                                    id: 'lese-og-sekreteaerhjelp-paa-vegne-av-bruker-har-fullmakt-ja-resultat',
                                                    type: 'result',
                                                    result: 'green',
                                                    label: 'Ja',
                                                    resultText: 'Kan få opplysninger'
                                                }
                                            ]
                                        },
                                        {
                                            id: 'lese-og-sekreteaerhjelp-paa-vegne-av-bruker-har-fullmakt-nei',
                                            type: 'choice',
                                            label: 'Har ikke fullmakt',
                                            infoModal: 'personerUtenFullmakt',
                                            children: [
                                                {
                                                    id: 'lese-og-sekreteaerhjelp-paa-vegne-av-bruker-har-fullmakt-nei-resultat',
                                                    type: 'result',
                                                    result: 'red',
                                                    label: 'Nei',
                                                    resultText: 'Kan ikke få opplysninger'
                                                }
                                            ]
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                }
            ]
        },
        {
            id: 'bruker-er-mors',
            label: 'Bruker er MORS',
            type: 'choice',
            infoModal: 'doodsbo',
            children: [
                {
                    id: 'bruker-er-mors-paaroorende',
                    type: 'choice',
                    label: 'Pårørende',
                    children: [
                        {
                            id: 'bruker-er-mors-paaroorende-se',
                            type: 'result',
                            label: "Se 'På vegne av bruker'",
                            result: 'orange',
                            resultText: 'Se "På vegne av bruker"'
                        }
                    ]
                },
                {
                    id: 'bruker-er-mors-kommunal-samarbeidspartner',
                    type: 'choice',
                    label: 'Kommunal samarbeidspartner',
                    children: [
                        {
                            id: 'bruker-er-mors-kommunal-samarbeidspartner-se',
                            type: 'result',
                            result: 'orange',
                            resultText: 'Se "Samarbeidspartnere og andre"',
                            label: "Se 'Samarbeidspartnere og andre'"
                        }
                    ]
                }
            ]
        },
        {
            id: 'samarbeidspartnere-og-andre',
            label: 'Samarbeidspartnere og andre',
            type: 'choice',
            infoModal: 'samarbeidspartnereOgAndre',
            children: [
                {
                    id: 'kommunal-samarbeidspartner',
                    label: 'Kommunal samarbeidspartner',
                    type: 'choice',
                    children: [
                        {
                            id: 'hjelpemiddelformidler',
                            label: 'Hjelpemiddelformidler/tekniker',
                            type: 'choice',
                            children: [
                                {
                                    id: 'hjelpemiddelformidler-kontroll',
                                    label: 'Identifiser/still kontrollspørsmål',
                                    type: 'info',
                                    children: [
                                        {
                                            id: 'hjelpemiddelformidler-behov',
                                            label: 'Har tjenestelig behov',
                                            type: 'choice',
                                            children: [
                                                {
                                                    id: 'hjelpemiddelformidler-behov-resultat',
                                                    type: 'result',
                                                    result: 'green',
                                                    resultText: 'Kan få opplysninger'
                                                }
                                            ]
                                        },

                                        {
                                            id: 'hjelpemiddelformidler-ikke-behov',
                                            label: 'Har ikke tjenestelig behov',
                                            type: 'choice',
                                            children: [
                                                {
                                                    id: 'hjelpemiddelformidler-ikke-behov-resultat',
                                                    type: 'result',
                                                    result: 'red',
                                                    resultText: 'Ikke oppgi opplysninger'
                                                }
                                            ]
                                        }
                                    ]
                                }
                            ]
                        },
                        {
                            id: 'leverandor-hjelpemiddel',
                            label: 'Leverandør av hjelpemiddel',
                            type: 'choice',
                            children: [
                                {
                                    id: 'leverandor-med-avtale',
                                    label: 'Leverandør med avtale',
                                    type: 'choice',
                                    children: [
                                        {
                                            id: 'leverandor-med-avtale-kontroll',
                                            label: 'Identifiser/Still kontrollspørsmål',
                                            type: 'info',
                                            children: [
                                                {
                                                    id: 'leverandor-med-avtale-behov',
                                                    label: 'Har tjenestelig behov',
                                                    type: 'choice',
                                                    children: [
                                                        {
                                                            id: 'leverandor-med-avtale-behov-resultat',
                                                            type: 'result',
                                                            result: 'green',
                                                            resultText: 'Kan få opplysninger'
                                                        }
                                                    ]
                                                },

                                                {
                                                    id: 'leverandor-med-avtale-ikke-behov',
                                                    label: 'Har ikke tjenestelig behov',
                                                    type: 'choice',
                                                    children: [
                                                        {
                                                            id: 'leverandor-med-avtale-ikke-behov-resultat',
                                                            type: 'result',
                                                            result: 'red',
                                                            resultText: 'Ikke oppgi opplysninger'
                                                        }
                                                    ]
                                                }
                                            ]
                                        }
                                    ]
                                },
                                // =========================================
                                // LEVERANDØR UTEN AVTALE
                                // =========================================
                                {
                                    id: 'leverandor-uten-avtale',
                                    label: 'Leverandør uten avtale',
                                    type: 'choice',
                                    children: [
                                        {
                                            id: 'leverandor-uten-avtale-kontroll',
                                            label: 'Identifiser - Oppdrag i våre fagsystemer?',
                                            type: 'info',
                                            children: [
                                                {
                                                    id: 'leverandor-uten-avtale-behov',
                                                    label: 'Har tjenestelig behov',
                                                    type: 'choice',
                                                    children: [
                                                        {
                                                            id: 'leverandor-uten-avtale-behov-resultat',
                                                            type: 'result',
                                                            result: 'green',
                                                            resultText: 'Kan få opplysninger'
                                                        }
                                                    ]
                                                },

                                                {
                                                    id: 'leverandor-uten-avtale-ikke-behov',
                                                    label: 'Har ikke tjenestelig behov',
                                                    type: 'choice',
                                                    children: [
                                                        {
                                                            id: 'leverandor-uten-avtale-ikke-behov-resultat',
                                                            type: 'result',
                                                            result: 'red',
                                                            resultText: 'Ikke oppgi opplysninger'
                                                        }
                                                    ]
                                                }
                                            ]
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                },
                // =====================================================
                // HELSE-INSTITUSJONER / BEHANDLERE
                // =====================================================
                {
                    id: 'helse-institusjoner',
                    label: 'Helse-institusjoner/behandlere',
                    type: 'choice',
                    children: [
                        {
                            id: 'helse-kontroll',
                            label: 'Identifiser/Still kontrollspørsmål',
                            type: 'info',
                            children: [
                                {
                                    id: 'helse-konkret-vurdering',
                                    label: 'Konkret vurdering (bruk av skjønn)',
                                    type: 'info',
                                    children: [
                                        {
                                            id: 'helse-behov',
                                            label: 'Har tjenestelig behov',
                                            type: 'choice',

                                            children: [
                                                {
                                                    id: 'helse-behov-resultat',
                                                    type: 'result',
                                                    result: 'green',
                                                    resultText: 'Kan få opplysninger'
                                                }
                                            ]
                                        },

                                        {
                                            id: 'helse-ikke-behov',
                                            label: 'Har ikke tjenestelig behov',
                                            type: 'choice',
                                            children: [
                                                {
                                                    id: 'helse-ikke-behov-resultat',
                                                    type: 'result',
                                                    result: 'red',
                                                    resultText: 'Ikke oppgi opplysninger'
                                                }
                                            ]
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                },
                // =====================================================
                // LEGE / HELSEPERSONELL
                // =====================================================

                {
                    id: 'lege-helsepersonell',
                    label: 'Lege / helsepersonell',
                    type: 'choice',
                    children: [
                        {
                            id: 'lege-kontroll',
                            label: 'Identifiser/Still kontrollspørsmål',
                            type: 'info',
                            children: [
                                {
                                    id: 'lege-fullmakt',
                                    type: 'choice',
                                    label: 'Har fullmakt / muntlig samtykke',
                                    children: [
                                        {
                                            id: 'lege-fullmakt-resultat',
                                            type: 'result',
                                            result: 'green',
                                            resultText: 'Kan få opplysninger'
                                        }
                                    ]
                                },
                                {
                                    id: 'lege-ingen-fullmakt',
                                    type: 'choice',
                                    label: 'Har ikke fullmakt / muntlig samtykke',
                                    infoModal: 'personerUtenFullmakt',
                                    children: [
                                        {
                                            id: 'lege-ikke-fullmakt-resultat',
                                            type: 'result',
                                            result: 'red',
                                            resultText: 'Ikke oppgi opplysninger'
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                },
                // =====================================================
                // SKOLE, BARNEHAGE, PPT
                // =====================================================
                {
                    id: 'skole-barnehage-ppt',
                    label: 'Skole, barnehage, PPT',
                    type: 'choice',
                    children: [
                        {
                            id: 'skole-barnehage-ppt-identifiser',
                            label: 'Identifiser/ Still kontrollspørsmål',
                            type: 'info',
                            children: [
                                {
                                    id: 'skole-barnehage-ppt-begrunner-søknad',

                                    type: 'choice',

                                    label: 'Begrunner av søknad',
                                    children: [
                                        {
                                            id: 'skole-barnehage-ppt-begrunner-søknad-resultat',
                                            label: 'Begrunner av søknad',
                                            type: 'result',
                                            result: 'green',
                                            resultText: 'Kan få opplysninger'
                                        }
                                    ]
                                },
                                {
                                    id: 'skole-barnehage-ppt-ikke-soke-hjelpemidler',
                                    type: 'choice',
                                    label: 'Skal søke hjelpemidler',
                                    children: [
                                        {
                                            id: 'skole-barnehage-ppt-ikke-soke-hjelpemidler-resultat',
                                            label: 'Gi veilending på generelt grunnlag',
                                            type: 'result',
                                            result: 'orange',
                                            resultText: 'Gi veilending på generelt grunnlag.'
                                        }
                                    ]
                                },
                                {
                                    id: 'skole-barnehage-ppt-ikke-soke-hjelpemidler-aktiveringsnokkel-lingdys',
                                    type: 'choice',
                                    label: 'Aktiveringsnøkkel Lingdys',
                                    children: [
                                        {
                                            id: 'skole-barnehage-ppt-ikke-soke-hjelpemidler-aktiveringsnokkel-lingdys-behov',
                                            label: 'Har tjenestelig behov',
                                            type: 'choice',
                                            children: [
                                                {
                                                    id: 'skole-barnehage-ppt-ikke-soke-hjelpemidler-aktiveringsnokkel-lingdys-behov-resultat',
                                                    label: 'Kan få opplysninger',
                                                    type: 'result',
                                                    result: 'green',
                                                    resultText: 'Kan få opplysninger'
                                                }
                                            ]
                                        },
                                        {
                                            id: 'skole-barnehage-ppt-ikke-soke-hjelpemidler-aktiveringsnokkel-lingdys-ikke-behov',
                                            label: 'Har ikke tjenestelig behov',
                                            type: 'choice',
                                            children: [
                                                {
                                                    id: 'skole-barnehage-ppt-ikke-soke-hjelpemidler-aktiveringsnokkel-lingdys-ikke-behov-resultat',
                                                    label: 'Ikke gi opplysninger',
                                                    type: 'result',
                                                    result: 'red',
                                                    resultText: 'Ikke gi opplysninger'
                                                }
                                            ]
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                },
                // =====================================================
                // AUDIOGRAG
                // =====================================================
                {
                    id: 'audiograf',
                    label: 'Audiograf',
                    type: 'choice',
                    children: [
                        {
                            id: 'audiograf-identifiser',
                            label: 'Identifiser/ Still kontrollspørsmål',
                            type: 'info',
                            children: [
                                {
                                    id: 'audiograf-begrunner-soknad',
                                    label: 'Begrunner søknad',
                                    type: 'choice',
                                    children: [
                                        {
                                            id: 'audiograf-begrunner-soknad-resultat',
                                            label: 'Kan få opplysninger',
                                            type: 'result',
                                            result: 'green',
                                            resultText: 'Kan få opplysninger'
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                },
                // =====================================================
                // OPTIKER
                // =====================================================
                {
                    id: 'optiker',
                    label: 'Optiker',
                    type: 'choice',
                    children: [
                        {
                            id: 'optiker-identifiser',
                            label: 'Identifiser/ Still kontrollspørsmål',
                            type: 'info',
                            children: [
                                {
                                    id: 'optiker-begrunner-soknad',
                                    label: 'Begrunner søknad',
                                    type: 'choice',
                                    children: [
                                        {
                                            id: 'optiker-begrunner-soknad-resultat',
                                            label: 'Kan få opplysninger',
                                            type: 'result',
                                            result: 'green',
                                            resultText: 'Kan få opplysninger'
                                        }
                                    ]
                                },
                                {
                                    id: 'optiker-part-i-sak',
                                    label: 'Part i sak (skal ha refusjon)',
                                    type: 'choice',
                                    children: [
                                        {
                                            id: 'optiker-part-i-sak-resultat',
                                            label: 'Kan få opplysninger',
                                            type: 'result',
                                            result: 'green',
                                            resultText: 'Kan få opplysninger'
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                },
                // =====================================================
                // OFFENTLIG INSTANS
                // =====================================================
                {
                    id: 'offentlig-instans',
                    label: 'Offentlig instans',
                    type: 'choice',
                    children: [
                        {
                            id: 'offentlig-instans-fylkeskommune-helfo',
                            label: 'Fylkeskommune / HELFO',
                            type: 'choice',
                            children: [
                                {
                                    id: 'offentlig-instans-fylkeskommune-helfo-tt-kort-sprikevogn',
                                    label: 'TT-Kort / sprikevogn',
                                    type: 'choice',
                                    children: [
                                        {
                                            id: 'offentlig-instans-fylkeskommune-helfo-tt-kort-sprikevogn-resultat',
                                            label: 'Se egne rutiner',
                                            type: 'result',
                                            result: 'red',
                                            resultText: 'Se egne rutiner'
                                        }
                                    ]
                                }
                            ]
                        },
                        {
                            id: 'offentlig-instans-barnevern-bufetat',
                            label: 'Barnevern / Bufetat',
                            type: 'choice',
                            children: [
                                {
                                    id: 'offentlig-instans-barnevern-bufetat-ivertagelse',
                                    label: 'Ivertagelse av barnet',
                                    type: 'choice',
                                    children: [
                                        {
                                            id: 'offentlig-instans-barnevern-bufetat-ivertagelse-resultat',
                                            label: 'Kan få opplysninger',
                                            type: 'result',
                                            result: 'green',
                                            resultText: 'Kan få opplysninger'
                                        }
                                    ]
                                },
                                {
                                    id: 'offentlig-instans-barnevern-bufetat-pa-vegne-av-foreldre',
                                    label: 'På vegne av foreldre',
                                    type: 'choice',
                                    children: [
                                        {
                                            id: 'offentlig-instans-barnevern-bufetat-pa-vegne-av-foreldre-fullmakt',
                                            label: 'Har fullmakt',
                                            type: 'choice',
                                            children: [
                                                {
                                                    id: 'offentlig-instans-barnevern-bufetat-pa-vegne-av-foreldre-fullmakt-resultat',
                                                    label: 'Kan få opplysninger',
                                                    type: 'result',
                                                    result: 'green',
                                                    resultText: 'Kan få opplysninger'
                                                }
                                            ]
                                        },
                                        {
                                            id: 'offentlig-instans-barnevern-bufetat-pa-vegne-av-foreldre-uten-fullmakt',
                                            label: 'Har ikke fullmakt',
                                            type: 'choice',
                                            infoModal: 'personerUtenFullmakt',
                                            children: [
                                                {
                                                    id: 'offentlig-instans-barnevern-bufetat-pa-vegne-av-foreldre-uten-fullmakt-resultat',
                                                    label: 'Kan ikke få opplysninger',
                                                    type: 'result',
                                                    result: 'red',
                                                    resultText: 'Kan ikke få opplysninger'
                                                }
                                            ]
                                        }
                                    ]
                                }
                            ]
                        },
                        {
                            id: 'offentlig-instans-asylmottak-flyktningstjeneste',
                            label: 'Asylmottak / flyktningtjeneste',
                            type: 'choice',
                            children: [
                                {
                                    id: 'offentlig-instans-asylmottak-flyktningstjeneste-identifiser',
                                    label: 'Identifiser/ Still kontrollspørsmål',
                                    type: 'info',
                                    children: [
                                        {
                                            id: 'offentlig-instans-asylmottak-flyktningstjeneste-har-fullmakt',
                                            label: 'Har fullmakt',
                                            type: 'choice',
                                            children: [
                                                {
                                                    id: 'offentlig-instans-asylmottak-flyktningstjeneste-har-fullmakt-resultat',
                                                    label: 'Kan få opplysninger',
                                                    type: 'result',
                                                    result: 'green',
                                                    resultText: 'Kan få opplysninger'
                                                }
                                            ]
                                        },
                                        {
                                            id: 'offentlig-instans-asylmottak-flyktningstjeneste-uten-fullmakt',
                                            label: 'Har ikke fullmakt',
                                            type: 'choice',
                                            infoModal: 'personerUtenFullmakt',
                                            children: [
                                                {
                                                    id: 'offentlig-instans-asylmottak-flyktningstjeneste-uten-fullmakt-resultat',
                                                    label: 'Kan ikke få opplysninger',
                                                    type: 'result',
                                                    result: 'red',
                                                    resultText: 'Kan ikke få opplysninger'
                                                }
                                            ]
                                        }
                                    ]
                                }
                            ]
                        },
                        {
                            id: 'offentlig-instans-fengsel-kriminalomsorg',
                            label: 'Fengsel/kriminalomsorg',
                            type: 'choice',
                            children: [
                                {
                                    id: 'offentlig-instans-fengsel-kriminalomsorgen-identifiser',
                                    label: 'Identifiser/ Still kontrollspørsmål',
                                    type: 'info',
                                    children: [
                                        {
                                            id: 'offentlig-instans-fengsel-kriminalomsorgen-identifiser-tjenestlig-behov',
                                            label: 'Har tjenestlig behov?',
                                            type: 'choice',
                                            children: [
                                                {
                                                    id: 'offentlig-instans-fengsel-kriminalomsorgen-identifiser-tjenestlig-behov-ja',
                                                    label: 'Kan få opplysninger',
                                                    type: 'result',
                                                    result: 'green',
                                                    resultText: 'Kan få opplysninger'
                                                }
                                            ]
                                        }
                                    ]
                                }
                            ]
                        },
                        {
                            id: 'offentlig-instans-politi',
                            label: 'Politi',
                            type: 'choice',
                            children: [
                                {
                                    id: 'offentlig-instans-politi-resultat',
                                    label: 'Kan ikke få opplysninger',
                                    type: 'result',
                                    result: 'red',
                                    resultText: 'Kan ikke få opplysninger.'
                                },
                                {
                                    id: 'offentlig-instans-politi-resultat-skjonn',
                                    label: 'Vi kan motta og videreformidle opplysninger',
                                    type: 'result',
                                    result: 'orange',
                                    resultText: 'Vi kan motta og videreformidle opplysninger'
                                }
                            ]
                        }
                    ]
                },
                // =========================================================
                // ARBEIDSGIVER / TILTAKSARRANGØR / NAV VEILEDER
                // =========================================================
                {
                    id: 'arbeidsgiver-tiltaksarrangor-nav-veileder',
                    label: 'Arbeidsgiver / Tiltaksarrangør / NAV veileder',
                    type: 'choice',
                    children: [
                        {
                            id: 'arbeidsgiver-tiltaksarrangor-nav-veileder-identifiser',
                            label: 'Identifiser/ Still kontrollspørsmål',
                            type: 'info',
                            children: [
                                {
                                    id: 'arbeidsgiver-tiltaksarrangor-nav-veileder-identifiser-fullmakt',
                                    label: 'Har fullmakt',
                                    type: 'choice',
                                    children: [
                                        {
                                            id: 'arbeidsgiver-tiltaksarrangor-nav-veileder-identifiser-fullmakt-resultat',
                                            label: 'Kan få opplysninger',
                                            type: 'result',
                                            result: 'green',
                                            resultText: 'Kan få opplysninger.'
                                        }
                                    ]
                                },
                                {
                                    id: 'arbeidsgiver-tiltaksarrangor-nav-veileder-identifiser-ikke-fullmakt',
                                    label: 'Har ikke fullmakt',
                                    type: 'choice',
                                    infoModal: 'personerUtenFullmakt',
                                    children: [
                                        {
                                            id: 'arbeidsgiver-tiltaksarrangor-nav-veileder-identifiser-ikke-fullmakt-resultat',
                                            label: 'Kan ikke få opplysninger',
                                            type: 'result',
                                            result: 'red',
                                            resultText: 'Kan ikke få opplysninger.'
                                        },
                                        {
                                            id: 'arbeidsgiver-tiltaksarrangor-nav-veileder-identifiser-ikke-fullmakt-resultat-tilrettelegging-arbeid-utdanning',
                                            label: 'Tilrettelegging arbeid/ utdanning',
                                            type: 'choice',
                                            children: [
                                                {
                                                    id: 'arbeidsgiver-tiltaksarrangor-nav-veileder-identifiser-ikke-fullmakt-resultat-tilrettelegging-arbeid-utdanning-resultat',
                                                    label: 'Videreformidle på org.nr uten brukeropplysning.',
                                                    type: 'result',
                                                    result: 'orange',
                                                    resultText: 'Videreformidle på org.nr uten brukeropplysning.'
                                                },
                                                {
                                                    id: 'arbeidsgiver-tiltaksarrangor-nav-veileder-identifiser-ikke-fullmakt-resultat-tilrettelegging-arbeid-utdanning-resultat-2',
                                                    label: 'Nav-veileder henvises til kontaktsperson',
                                                    type: 'result',
                                                    result: 'orange',
                                                    resultText: 'Nav-veileder henvises til kontaktsperson.'
                                                }
                                            ]
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                },
                // =========================================================
                // BORETTSLAG / UTLEIER
                // =========================================================
                {
                    id: 'borettslag-utleier',
                    label: 'Borettslag / Utleier',
                    type: 'choice',
                    children: [
                        {
                            id: 'borettslag-utleier-identifiser',
                            label: 'Identifiser/ still kontrollspørsmål',
                            type: 'info',
                            children: [
                                {
                                    id: 'borettslag-utleier-identifiser-fullmakt',
                                    label: 'Har fullmakt',
                                    type: 'choice',
                                    children: [
                                        {
                                            id: 'borettslag-utleier-identifiser-fullmakt',
                                            label: 'Ja',
                                            type: 'result',
                                            result: 'green',
                                            resultText: 'Kan få opplysninger'
                                        }
                                    ]
                                },
                                {
                                    id: 'borettslag-utleier-identifiser-ingen-fullmakt',
                                    label: 'Ikke fullmakt',
                                    type: 'choice',
                                    infoModal: 'personerUtenFullmakt',
                                    children: [
                                        {
                                            id: 'borettslag-utleier-identifiser-ingen-fullmakt',
                                            label: 'Nei',
                                            type: 'result',
                                            result: 'red',
                                            resultText: 'Kan ikke få opplysninger'
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                },
                // =========================================================
                // MEDIA
                // =========================================================
                {
                    id: 'media',
                    label: 'Media',

                    type: 'choice',
                    children: [
                        {
                            id: 'media-resultat',
                            label: 'Henvis til pressevakt',
                            type: 'result',
                            result: 'red',
                            resultText: 'Henvis til pressevakt'
                        }
                    ]
                }
            ]
        }
    ];

    // =========================================================
    // VALGT STI
    // =========================================================

    /*
     * Inneholder kun valg som brukeren faktisk har gjort.
     *
     * INFO-bokser havner IKKE her.
     *
     * Eksempel:
     *
     * [
     *   'kommunal-samarbeidspartner',
     *   'hjelpemiddelformidler',
     *   'hjelpemiddelformidler-behov'
     * ]
     */

    selectedPath = [];

    shouldScrollToNextStep = false;

    // =========================================================
    // MODAL
    // =========================================================

    isModalOpen = false;

    activeModal = null;

    // =========================================================
    // MODAL TITLE
    // =========================================================

    get modalTitle() {
        switch (this.activeModal) {
            case 'over18':
                return 'Bruker (myndig/over 18) ';

            case 'under18':
                return 'Bruker (mindreårig) under 18 år';
            case 'foreldreForesatteVergeMindreaarige':
                return 'Foreldre/ foresatte/ verge for mindreårig';
            case 'fosterforeldre':
                return 'Fosterforeldre';
            case 'vergeForVoksneUmyndiggjorte':
                return 'Verge for voksne/ umyndiggjorte';
            case 'paaroerende':
                return 'Pårørende';
            case 'personligAssistentBPA':
                return 'Personlig assistent (BPA)';
            case 'leseOgSekretaerhjelp':
                return 'Lese- og sekretærhjelp';
            case 'advokat':
                return 'Advokat';
            case 'personerUtenFullmakt':
                return 'Personer uten fullmakt';
            case 'doodsbo':
                return 'Dødsbo (MORS)';
            case 'tolk':
                return 'Bruker = tolk';
            case 'samarbeidspartnereOgAndre':
                return 'Samarbeidspartnere og andre';
            default:
                return '';
        }
    }

    // =========================================================
    // MODAL VISNING
    // =========================================================

    get modalDescription() {
        switch (this.activeModal) {
            default:
                return '';
        }
    }

    get isOver18Modal() {
        return this.activeModal === 'over18';
    }

    get isUnder18Modal() {
        return this.activeModal === 'under18';
    }

    get isForeldreForesatteVergeMindreaarigeModal() {
        return this.activeModal === 'foreldreForesatteVergeMindreaarige';
    }

    get isFosterforeldreModal() {
        return this.activeModal === 'fosterforeldre';
    }

    get isVergeForVoksneUmyndiggjorteModal() {
        return this.activeModal === 'vergeForVoksneUmyndiggjorte';
    }
    get isPaaroerendeModal() {
        return this.activeModal === 'paaroerende';
    }

    get isPersonligAssistentBPAModal() {
        return this.activeModal === 'personligAssistentBPA';
    }

    get isLeseOgSekretaerhjelpModal() {
        return this.activeModal === 'leseOgSekretaerhjelp';
    }

    get isAdvokatModal() {
        return this.activeModal === 'advokat';
    }

    get isDoodsboModal() {
        return this.activeModal === 'doodsbo';
    }

    get isPersonerUtenFullmaktModal() {
        return this.activeModal === 'personerUtenFullmakt';
    }

    get isTolkModal() {
        return this.activeModal === 'tolk';
    }

    get isSamarbeidspartnereOgAndreModal() {
        return this.activeModal === 'samarbeidspartnereOgAndre';
    }

    // =========================================================
    // BYGG SYNlige NIVÅER
    // =========================================================

    get visibleLevels() {
        const levels = [];

        /*
         * Første nivå.
         */

        let currentNodes = this.decisionTree;

        let level = 0;

        let choiceLevel = 0;

        /*
         * Vi fortsetter så lenge det finnes noder
         * som skal vises.
         */

        while (currentNodes && currentNodes.length > 0) {
            // -------------------------------------------------
            // Legg til dette nivået
            // -------------------------------------------------

            const options = currentNodes.map((node) => {
                return this.prepareNode(node, choiceLevel);
            });

            levels.push({
                level: level,

                choiceLevel: choiceLevel,

                cssClass:
                    'tree-level' +
                    (options.every((option) => option.type === 'result') ? ' tree-level-results' : '') +
                    (choiceLevel === this.selectedPath.length && options.some((option) => option.type === 'choice')
                        ? ' tree-level-active'
                        : ''),

                options: options
            });

            if (currentNodes.length === 1 && currentNodes[0].type === 'info') {
                currentNodes = currentNodes[0].children || [];

                level++;

                continue;
            }

            // -------------------------------------------------
            // Finn valgt node
            // -------------------------------------------------

            const selectedId = this.selectedPath[choiceLevel];

            /*
             * Dersom brukeren ikke har valgt noe
             * på dette nivået, stopper vi her.
             */

            if (!selectedId) {
                break;
            }

            const selectedNode = currentNodes.find((node) => node.id === selectedId);

            if (!selectedNode) {
                break;
            }

            /*
             * Hvis valgt node er et resultat,
             * stopper vi.
             */

            if (selectedNode.type === 'result') {
                break;
            }

            /*
             * Gå til children.
             */

            currentNodes = selectedNode.children || [];

            level++;

            choiceLevel++;
        }

        return levels;
    }

    // =========================================================
    // PREPARE NODE
    // =========================================================

    prepareNode(node, level) {
        const isSelected = this.selectedPath[level] === node.id;

        let cssClass = 'tree-option';

        // -----------------------------------------------------
        // VALGBAR
        // -----------------------------------------------------

        if (node.type === 'choice') {
            cssClass += ' tree-option-choice';
        }

        // -----------------------------------------------------
        // INFORMASJON
        // -----------------------------------------------------

        if (node.type === 'info') {
            cssClass += ' tree-option-info';
        }

        // -----------------------------------------------------
        // VALGT
        // -----------------------------------------------------

        if (isSelected) {
            cssClass += ' tree-option-selected';
        }

        // -----------------------------------------------------
        // RESULTAT
        // -----------------------------------------------------

        if (node.type === 'result') {
            if (node.result === 'green') {
                cssClass += ' tree-option-green';
            }

            if (node.result === 'red') {
                cssClass += ' tree-option-red';
            }

            if (node.result === 'orange') {
                cssClass += ' tree-option-orange';
            }
        }

        return {
            ...node,

            cssClass: cssClass,

            isChoice: node.type === 'choice',

            isInfo: node.type === 'info',

            isResult: node.type === 'result'
        };
    }

    // =========================================================
    // KLIKK PÅ VALG
    // =========================================================

    handleDescriptionLinkClick(event) {
        event.stopPropagation();
    }

    handleOptionClick(event) {
        const optionId = event.currentTarget.dataset.id;

        const level = Number(event.currentTarget.dataset.level);

        /*
         * Finn nodene på dette nivået.
         */

        const nodes = this.getNodesForLevel(level);

        const node = nodes.find((item) => item.id === optionId);

        if (!node) {
            return;
        }

        /*
         * Bare choice kan velges.
         */

        if (node.type !== 'choice') {
            return;
        }

        /*
         * Fjern alle valg som ligger etter
         * dette nivået.
         */

        this.selectedPath = this.selectedPath.slice(0, level);

        /*
         * Legg til det nye valget.
         */

        this.selectedPath = [...this.selectedPath, optionId];

        this.shouldScrollToNextStep = true;
    }

    renderedCallback() {
        if (!this.shouldScrollToNextStep) {
            return;
        }

        this.shouldScrollToNextStep = false;

        const nextStep =
            this.template.querySelector('.tree-level-active') || this.template.querySelector('.tree-level:last-child');

        if (nextStep) {
            nextStep.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
    }

    // =========================================================
    // FINN NODER PÅ ET BESTEMT NIVÅ
    // =========================================================

    getNodesForLevel(level) {
        let nodes = this.decisionTree;

        /*
         * Vi følger brukerens valg frem til
         * ønsket nivå.
         */

        for (let i = 0; i < level; i++) {
            const selectedId = this.selectedPath[i];

            if (!selectedId) {
                return [];
            }

            const selectedNode = nodes.find((node) => node.id === selectedId);

            if (!selectedNode) {
                return [];
            }

            nodes = selectedNode.children || [];

            while (nodes.length === 1 && nodes[0].type === 'info') {
                nodes = nodes[0].children || [];
            }
        }

        return nodes;
    }

    // =========================================================
    // INFO-KNAPP
    // =========================================================

    handleInfoClick(event) {
        /*
         * Sørger for at klikk på "i"
         * ikke også klikker på boksen.
         */

        event.stopPropagation();

        this.activeModal = event.currentTarget.dataset.modal;

        this.isModalOpen = true;
    }

    // =========================================================
    // LUKK MODAL
    // =========================================================

    closeModal() {
        this.isModalOpen = false;

        this.activeModal = null;
    }
}
