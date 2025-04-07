# crm-hot-servicetjenesten

Denne pakken inneholder Salesforce metadata som støtter NAV Hjelpemidler og tilrettelegging sitt nasjonale service- og veiledningstjeneste. Løsningen utvikles av Team HoT CRM, som ble opprettet i Januar 2020 og ligger under DigiHot.

## Salesforce Features

Løsningen benytter seg av

-   Service Cloud

## Lenker

-   https://confluence.adeo.no/display/DigiHoT/Team+HoT+CRM
-   https://confluence.adeo.no/display/PTC/Plattform+Team+CRM

## Post scratch setup for Chat

Fordi noe av Salesforce sin metadata har dårlig support for pakkeløsningen og metadata deployment, så vil det være noen små steg å gjennomføre manuelt i Scratch for å teste Chat løsningen:

1. Opprett LiveChatButton
    - Gå til Setup -> Chat Buttons & Invitations. Opprett en ny Chat button med Omni-Channel routing connectet til Scratch Chat Queue.
2. Opprett en Embedded Service deployment og Config.
    - Gå til Setup -> Embedded Service Deployments og klikk på Deployment, velg Embedded Chat og deploy til Experience Cloud
    - Under chat setting, klikk start og lagre de prefylte verdiene.
3. Gå til Setup -> digitial experience -> all sites -> scratch_innboks og åpne Builder. Nederst i bodien på siden ligger en tom embedded service chat. Trykk på denne og oppdater den med ny verdi.
4. Mens du fortsatt er i Scratch_innboks builder, åpne settings -> Security and Privacy og sett på "Relaxed CSP" (om dette ikke alt er automatisk aktivert). Under CSP Errors seksjonen legger du til de to sidene som har blitt blokkert fra live agent endpoints (de som popper opp som error når du legger inn embedded service).
    - eksempel lenke 1: https://d.la1-c1cs-am3.salesforceliveagent.com/chat/rest/Visitor/Settings.jsonp
    - eksempel lenke 2: https://d.la1-c1cs-am3.salesforceliveagent.com/chat/rest/EmbeddedService/EmbeddedServiceConfig.jsonp
5. Dobbeltsjekk at Scratch Community profile er blitt opprettet på deploy. Dersom denne ikke er opprettet automatisk, opprett den manuelt eller oppdater .forceignore filen til å ikke ignorere profiles og deploy den spesifikke profilen på nytt.
    - User License: Customer Community Plus
6. Naviger ut av scratch_innboks Builder og inn til Workspace (Bruk ikonet i top venstre hjørne). Gå til Administration -> Members og legg til Customer Profile Scratch Community Profile og lagre.
7. Gå til Setup -> Permission Sets -> Scratch Permission -> Service Presence statuses, og assign de statusene som ligger der for chat.
8. Gi din egen bruker Scratch Permission
9. Kjør opprettelse av dummy data : eks "sf data import tree --plan 'C:\Dev\Repos\crm-hot-servicetjenesten\dummy-data\chat\plan.json'" (husk å bruke egen path)
10. Kjør denne kommandoen i terminal: npm run scratchSetup

Tips. For testing brukes "Harry Potter" accounten, og for å teste med denne accounten må man logge inn på experience cloud. Dersom knappen for "Log in to Experience as user" ikke alt er tilgjenglig på appen, legg den til på flexipagen.

Andre hjelpefulle commands i pakken:

#Activate api mock for all profiles
npm run activateMock
#Deactive mock for all profiles
npm run activateMock
