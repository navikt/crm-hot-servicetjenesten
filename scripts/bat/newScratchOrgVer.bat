@echo off
setlocal enabledelayedexpansion

REM Oppretter scratch org
sf org create scratch --definition-file config\project-scratch-def.json --alias %1 --duration-days %2 --set-default --json --wait 30 >nul 2>&1

set PACKAGES=(
    "crm-platform-base:0.254.0"
    "crm-platform-access-control:0.146.0"
    "crm-shared-flowComponents:0.4.0"
    "crm-henvendelse-base:0.31.0"
    "crm-platform-integration:0.147.0"
    "crm-platform-oppgave:0.63.0"
    "crm-community-base:0.119.0"
    "crm-platform-reporting:0.39.0"
    "crm-journal-utilities:0.40.0"
    "crm-shared-user-notification:0.24.0"
    "crm-henvendelse:0.154.0"
    "crm-thread-view:0.2.0"
    "crm-shared-timeline:1.27.0"
)

for %%P in (!PACKAGES!) do (
    set package=%%~P
    for /f "tokens=1 delims=:" %%A in ("!package!") do set packageName=%%A
    for /f "tokens=2 delims=:" %%B in ("!package!") do set ver=%%B

    REM Check for version pattern
    echo !ver! | findstr /R "[0-9]\{1,4\}\.[0-9]\{1,4\}\.[0-9]\{1,4\}\.[0-9]\{1,4\}" >nul
    if errorlevel 1 (
        set beta=""
    ) else (
        set beta=1
    )

    if "!beta!"=="" (
        for /f "tokens=*" %%C in ('sf package version list --packages "!packageName!" --released --concise ^| findstr "!ver!" ^| findstr "04t[a-zA-Z0-9]\{15\}"') do (
            set packageId=%%C
        )
    ) else (
        for /f "tokens=*" %%C in ('sf package version list --packages "!packageName!" ^| findstr "!ver!" ^| findstr "04t[a-zA-Z0-9]\{15\}"') do (
            set packageId=%%C
        )
    )

    if "!packageId!"=="" (
        echo can't find packageId for !packageName! !ver!
    ) else (
        echo Installing !packageName! !ver! !packageId!:
        sf package install --package !packageId! --no-prompt --installation-key %3 --wait 30 --publish-wait 30 >nul 2>&1
    )
)

REM Dytt kildekoden til scratch org'en
sf project deploy start >nul 2>&1

REM Tildeler permissionset
sf org assign permset --name HOT_Servicetjenesten_Admin >nul 2>&1

REM Opprett testdata
sf apex run --file scripts\apex\createTestData.apex >nul 2>&1

echo done
