echo "Hei på deg. Oppretter scratch org for deg"
call sf org create scratch --definition-file config\project-scratch-def.json --alias %1 --duration-days %2 --set-default --json --wait 30

echo "Installerer crm-platform-base ver. 0.279"
call sf package install --package 04tQC000000uij7YAA --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-thread-view ver. 0.5"
call sf package install --package 04tKB000000Y8nqYAC --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-journal-utilities ver. 0.43"
call sf package install --package 04tKB000000Y9WtYAK --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-platform-reporting ver. 0.39"
call sf package install --package 04tKB000000Y5GEYA0 --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-shared-flowComponents ver. 0.4"
call sf package install --package 04t7U0000008qz4QAA --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-henvendelse-base ver. 0.36"
call sf package install --package 04tQC000000uSXtYAM --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-platform-integration ver. 0.158"
call sf package install --package 04tQC000000uiG5YAI --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-shared-user-notification ver. 0.25"
call sf package install --package 04tQC000000tKMHYA2 --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-platform-oppgave ver. 0.64"
call sf package install --package 04tKB000000YB09YAG --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-platform-access-control ver. 0.162"
call sf package install --package 04tQC000000tlPhYAI --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-community-base ver. 0.121"
call sf package install --package 04tQC000000ieEfYAI --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-henvendelse ver. 0.180"
call sf package install --package 04tQC000000uSCvYAM --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-shared-timeline ver. 1.29"
call sf package install --package 04tKB000000Y8znYAC --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Dytter kildekoden til scratch org'en"
call sf project deploy start

echo "Tildeler tilatelsessett til brukeren"
call sf org assign permset --name HOT_Servicetjenesten_Admin

echo "Creating testdata"
call sf apex run --file scripts/apex/createTestData.apex

echo "Ferdig"
