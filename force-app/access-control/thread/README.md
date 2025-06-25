# Servicetjenesten Thread ApexSharingRules

### Update 2025-06-23:

AccessHandler logic merged with NKS (https://github.com/navikt/crm-nks-base/tree/main/force-app/access-control/thread), to avoid _SOQL limit_ errors in some cases.

So now only SharingRules here.

#### Deprecated:

NKS AccessHandlers(https://github.com/navikt/crm-nks-base/tree/main/force-app/access-control/thread) cannot be used because of additional check on field - STO_Category\_\_c
Added adapted versions of AccessHandlers and triggers
