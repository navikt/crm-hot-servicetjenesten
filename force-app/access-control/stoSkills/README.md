# Servicetjenesten Skill sync scheduler

Scheduler updates Fortrolig og Skjermet skills for ServiceResource depending on AD groups.
It calls STO_GroupMemberSkillService class from crm-sto package( https://github.com/navikt/crm-sto/blob/main/force-app/main/default/classes/STO_GroupMemberSkillService.cls ) but with parameters related to Servicetjenesten:

-   'domain' => 'HOT'
-   'subdomain' => 'Servicetjenesten'
-   'permsetgroup' => 'HOT_Servicetjenesten_Gruppe'
-   'fortroliggroup' => 'group_AD_Fortrolig_Adresse'
-   'skjermedegroup' => 'Skjermede_Personer_AD'
-   'resourcetype' => 'T'

As STO_GroupMemberSkillService implements a Callable inteface, there is no need to have a dependency on crm-sto package
