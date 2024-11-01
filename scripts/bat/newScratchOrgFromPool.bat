echo "Hent scratch org fra pool"
call sfp pool:fetch --tag dev --targetdevhubusername %1 --alias %2 --setdefaultusername

echo "Dytter kildekoden til scratch org'en"
call sf project deploy start

echo "Tildeler tilatelsessett"
call sf org assign permset --name HOT_Servicetjenesten_Admin

echo "Oppretter testdata"
call sf apex run --file scripts/apex/createTestData.apex

echo "Ferdig"