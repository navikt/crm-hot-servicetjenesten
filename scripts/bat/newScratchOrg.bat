echo "Hei på deg. Oppretter scratch org for deg"
call sf org create scratch --definition-file config\project-scratch-def.json --alias %1 --duration-days %2 --set-default --json --wait 30

echo "Installerer crm-platform-base ver. 0.247"
call sf package install --package 04tKB000000Y6N2YAK --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-journal-utilities ver. 0.40"
call sf package install --package 04tKB000000Y65FYAS --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-platform-reporting ver. 0.39"
call sf package install --package 04tKB000000Y5GEYA0 --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-shared-flowComponents ver. 0.4"
call sf package install --package 04t7U0000008qz4QAA --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-henvendelse-base ver. 0.27"
call sf package install --package 04tKB000000Y77jYAC --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-platform-integration ver. 0.142"
call sf package install --package 04tKB000000Y6CWYA0 --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-sf-saf ver. 0.29"
call sf package install --package 04tKB000000Y7qsYAC --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-shared-user-notification ver. 0.24"
call sf package install --package 04t7U000000Y4jZQAS --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-platform-oppgave ver. 0.63"
call sf package install --package 04tKB000000Y5H7YAK --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-nks-integration ver. 0.78"
call sf package install --package 04tKB000000Y73CYAS --no-prompt --installation-key %3 --wait 30 --publish-wait 30


echo "Installerer crm-platform-access-control ver. 0.146"
call sf package install --package 04tKB000000Y7NBYA0 --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-community-base ver. 0.119"
call sf package install --package 04tKB000000Y0CZYA0 --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-henvendelse ver. 0.154"
call sf package install --package 04tKB000000Y5fXYAS --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-thread-view ver. 0.2"
call sf package install --package 04t7U000000TqvIQAS --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-shared-timeline ver. 1.27"
call sf package install --package 04tKB000000Y655YAC --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Dytter kildekoden til scratch org'en"
call sf project deploy start

echo "Tildeler tilatelsessett til brukeren"
call sf org assign permset --name HOT_Servicetjenesten_Admin

echo "Creating testdata"
call sf apex run --file scripts/apex/createTestData.apex

echo "Ferdig"
