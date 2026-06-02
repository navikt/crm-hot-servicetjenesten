#!/usr/bin/env bash

set -euo pipefail

# -----------------------------
# Defaults
# -----------------------------

ORG_ALIAS="${ORG_ALIAS:-crm-hot-servicetjenesten}"
DURATION_DAYS="${DURATION_DAYS:-7}"
SCRATCH_DEF_FILE="${SCRATCH_DEF_FILE:-config/project-scratch-def.json}"
PROJECT_FILE="${PROJECT_FILE:-sfdx-project.json}"
COMMUNITY_NAME="${COMMUNITY_NAME:-Aa-registret}"
DUMMY_DATA_PLAN="${DUMMY_DATA_PLAN:-dummy-data/plan.json}"
DUMMY_DATA_STEPS="${DUMMY_DATA_STEPS:-apex:scripts/apex/createTestData.apex,plan:dummy-data/sto/data/plan.json,plan:dummy-data/sto/plan.json,plan:dummy-data/conversation_notes/plan.json,apex:dummy-data/GenerateData.apex}"
PACKAGE_WAIT_MINUTES="${PACKAGE_WAIT_MINUTES:-10}"
PACKAGE_INSTALL_KEY="${PACKAGE_INSTALL_KEY:-}"

RUN_ORG_CREATE="${RUN_ORG_CREATE:-true}"
RUN_PACKAGES="${RUN_PACKAGES:-true}"
POST_STEPS="${POST_STEPS:-all}"
VERIFY_PACKAGE_VERSIONS="${VERIFY_PACKAGE_VERSIONS:-true}"
INSTALL_LATEST_PACKAGES="${INSTALL_LATEST_PACKAGES:-false}"
DELETE_ORG_ONLY="${DELETE_ORG_ONLY:-false}"
UPDATE_PACKAGES_ONLY="${UPDATE_PACKAGES_ONLY:-false}"

USE_POOL="${USE_POOL:-false}"
POOL_TAG="${POOL_TAG:-dev}"
POOL_DEVHUB_USERNAME="${POOL_DEVHUB_USERNAME:-}"
FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY="${FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY:-true}"
ORG_AVAILABLE_FOR_READ="${ORG_AVAILABLE_FOR_READ:-true}"

SELF_CHECK_ONLY="${SELF_CHECK_ONLY:-false}"
DRY_RUN="${DRY_RUN:-false}"
PACKAGE_PLAN_ONLY="${PACKAGE_PLAN_ONLY:-false}"

# Packages in this list do NOT use package install key.
# Packages NOT in this list WILL use package install key.
PACKAGES_NOT_REQUIRING_INSTALL_KEY="${PACKAGES_NOT_REQUIRING_INSTALL_KEY:-platform-data-model,custom-metadata-dao,custom-permission-helper,feature-toggle}"

PACKAGE_UPDATE_SUGGESTIONS=""
INSTALLED_PACKAGES_JSON=""

RUN_STARTED_AT="$(date '+%Y-%m-%d %H:%M:%S %Z')"
RUN_STARTED_SECONDS="$SECONDS"
SUMMARY_PRINTED=false
SUMMARY_ENABLED=true

RUN_ACTIONS=()
PACKAGES_INSTALLED=()
PACKAGES_UPDATED=()
PACKAGES_SKIPPED=()
PACKAGES_MISSING=()
PACKAGES_HIGHER_THAN_TARGET=()
POST_STEPS_RUN=()
POST_STEPS_SKIPPED=()
ORG_ACTION="No org action recorded."
DATA_STEPS=()

# -----------------------------
# Colors
# -----------------------------

if [[ -t 1 ]]; then
    YELLOW=$'\033[33m'
    GREEN=$'\033[32m'
    RED=$'\033[31m'
    RESET=$'\033[0m'
else
    YELLOW=""
    GREEN=""
    RED=""
    RESET=""
fi

# -----------------------------
# Common helpers
# -----------------------------

error() {
    local exit_code="${1:-1}"
    local message="${2:-Installation failed.}"

    echo ""
    echo "${RED}$message${RESET}"
    echo ""
    echo "${RED}Installation failed.${RESET}"
    echo ""

    exit "$exit_code"
}

warning() {
    echo "${YELLOW}WARNING: $1${RESET}"
}

add_action() { RUN_ACTIONS+=("$1"); }
add_package_installed() { PACKAGES_INSTALLED+=("$1"); }
add_package_updated() { PACKAGES_UPDATED+=("$1"); }
add_package_skipped() { PACKAGES_SKIPPED+=("$1"); }
add_package_missing() { PACKAGES_MISSING+=("$1"); }
add_package_higher_than_target() { PACKAGES_HIGHER_THAN_TARGET+=("$1"); }
add_post_step_run() { POST_STEPS_RUN+=("$1"); }
add_post_step_skipped() { POST_STEPS_SKIPPED+=("$1"); }

format_duration() {
    local total_seconds="$1"
    local hours=$((total_seconds / 3600))
    local minutes=$(((total_seconds % 3600) / 60))
    local seconds=$((total_seconds % 60))

    printf "%02dh %02dm %02ds" "$hours" "$minutes" "$seconds"
}

print_array_items() {
    local title="$1"
    shift

    if [[ "$#" -eq 0 ]]; then
        return 0
    fi

    echo ""
    echo "$title"
    printf -- "- %s\n" "$@"
}

print_run_summary() {
    local exit_code="${1:-0}"

    if [[ "$SUMMARY_ENABLED" != "true" ]]; then
        return 0
    fi

    if [[ "$SUMMARY_PRINTED" == "true" ]]; then
        return 0
    fi

    SUMMARY_PRINTED=true

    local ended_at=""
    local elapsed_seconds=""
    local duration=""
    local status=""
    local installed_label="Installed"
    local updated_label="Updated"

    ended_at="$(date '+%Y-%m-%d %H:%M:%S %Z')"
    elapsed_seconds=$((SECONDS - RUN_STARTED_SECONDS))
    duration="$(format_duration "$elapsed_seconds")"

    if [[ "$exit_code" -eq 0 ]]; then
        status="${GREEN}SUCCESS${RESET}"
    else
        status="${RED}FAILED${RESET} exit code $exit_code"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        installed_label="Would install"
        updated_label="Would update"
    fi

    echo ""
    echo "============================================================"
    echo "Run summary"
    echo "============================================================"
    echo "Status:        $status"
    echo "Started:       $RUN_STARTED_AT"
    echo "Ended:         $ended_at"
    echo "Duration:      $duration"
    echo ""
    echo "Mode:"
    echo "- Org alias:              $ORG_ALIAS"
    echo "- Use pool:               $USE_POOL"
    echo "- Install latest:         $INSTALL_LATEST_PACKAGES"
    echo "- Update packages only:   $UPDATE_PACKAGES_ONLY"
    echo "- Delete org only:        $DELETE_ORG_ONLY"
    echo "- Self-check only:        $SELF_CHECK_ONLY"
    echo "- Dry-run:                $DRY_RUN"
    echo "- Package plan only:      $PACKAGE_PLAN_ONLY"
    echo "- Post steps:             $POST_STEPS"
    echo ""
    echo "Org:"
    echo "- $ORG_ACTION"
    echo ""
    echo "Packages:"
    echo "- Missing before install:     ${#PACKAGES_MISSING[@]}"
    echo "- $installed_label:                  ${#PACKAGES_INSTALLED[@]}"
    echo "- $updated_label:                    ${#PACKAGES_UPDATED[@]}"
    echo "- Skipped, already correct:   ${#PACKAGES_SKIPPED[@]}"
    echo "- Higher than target:         ${#PACKAGES_HIGHER_THAN_TARGET[@]}"

    print_array_items "Packages missing before install:" "${PACKAGES_MISSING[@]}"
    print_array_items "Packages installed:" "${PACKAGES_INSTALLED[@]}"
    print_array_items "Packages updated:" "${PACKAGES_UPDATED[@]}"
    print_array_items "Packages skipped:" "${PACKAGES_SKIPPED[@]}"
    print_array_items "Packages higher than target:" "${PACKAGES_HIGHER_THAN_TARGET[@]}"

    echo ""
    echo "Post steps:"
    if [[ "${#POST_STEPS_RUN[@]}" -eq 0 ]]; then
        echo "- Ran:     none"
    else
        echo "- Ran:     ${POST_STEPS_RUN[*]}"
    fi

    if [[ "${#POST_STEPS_SKIPPED[@]}" -eq 0 ]]; then
        echo "- Skipped: none"
    else
        echo "- Skipped: ${POST_STEPS_SKIPPED[*]}"
    fi

    print_array_items "Actions:" "${RUN_ACTIONS[@]}"

    echo "============================================================"
    echo ""
}

on_exit() {
    local exit_code=$?
    set +e
    print_run_summary "$exit_code"
}

trap on_exit EXIT

format_command() {
    printf '%q ' "$@"
    echo ""
}

run_cmd() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "${YELLOW}[dry-run] Would run:${RESET} $(format_command "$@")"
        return 0
    fi

    "$@"
}

usage() {
    cat <<'EOF_USAGE'
Usage:
  ./create-scratch-org.sh [options]

Options:
  -a, --alias <alias>                 Scratch org alias. Default: crm-hot-servicetjenesten
  -d, --duration-days <days>          Scratch org duration in days. Default: 14
  -f, --definition-file <file>        Scratch org definition file. Default: config/project-scratch-def.json
  -p, --project-file <file>           Salesforce DX project file. Default: sfdx-project.json
  --dummy-data-plan <file>            Dummy data import plan. Default: dummy-data/plan.json
    --dummy-data-steps <steps>          Ordered data steps. Comma-separated list of:
                                                                            plan:<file> or apex:<file>
                                                                            Example:
                                                                            apex:scripts/apex/createTestData.apex,plan:dummy-data/sto/data/plan.json

  -s, --post-steps <steps>            Post steps to run. Default: all
                                      Values: all, none, deploy, permsets, data, community
                                      Multiple values can be comma-separated: deploy,permsets,data,community

  --install-latest                    Install latest released package versions instead of versions defined in sfdx-project.json.
  --update-packages                   Only install package dependencies that are missing or behind.
  --use-pool                          Try to fetch a scratch org from the sfp scratch org pool.
  --pool-tag <tag>                    sfp pool tag. Default: dev
  --pool-devhub <alias>               DevHub username or alias for sfp pool commands.
                                      If omitted, script tries: sf config get target-dev-hub --json
  --delete-org-only                   Only delete the scratch org matching --alias.
  --self-check                        Validate setup and configuration only.
  --dry-run                           Print mutating commands instead of executing them.
  --package-plan                      Check installed packages and print what would change.
  --skip-org                          Do not delete/create/fetch scratch org.
  --skip-packages                     Do not install packages.
  --skip-version-check                Do not warn when dependency versions are not latest released versions.
  -h, --help                          Show this help text.

Environment variables:
  PACKAGE_INSTALL_KEY                 Installation key used for packages requiring key.
  PACKAGES_NOT_REQUIRING_INSTALL_KEY  Comma-separated list of packages that do NOT require install key.

Examples:
  ./create-scratch-org.sh
  ./create-scratch-org.sh --self-check
  ./create-scratch-org.sh --dry-run
  ./create-scratch-org.sh --package-plan
  ./create-scratch-org.sh --package-plan --install-latest
  ./create-scratch-org.sh --use-pool --pool-tag dev --pool-devhub "NAV DevHub"
  ./create-scratch-org.sh --update-packages --install-latest
  ./create-scratch-org.sh --delete-org-only
  ./create-scratch-org.sh --skip-org --skip-packages --post-steps deploy
EOF_USAGE
}

require_option_value() {
    local option_name="$1"
    local option_value="${2:-}"

    if [[ -z "$option_value" || "$option_value" == -* ]]; then
        error 1 "Missing value for option: $option_name"
    fi
}

validate_number() {
    local value="$1"
    local name="$2"

    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        error 1 "$name must be a number. Got: $value"
    fi
}

validate_boolean() {
    local value="$1"
    local name="$2"

    case "$value" in
        true|false) ;;
        *) error 1 "$name must be either true or false. Got: $value" ;;
    esac
}

require_command() {
    local command_name="$1"

    if ! command -v "$command_name" >/dev/null 2>&1; then
        error 1 "Required command not found: $command_name"
    fi
}

validate_file_exists() {
    local file_path="$1"
    local name="$2"

    if [[ ! -f "$file_path" ]]; then
        error 1 "$name not found: $file_path"
    fi
}

validate_json_file() {
    local file_path="$1"

    if ! jq empty "$file_path" >/dev/null 2>&1; then
        error 1 "Invalid JSON file: $file_path"
    fi
}

validate_post_steps() {
    POST_STEPS="${POST_STEPS// /}"

    if [[ "$POST_STEPS" == "all" || "$POST_STEPS" == "none" ]]; then
        return 0
    fi

    IFS=',' read -ra selected_steps <<< "$POST_STEPS"

    for step in "${selected_steps[@]}"; do
        case "$step" in
            deploy|permsets|data|community) ;;
            *) error 1 "Invalid post step: $step. Valid values are: all, none, deploy, permsets, data, community" ;;
        esac
    done
}

parse_data_steps() {
    DATA_STEPS=()

    local normalized_steps="${DUMMY_DATA_STEPS// /}"

    if [[ -z "$normalized_steps" ]]; then
        return 0
    fi

    IFS=',' read -ra DATA_STEPS <<< "$normalized_steps"
}

validate_data_steps() {
    parse_data_steps

    if [[ "${#DATA_STEPS[@]}" -eq 0 ]]; then
        return 0
    fi

    local step=""

    for step in "${DATA_STEPS[@]}"; do
        [[ -z "$step" ]] && continue

        local step_type="${step%%:*}"
        local step_path="${step#*:}"

        if [[ "$step_type" != "plan" && "$step_type" != "apex" ]]; then
            error 1 "Invalid data step type in $step. Use plan:<file> or apex:<file>."
        fi

        if [[ -z "$step_path" || "$step_path" == "$step_type" ]]; then
            error 1 "Invalid data step path in $step."
        fi

        validate_file_exists "$step_path" "Data step file"
    done
}

should_run_post_step() {
    local step="$1"

    if [[ "$POST_STEPS" == "all" ]]; then
        return 0
    fi

    if [[ "$POST_STEPS" == "none" ]]; then
        return 1
    fi

    if [[ ",$POST_STEPS," == *",$step,"* ]]; then
        return 0
    fi

    return 1
}

needs_project_file() {
    if [[ "$RUN_PACKAGES" == "true" || "$UPDATE_PACKAGES_ONLY" == "true" || "$PACKAGE_PLAN_ONLY" == "true" || "$SELF_CHECK_ONLY" == "true" ]]; then
        return 0
    fi

    return 1
}

read_dependencies() {
    jq -r '
        .packageDirectories[]?
        | select(.dependencies != null)
        | .dependencies[]?
        | [.package, .versionNumber]
        | @tsv
    ' "$PROJECT_FILE"
}

dependency_count() {
    jq -r '
        [
            .packageDirectories[]?
            | select(.dependencies != null)
            | .dependencies[]?
        ]
        | length
    ' "$PROJECT_FILE"
}

package_requires_key() {
    local package_name="$1"
    local normalized_no_key_packages=",${PACKAGES_NOT_REQUIRING_INSTALL_KEY// /},"

    if [[ "$normalized_no_key_packages" == *",$package_name,"* ]]; then
        return 1
    fi

    return 0
}

check_if_package_install_key_is_required() {
    local install_key_required=false

    if [[ "$DRY_RUN" == "true" || "$SELF_CHECK_ONLY" == "true" || "$PACKAGE_PLAN_ONLY" == "true" ]]; then
        return 0
    fi

    if [[ "$RUN_PACKAGES" != "true" && "$UPDATE_PACKAGES_ONLY" != "true" ]]; then
        return 0
    fi

    while IFS=$'\t' read -r package_name requested_version; do
        [[ -z "$package_name" ]] && continue

        if package_requires_key "$package_name"; then
            install_key_required=true
            break
        fi
    done < <(read_dependencies)

    if [[ "$install_key_required" == "true" && -z "$PACKAGE_INSTALL_KEY" ]]; then
        echo ""
        read -rsp "Package install key: " PACKAGE_INSTALL_KEY
        echo ""

        if [[ -z "$PACKAGE_INSTALL_KEY" ]]; then
            error 1 "Package install key is required because one or more packages require it."
        fi
    fi
}

resolve_pool_devhub_username() {
    if [[ -n "$POOL_DEVHUB_USERNAME" ]]; then
        echo "$POOL_DEVHUB_USERNAME"
        return 0
    fi

    local resolved_devhub=""

    resolved_devhub="$(
        sf config get target-dev-hub --json 2>/dev/null \
            | jq -r '.result[]? | select(.name == "target-dev-hub") | .value // empty' \
            | head -n 1
    )"

    if [[ -z "$resolved_devhub" || "$resolved_devhub" == "null" ]]; then
        error 1 "sfp requires --targetdevhubusername, but no --pool-devhub was provided and no sf target-dev-hub config was found. Run either: sf config set target-dev-hub \"NAV DevHub\" or use: --pool-devhub \"NAV DevHub\""
    fi

    echo "$resolved_devhub"
}

get_pool_list_output() {
    local resolved_devhub=""
    resolved_devhub="$(resolve_pool_devhub_username)"

    sfp pool list \
        --tag "$POOL_TAG" \
        -a \
        --targetdevhubusername "$resolved_devhub"
}

unused_pool_org_count() {
    local pool_output="$1"

    echo "$pool_output" \
        | sed -nE 's/.*Unused Scratch Orgs in the Pool[[:space:]]*:[[:space:]]*([0-9]+).*/\1/p' \
        | tail -n 1
}

fetch_scratch_org_from_pool() {
    local resolved_devhub=""
    resolved_devhub="$(resolve_pool_devhub_username)"

    echo ""
    echo "Fetching scratch org from sfp pool..."
    echo "Pool tag: $POOL_TAG"
    echo "DevHub:   $resolved_devhub"
    echo "Alias:    $ORG_ALIAS"

    run_cmd sfp pool fetch \
        --tag "$POOL_TAG" \
        --targetdevhubusername "$resolved_devhub" \
        --alias "$ORG_ALIAS" \
        --setdefaultusername \
        || error $? "Failed to fetch scratch org from sfp pool."

    if [[ "$DRY_RUN" == "true" ]]; then
        ORG_AVAILABLE_FOR_READ=false
        ORG_ACTION="Dry-run: would fetch scratch org from pool: tag=$POOL_TAG alias=$ORG_ALIAS"
        add_action "Dry-run: would fetch scratch org from pool with tag $POOL_TAG as alias $ORG_ALIAS"
    else
        ORG_AVAILABLE_FOR_READ=true
        ORG_ACTION="Fetched scratch org from pool: tag=$POOL_TAG alias=$ORG_ALIAS"
        add_action "Fetched scratch org from pool with tag $POOL_TAG as alias $ORG_ALIAS"
    fi
}

try_fetch_scratch_org_from_pool() {
    local pool_output=""
    local unused_count=""

    echo ""
    echo "Checking sfp scratch org pool..."
    echo "Pool tag: $POOL_TAG"

    pool_output="$(get_pool_list_output)" || error $? "Failed to list sfp scratch org pool."
    echo "$pool_output"

    unused_count="$(unused_pool_org_count "$pool_output")"

    if [[ -z "$unused_count" ]]; then
        warning "Could not parse unused scratch org count from sfp pool list output."

        if [[ "$FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY" == "true" ]]; then
            echo "Falling back to normal scratch org creation."
            return 1
        fi

        error 1 "Could not determine whether the scratch org pool has available orgs."
    fi

    if [[ "$unused_count" -gt 0 ]]; then
        echo ""
        echo "${GREEN}Unused scratch orgs available in pool: $unused_count${RESET}"
        fetch_scratch_org_from_pool
        return 0
    fi

    warning "No unused scratch orgs available in pool."

    if [[ "$FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY" == "true" ]]; then
        echo "Falling back to normal scratch org creation."
        return 1
    fi

    error 1 "No unused scratch orgs available in pool."
}

get_package_versions_json() {
    local package_name="$1"

    sf package version list \
        --released \
        --order-by CreatedDate \
        --json \
        --packages "$package_name"
}

latest_version_json() {
    local versions_json="$1"

    echo "$versions_json" | jq -c '
        .result
        | map(select(.SubscriberPackageVersionId != null))
        | sort_by(
            (.MajorVersion // 0),
            (.MinorVersion // 0),
            (.PatchVersion // 0),
            (.BuildNumber // 0),
            (.CreatedDate // "")
        )
        | last // empty
    '
}

requested_version_json() {
    local versions_json="$1"
    local requested_version="$2"

    echo "$versions_json" | jq -c --arg requested "$requested_version" '
        def released_versions:
            .result
            | map(select(.SubscriberPackageVersionId != null));

        def sort_versions:
            sort_by(
                (.MajorVersion // 0),
                (.MinorVersion // 0),
                (.PatchVersion // 0),
                (.BuildNumber // 0),
                (.CreatedDate // "")
            );

        ($requested | split(".")) as $parts
        | if ($requested == "" or $requested == "LATEST") then
            released_versions
            | sort_versions
            | last // empty
          elif (($parts | length) >= 3) then
            ($parts[0] | tonumber?) as $major
            | ($parts[1] | tonumber?) as $minor
            | ($parts[2] | tonumber?) as $patch
            | (
                released_versions
                | map(
                    select(
                        ((.MajorVersion // -1) == $major)
                        and ((.MinorVersion // -1) == $minor)
                        and ((.PatchVersion // -1) == $patch)
                        and (
                            (($parts | length) < 4)
                            or ($parts[3] == "LATEST")
                            or (($parts[3] | tonumber?) == null)
                            or ((.BuildNumber // -1) == ($parts[3] | tonumber?))
                        )
                    )
                )
                | sort_versions
                | last // empty
              )
          else
            released_versions
            | sort_versions
            | last // empty
          end
    '
}

version_label_from_json() {
    local version_json="$1"

    echo "$version_json" | jq -r '
        if . == null or . == "" then
            "unknown"
        elif .MajorVersion != null then
            "\(.MajorVersion).\(.MinorVersion).\(.PatchVersion).\(.BuildNumber // "unknown")"
        else
            .Version // .VersionNumber // .Name // "unknown"
        end
    '
}

base_version_from_json() {
    local version_json="$1"

    echo "$version_json" | jq -r '
        if . == null or . == "" then
            "unknown"
        elif .MajorVersion != null then
            "\(.MajorVersion).\(.MinorVersion).\(.PatchVersion)"
        else
            (.Version // .VersionNumber // .Name // "unknown")
            | split(".")
            | .[0:3]
            | join(".")
        end
    '
}

base_version_from_requested() {
    local requested_version="$1"

    requested_version="${requested_version%.LATEST}"
    requested_version="${requested_version%.NEXT}"

    IFS='.' read -r major minor patch rest <<< "$requested_version"

    if [[ -z "${major:-}" || -z "${minor:-}" || -z "${patch:-}" ]]; then
        echo "unknown"
        return 0
    fi

    echo "$major.$minor.$patch"
}

subscriber_package_version_id_from_json() {
    local version_json="$1"

    echo "$version_json" | jq -r '.SubscriberPackageVersionId // empty'
}

suggested_version_number_from_latest() {
    echo "$RESOLVED_LATEST_BASE_VERSION.LATEST"
}

RESOLVED_SUBSCRIBER_PACKAGE_VERSION_ID=""
RESOLVED_SELECTED_VERSION=""
RESOLVED_SELECTED_BASE_VERSION=""
RESOLVED_LATEST_VERSION=""
RESOLVED_LATEST_BASE_VERSION=""
RESOLVED_LATEST_SUBSCRIBER_PACKAGE_VERSION_ID=""

resolve_package_version() {
    local package_name="$1"
    local requested_version="$2"

    local versions_json=""
    local selected_json=""
    local latest_json=""

    echo ""
    echo "Resolving package version for $package_name from $PROJECT_FILE..."
    echo "Requested version in project file: $requested_version"

    versions_json="$(get_package_versions_json "$package_name")" \
        || error $? "Failed to list package versions for $package_name"

    latest_json="$(latest_version_json "$versions_json")"

    if [[ -z "$latest_json" || "$latest_json" == "null" ]]; then
        error 1 "Could not resolve latest released version for package $package_name"
    fi

    if [[ "$INSTALL_LATEST_PACKAGES" == "true" ]]; then
        selected_json="$latest_json"
    else
        selected_json="$(requested_version_json "$versions_json" "$requested_version")"
    fi

    if [[ -z "$selected_json" || "$selected_json" == "null" ]]; then
        error 1 "Could not resolve requested version $requested_version for package $package_name"
    fi

    RESOLVED_SUBSCRIBER_PACKAGE_VERSION_ID="$(subscriber_package_version_id_from_json "$selected_json")"
    RESOLVED_SELECTED_VERSION="$(version_label_from_json "$selected_json")"
    RESOLVED_SELECTED_BASE_VERSION="$(base_version_from_json "$selected_json")"

    RESOLVED_LATEST_VERSION="$(version_label_from_json "$latest_json")"
    RESOLVED_LATEST_BASE_VERSION="$(base_version_from_json "$latest_json")"
    RESOLVED_LATEST_SUBSCRIBER_PACKAGE_VERSION_ID="$(subscriber_package_version_id_from_json "$latest_json")"

    if [[ -z "$RESOLVED_SUBSCRIBER_PACKAGE_VERSION_ID" ]]; then
        error 1 "Could not find SubscriberPackageVersionId for $package_name $requested_version"
    fi
}

warn_if_dependency_is_not_latest() {
    local package_name="$1"
    local requested_version="$2"

    if [[ "$VERIFY_PACKAGE_VERSIONS" != "true" ]]; then
        return 0
    fi

    local requested_base_version=""
    local suggested_version_number=""

    requested_base_version="$(base_version_from_requested "$requested_version")"
    suggested_version_number="$(suggested_version_number_from_latest)"

    if [[ "$requested_base_version" != "$RESOLVED_LATEST_BASE_VERSION" ]]; then
        warning "$package_name is not using the latest released version in $PROJECT_FILE. Defined: $requested_version. Latest released: $RESOLVED_LATEST_VERSION. Latest 04t: $RESOLVED_LATEST_SUBSCRIBER_PACKAGE_VERSION_ID. Suggested versionNumber: $suggested_version_number"

        PACKAGE_UPDATE_SUGGESTIONS+="$package_name|$requested_version|$suggested_version_number|$RESOLVED_LATEST_VERSION|$RESOLVED_LATEST_SUBSCRIBER_PACKAGE_VERSION_ID"$'\n'
    fi
}

print_package_update_suggestions() {
    if [[ "$VERIFY_PACKAGE_VERSIONS" != "true" ]]; then
        return 0
    fi

    if [[ -z "$PACKAGE_UPDATE_SUGGESTIONS" ]]; then
        echo ""
        echo "${GREEN}All dependency versions in $PROJECT_FILE look up to date.${RESET}"
        return 0
    fi

    echo ""
    echo "${YELLOW}Suggested dependency updates for $PROJECT_FILE:${RESET}"
    echo ""

    while IFS='|' read -r package_name current_version suggested_version latest_version latest_04t; do
        [[ -z "$package_name" ]] && continue

        echo "${YELLOW}$package_name${RESET}"
        echo "  Current versionNumber:   $current_version"
        echo "  Suggested versionNumber: $suggested_version"
        echo "  Latest resolved version: $latest_version"
        echo "  Latest 04t:              $latest_04t"
        echo ""
    done <<< "$PACKAGE_UPDATE_SUGGESTIONS"

    echo "${YELLOW}Dependency entries you can copy into $PROJECT_FILE:${RESET}"
    echo ""

    while IFS='|' read -r package_name current_version suggested_version latest_version latest_04t; do
        [[ -z "$package_name" ]] && continue

        cat <<EOF_JSON
{
    "package": "$package_name",
    "versionNumber": "$suggested_version"
},
EOF_JSON
    done <<< "$PACKAGE_UPDATE_SUGGESTIONS"

    echo ""
    echo "Copy the suggested versionNumber values into the matching dependency entries in $PROJECT_FILE."
}

get_installed_packages_json() {
    sf package installed list \
        --target-org "$ORG_ALIAS" \
        --json
}

load_installed_packages() {
    echo ""
    echo "Reading installed packages from org: $ORG_ALIAS"

    if [[ "$ORG_AVAILABLE_FOR_READ" != "true" ]]; then
        warning "Org was not actually created or fetched in this run. Assuming no installed packages for planning."
        INSTALLED_PACKAGES_JSON='{"result":[]}'
        return 0
    fi

    INSTALLED_PACKAGES_JSON="$(get_installed_packages_json)" \
        || error $? "Failed to read installed packages from org: $ORG_ALIAS"
}

installed_package_json() {
    local package_name="$1"

    echo "$INSTALLED_PACKAGES_JSON" | jq -c --arg package_name "$package_name" '
        (.result // [])
        | map(
            select(
                (
                    .SubscriberPackageName
                    // .PackageName
                    // .Name
                    // .Package
                    // ""
                ) == $package_name
            )
        )
        | first // empty
    '
}

installed_package_version() {
    local installed_json="$1"

    echo "$installed_json" | jq -r '
        .SubscriberPackageVersionNumber
        // .VersionNumber
        // .Version
        // "unknown"
    '
}

installed_package_04t() {
    local installed_json="$1"

    echo "$installed_json" | jq -r '
        .SubscriberPackageVersionId
        // .SubscriberPackageVersionID
        // empty
    '
}

normalize_version() {
    local version="$1"

    version="${version%.LATEST}"
    version="${version%.NEXT}"
    version="$(echo "$version" | sed -E 's/[^0-9.].*$//')"

    IFS='.' read -r major minor patch build rest <<< "$version"

    major="${major:-0}"
    minor="${minor:-0}"
    patch="${patch:-0}"
    build="${build:-0}"

    echo "$major.$minor.$patch.$build"
}

compare_versions() {
    local left=""
    local right=""

    left="$(normalize_version "$1")"
    right="$(normalize_version "$2")"

    IFS='.' read -r left_major left_minor left_patch left_build <<< "$left"
    IFS='.' read -r right_major right_minor right_patch right_build <<< "$right"

    local left_parts=("$left_major" "$left_minor" "$left_patch" "$left_build")
    local right_parts=("$right_major" "$right_minor" "$right_patch" "$right_build")

    for i in 0 1 2 3; do
        if (( 10#${left_parts[$i]} < 10#${right_parts[$i]} )); then
            echo "-1"
            return 0
        fi

        if (( 10#${left_parts[$i]} > 10#${right_parts[$i]} )); then
            echo "1"
            return 0
        fi
    done

    echo "0"
}

install_resolved_package() {
    local package_name="$1"

    local install_args=(
        package install
        -r
        -w "$PACKAGE_WAIT_MINUTES"
        -p "$RESOLVED_SUBSCRIBER_PACKAGE_VERSION_ID"
        --target-org "$ORG_ALIAS"
    )

    if package_requires_key "$package_name"; then
        if [[ "$DRY_RUN" == "true" ]]; then
            install_args+=(-k "***")
        else
            install_args+=(-k "$PACKAGE_INSTALL_KEY")
        fi
    fi

    run_cmd sf "${install_args[@]}" \
        || error $? "Failed to install package $package_name with ID $RESOLVED_SUBSCRIBER_PACKAGE_VERSION_ID"
}

delete_existing_scratch_org() {
    echo ""
    echo "Deleting existing scratch org, if it exists: $ORG_ALIAS"

    if [[ "$DRY_RUN" == "true" ]]; then
        run_cmd sf org delete scratch \
            --no-prompt \
            --target-org "$ORG_ALIAS"

        ORG_ACTION="Dry-run: would delete scratch org if it existed: $ORG_ALIAS"
        add_action "Dry-run: would delete scratch org if it existed: $ORG_ALIAS"
    else
        sf org delete scratch \
            --no-prompt \
            --target-org "$ORG_ALIAS" \
            > /dev/null 2>&1 || true

        ORG_ACTION="Attempted to delete scratch org: $ORG_ALIAS"
        add_action "Deleted scratch org if it existed: $ORG_ALIAS"
    fi
}

create_scratch_org() {
    echo ""
    echo "Creating scratch org: $ORG_ALIAS"

    run_cmd sf org create scratch \
        --set-default \
        --definition-file "$SCRATCH_DEF_FILE" \
        --duration-days "$DURATION_DAYS" \
        --alias "$ORG_ALIAS" \
        || error $? '"sf org create scratch" command failed.'

    if [[ "$DRY_RUN" == "true" ]]; then
        ORG_AVAILABLE_FOR_READ=false
        ORG_ACTION="Dry-run: would create scratch org: $ORG_ALIAS"
        add_action "Dry-run: would create scratch org $ORG_ALIAS with duration $DURATION_DAYS days"
    else
        ORG_AVAILABLE_FOR_READ=true
        ORG_ACTION="Created scratch org: $ORG_ALIAS"
        add_action "Created scratch org $ORG_ALIAS with duration $DURATION_DAYS days"
    fi
}

setup_org() {
    if [[ "$RUN_ORG_CREATE" != "true" ]]; then
        echo ""
        echo "Skipping scratch org delete/create/fetch."
        return 0
    fi

    if [[ "$USE_POOL" == "true" ]]; then
        if try_fetch_scratch_org_from_pool; then
            echo ""
            echo "${GREEN}Using scratch org fetched from pool.${RESET}"
            return 0
        fi
    fi

    delete_existing_scratch_org
    create_scratch_org
}

install_packages() {
    local count=""
    count="$(dependency_count)"

    if [[ "$count" -eq 0 ]]; then
        error 1 "No package dependencies found in $PROJECT_FILE"
    fi

    echo ""
    echo "Installing package dependencies from $PROJECT_FILE..."

    if [[ "$INSTALL_LATEST_PACKAGES" == "true" ]]; then
        echo "Install mode: latest released package versions"
    else
        echo "Install mode: versions defined in $PROJECT_FILE"
    fi

    while IFS=$'\t' read -r package_name requested_version; do
        [[ -z "$package_name" ]] && continue

        resolve_package_version "$package_name" "$requested_version"
        warn_if_dependency_is_not_latest "$package_name" "$requested_version"

        echo ""
        echo "Installing $package_name"
        echo "Defined version:  $requested_version"
        echo "Resolved version: $RESOLVED_SELECTED_VERSION"
        echo "Package ID:       $RESOLVED_SUBSCRIBER_PACKAGE_VERSION_ID"

        install_resolved_package "$package_name"
        add_package_installed "$package_name $RESOLVED_SELECTED_VERSION"

    done < <(read_dependencies)
}

update_packages() {
    local count=""
    count="$(dependency_count)"

    if [[ "$count" -eq 0 ]]; then
        error 1 "No package dependencies found in $PROJECT_FILE"
    fi

    echo ""
    echo "Checking and updating package dependencies from $PROJECT_FILE..."

    if [[ "$INSTALL_LATEST_PACKAGES" == "true" ]]; then
        echo "Update mode: latest released package versions"
    else
        echo "Update mode: versions defined in $PROJECT_FILE"
    fi

    load_installed_packages

    while IFS=$'\t' read -r package_name requested_version; do
        [[ -z "$package_name" ]] && continue

        resolve_package_version "$package_name" "$requested_version"
        warn_if_dependency_is_not_latest "$package_name" "$requested_version"

        local installed_json=""
        local installed_version=""
        local installed_04t=""
        local comparison=""

        installed_json="$(installed_package_json "$package_name")"

        echo ""
        echo "Checking $package_name"
        echo "Defined version:   $requested_version"
        echo "Target version:    $RESOLVED_SELECTED_VERSION"
        echo "Target 04t:        $RESOLVED_SUBSCRIBER_PACKAGE_VERSION_ID"

        if [[ -z "$installed_json" || "$installed_json" == "null" ]]; then
            echo "${YELLOW}Package is not installed. Installing target version.${RESET}"
            add_package_missing "$package_name target=$RESOLVED_SELECTED_VERSION"
            install_resolved_package "$package_name"
            add_package_installed "$package_name $RESOLVED_SELECTED_VERSION"
            continue
        fi

        installed_version="$(installed_package_version "$installed_json")"
        installed_04t="$(installed_package_04t "$installed_json")"

        echo "Installed version: $installed_version"
        echo "Installed 04t:     ${installed_04t:-unknown}"

        comparison="$(compare_versions "$installed_version" "$RESOLVED_SELECTED_VERSION")"

        if [[ "$comparison" == "-1" ]]; then
            echo "${YELLOW}Installed version is lower than target version. Installing update.${RESET}"
            install_resolved_package "$package_name"
            add_package_updated "$package_name $installed_version -> $RESOLVED_SELECTED_VERSION"
        elif [[ "$comparison" == "0" ]]; then
            echo "${GREEN}Package is already on target version. Skipping.${RESET}"
            add_package_skipped "$package_name $installed_version"
        else
            warning "$package_name has a higher version installed than the target version. Installed: $installed_version. Target: $RESOLVED_SELECTED_VERSION. Skipping downgrade."
            add_package_higher_than_target "$package_name installed=$installed_version target=$RESOLVED_SELECTED_VERSION"
        fi

    done < <(read_dependencies)
}

deploy_metadata() {
    echo ""
    echo "Deploying metadata..."

    run_cmd sf project deploy start \
        --target-org "$ORG_ALIAS" \
        || error $? '"sf project deploy start" command failed.'

    add_action "Deployed metadata to $ORG_ALIAS"
}

assign_permission_sets() {
    echo ""
    echo "Assigning permission sets..."

    run_cmd sf org assign permset \
        --target-org "$ORG_ALIAS" \
        --name HOT_Servicetjenesten_Admin \
        || error $? '"sf org assign permset" command failed.'

    add_action "Assigned permission sets in $ORG_ALIAS"
}

import_dummy_data() {
    echo ""
    echo "Running data steps..."

    parse_data_steps

    if [[ "${#DATA_STEPS[@]}" -eq 0 ]]; then
        echo "No data steps configured. Skipping."
        add_action "Skipped data steps because no steps were configured"
        return 0
    fi

    local step=""

    for step in "${DATA_STEPS[@]}"; do
        [[ -z "$step" ]] && continue

        local step_type="${step%%:*}"
        local step_path="${step#*:}"

        if [[ "$step_type" == "apex" ]]; then
            echo "Executing Apex script: $step_path"
            run_cmd sf apex run \
                --target-org "$ORG_ALIAS" \
                --file "$step_path" \
                || error $? "\"sf apex run\" command failed for script: \"$step_path\"."

            add_action "Executed Apex data script $step_path"
        else
            echo "Importing data plan: $step_path"
            run_cmd sf data import tree \
                --target-org "$ORG_ALIAS" \
                --plan "$step_path" \
                || error $? "\"sf data import tree\" command failed for plan: \"$step_path\"."

            add_action "Imported dummy data plan $step_path"
        fi
    done
}

publish_community() {
    echo ""
    echo "Publishing community: $COMMUNITY_NAME"

    run_cmd sf community publish \
        --target-org "$ORG_ALIAS" \
        --name "$COMMUNITY_NAME" \
        || error $? "\"sf community publish\" command failed for community: \"$COMMUNITY_NAME\"."

    add_action "Published community $COMMUNITY_NAME"
}

run_self_check() {
    echo ""
    echo "${GREEN}Running self-check...${RESET}"
    echo ""
    echo "Bash version:              ${BASH_VERSION:-unknown}"
    echo "Script file:               $0"
    echo "Working directory:         $(pwd)"
    echo "Org alias:                 $ORG_ALIAS"
    echo "Project file:              $PROJECT_FILE"
    echo "Scratch definition file:   $SCRATCH_DEF_FILE"
    echo "Post steps:                $POST_STEPS"
    echo "Use pool:                  $USE_POOL"
    echo "Install latest packages:   $INSTALL_LATEST_PACKAGES"
    echo ""

    echo "Checking required commands..."
    require_command "sf"
    echo "${GREEN}OK:${RESET} sf"
    require_command "jq"
    echo "${GREEN}OK:${RESET} jq"
    require_command "sed"
    echo "${GREEN}OK:${RESET} sed"

    if [[ "$USE_POOL" == "true" ]]; then
        require_command "sfp"
        echo "${GREEN}OK:${RESET} sfp"

        if [[ -n "$POOL_DEVHUB_USERNAME" ]]; then
            echo "${GREEN}OK:${RESET} pool DevHub provided: $POOL_DEVHUB_USERNAME"
        else
            local resolved_devhub=""
            resolved_devhub="$(resolve_pool_devhub_username)"
            echo "${GREEN}OK:${RESET} resolved default DevHub for sfp: $resolved_devhub"
        fi
    fi

    echo ""
    echo "Checking files..."
    validate_file_exists "$PROJECT_FILE" "Project file"
    echo "${GREEN}OK:${RESET} $PROJECT_FILE exists"
    validate_json_file "$PROJECT_FILE"
    echo "${GREEN}OK:${RESET} $PROJECT_FILE is valid JSON"

    if [[ -f "$SCRATCH_DEF_FILE" ]]; then
        echo "${GREEN}OK:${RESET} $SCRATCH_DEF_FILE exists"
    else
        warning "$SCRATCH_DEF_FILE does not exist. This is only required when creating a scratch org without pool."
    fi

    echo ""
    echo "Checking package dependencies..."
    local count=""
    count="$(dependency_count)"
    echo "Dependencies found: $count"

    if [[ "$count" -eq 0 ]]; then
        error 1 "No package dependencies found in $PROJECT_FILE"
    fi

    ORG_ACTION="No org action. Self-check only."
    add_action "Self-check completed"

    echo ""
    echo "${GREEN}Self-check completed successfully.${RESET}"
    echo "No orgs were created, deleted, fetched, deployed to, or modified."
    echo ""
}

package_plan() {
    local count=""
    count="$(dependency_count)"

    if [[ "$count" -eq 0 ]]; then
        error 1 "No package dependencies found in $PROJECT_FILE"
    fi

    echo ""
    echo "${GREEN}Creating package plan for org: $ORG_ALIAS${RESET}"

    if [[ "$INSTALL_LATEST_PACKAGES" == "true" ]]; then
        echo "Plan mode: latest released package versions"
    else
        echo "Plan mode: versions defined in $PROJECT_FILE"
    fi

    load_installed_packages

    while IFS=$'\t' read -r package_name requested_version; do
        [[ -z "$package_name" ]] && continue

        resolve_package_version "$package_name" "$requested_version"
        warn_if_dependency_is_not_latest "$package_name" "$requested_version"

        local installed_json=""
        local installed_version=""
        local installed_04t=""
        local comparison=""

        installed_json="$(installed_package_json "$package_name")"

        echo ""
        echo "Package:           $package_name"
        echo "Defined version:   $requested_version"
        echo "Target version:    $RESOLVED_SELECTED_VERSION"
        echo "Target 04t:        $RESOLVED_SUBSCRIBER_PACKAGE_VERSION_ID"

        if package_requires_key "$package_name"; then
            echo "Install key:       required"
        else
            echo "Install key:       not required"
        fi

        if [[ -z "$installed_json" || "$installed_json" == "null" ]]; then
            echo "${YELLOW}Plan:${RESET} package is missing and would be installed."
            add_package_missing "$package_name target=$RESOLVED_SELECTED_VERSION"
            continue
        fi

        installed_version="$(installed_package_version "$installed_json")"
        installed_04t="$(installed_package_04t "$installed_json")"

        echo "Installed version: $installed_version"
        echo "Installed 04t:     ${installed_04t:-unknown}"

        comparison="$(compare_versions "$installed_version" "$RESOLVED_SELECTED_VERSION")"

        if [[ "$comparison" == "-1" ]]; then
            echo "${YELLOW}Plan:${RESET} installed version is lower than target and would be updated."
            add_package_updated "$package_name would update $installed_version -> $RESOLVED_SELECTED_VERSION"
        elif [[ "$comparison" == "0" ]]; then
            echo "${GREEN}Plan:${RESET} package is already on target version and would be skipped."
            add_package_skipped "$package_name $installed_version"
        else
            warning "$package_name has a higher version installed than the target version. Installed: $installed_version. Target: $RESOLVED_SELECTED_VERSION. Would skip downgrade."
            add_package_higher_than_target "$package_name installed=$installed_version target=$RESOLVED_SELECTED_VERSION"
        fi

    done < <(read_dependencies)
}

print_settings() {
    local pool_devhub_display="${POOL_DEVHUB_USERNAME:-resolve from sf config target-dev-hub}"

    echo ""
    echo "Scratch org setup settings:"
    echo "Alias:                         $ORG_ALIAS"
    echo "Duration days:                 $DURATION_DAYS"
    echo "Definition file:               $SCRATCH_DEF_FILE"
    echo "Project file:                  $PROJECT_FILE"
    echo "Community name:                $COMMUNITY_NAME"
    echo "Dummy data plan:               $DUMMY_DATA_PLAN"
    echo "Dummy data steps:              $DUMMY_DATA_STEPS"
    echo "Package wait minutes:          $PACKAGE_WAIT_MINUTES"
    echo "Run org create/fetch:          $RUN_ORG_CREATE"
    echo "Use pool:                      $USE_POOL"
    echo "Pool tag:                      $POOL_TAG"
    echo "Pool DevHub:                   $pool_devhub_display"
    echo "Run packages:                  $RUN_PACKAGES"
    echo "Post steps:                    $POST_STEPS"
    echo "Verify package versions:       $VERIFY_PACKAGE_VERSIONS"
    echo "Install latest packages:       $INSTALL_LATEST_PACKAGES"
    echo "Delete org only:               $DELETE_ORG_ONLY"
    echo "Update packages only:          $UPDATE_PACKAGES_ONLY"
    echo "Self-check only:               $SELF_CHECK_ONLY"
    echo "Dry-run:                       $DRY_RUN"
    echo "Package plan only:             $PACKAGE_PLAN_ONLY"
    echo "Packages not requiring key:    $PACKAGES_NOT_REQUIRING_INSTALL_KEY"
    echo ""
}

# -----------------------------
# Arguments
# -----------------------------

while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--alias)
            require_option_value "$1" "${2:-}"
            ORG_ALIAS="$2"
            shift 2
            ;;
        -d|--duration-days)
            require_option_value "$1" "${2:-}"
            DURATION_DAYS="$2"
            shift 2
            ;;
        -f|--definition-file)
            require_option_value "$1" "${2:-}"
            SCRATCH_DEF_FILE="$2"
            shift 2
            ;;
        -p|--project-file)
            require_option_value "$1" "${2:-}"
            PROJECT_FILE="$2"
            shift 2
            ;;
        -c|--community-name)
            require_option_value "$1" "${2:-}"
            COMMUNITY_NAME="$2"
            shift 2
            ;;
        --dummy-data-plan)
            require_option_value "$1" "${2:-}"
            DUMMY_DATA_PLAN="$2"
            DUMMY_DATA_STEPS="plan:$DUMMY_DATA_PLAN"
            shift 2
            ;;
        --dummy-data-steps)
            require_option_value "$1" "${2:-}"
            DUMMY_DATA_STEPS="$2"
            shift 2
            ;;
        -s|--post-steps)
            require_option_value "$1" "${2:-}"
            POST_STEPS="$2"
            shift 2
            ;;
        --install-latest)
            INSTALL_LATEST_PACKAGES=true
            shift
            ;;
        --update-packages)
            UPDATE_PACKAGES_ONLY=true
            shift
            ;;
        --use-pool)
            USE_POOL=true
            shift
            ;;
        --pool-tag)
            require_option_value "$1" "${2:-}"
            POOL_TAG="$2"
            shift 2
            ;;
        --pool-devhub)
            require_option_value "$1" "${2:-}"
            POOL_DEVHUB_USERNAME="$2"
            shift 2
            ;;
        --delete-org-only)
            DELETE_ORG_ONLY=true
            shift
            ;;
        --self-check)
            SELF_CHECK_ONLY=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --package-plan)
            PACKAGE_PLAN_ONLY=true
            shift
            ;;
        --skip-org)
            RUN_ORG_CREATE=false
            shift
            ;;
        --skip-packages)
            RUN_PACKAGES=false
            shift
            ;;
        --skip-version-check)
            VERIFY_PACKAGE_VERSIONS=false
            shift
            ;;
        -h|--help)
            SUMMARY_ENABLED=false
            usage
            exit 0
            ;;
        *)
            error 1 "Unknown argument: $1"
            ;;
    esac
done

# -----------------------------
# Normalize mode shortcuts
# -----------------------------

if [[ "$DELETE_ORG_ONLY" == "true" && "$UPDATE_PACKAGES_ONLY" == "true" ]]; then
    error 1 "You cannot combine --delete-org-only and --update-packages."
fi

if [[ "$DELETE_ORG_ONLY" == "true" && "$PACKAGE_PLAN_ONLY" == "true" ]]; then
    error 1 "You cannot combine --delete-org-only and --package-plan."
fi

if [[ "$DELETE_ORG_ONLY" == "true" ]]; then
    RUN_ORG_CREATE=false
    RUN_PACKAGES=false
    POST_STEPS=none
    USE_POOL=false
fi

if [[ "$SELF_CHECK_ONLY" == "true" ]]; then
    RUN_ORG_CREATE=false
    RUN_PACKAGES=false
    POST_STEPS=none
fi

if [[ "$PACKAGE_PLAN_ONLY" == "true" ]]; then
    RUN_ORG_CREATE=false
    RUN_PACKAGES=false
    POST_STEPS=none
    USE_POOL=false
fi

if [[ "$UPDATE_PACKAGES_ONLY" == "true" ]]; then
    RUN_ORG_CREATE=false
    RUN_PACKAGES=true
    POST_STEPS=none
    USE_POOL=false
fi

# -----------------------------
# Validation
# -----------------------------

validate_number "$DURATION_DAYS" "Duration days"
validate_number "$PACKAGE_WAIT_MINUTES" "Package wait minutes"

validate_boolean "$RUN_ORG_CREATE" "RUN_ORG_CREATE"
validate_boolean "$RUN_PACKAGES" "RUN_PACKAGES"
validate_boolean "$VERIFY_PACKAGE_VERSIONS" "VERIFY_PACKAGE_VERSIONS"
validate_boolean "$INSTALL_LATEST_PACKAGES" "INSTALL_LATEST_PACKAGES"
validate_boolean "$DELETE_ORG_ONLY" "DELETE_ORG_ONLY"
validate_boolean "$UPDATE_PACKAGES_ONLY" "UPDATE_PACKAGES_ONLY"
validate_boolean "$USE_POOL" "USE_POOL"
validate_boolean "$FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY" "FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY"
validate_boolean "$SELF_CHECK_ONLY" "SELF_CHECK_ONLY"
validate_boolean "$DRY_RUN" "DRY_RUN"
validate_boolean "$PACKAGE_PLAN_ONLY" "PACKAGE_PLAN_ONLY"

validate_post_steps
validate_data_steps

require_command "sf"

if [[ "$USE_POOL" == "true" ]]; then
    require_command "sfp"
    require_command "jq"
fi

if needs_project_file; then
    require_command "jq"
    require_command "sed"

    validate_file_exists "$PROJECT_FILE" "Project file"
    validate_json_file "$PROJECT_FILE"
fi

if [[ "$RUN_ORG_CREATE" == "true" && ( "$USE_POOL" != "true" || "$FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY" == "true" ) ]]; then
    validate_file_exists "$SCRATCH_DEF_FILE" "Scratch org definition file"
fi

# -----------------------------
# Main
# -----------------------------

print_settings

if [[ "$SELF_CHECK_ONLY" == "true" ]]; then
    run_self_check
    exit 0
fi

if [[ "$DELETE_ORG_ONLY" == "true" ]]; then
    delete_existing_scratch_org

    echo ""
    echo "${GREEN}Scratch org delete completed successfully.${RESET}"
    echo ""
    exit 0
fi

if [[ "$PACKAGE_PLAN_ONLY" == "true" ]]; then
    ORG_ACTION="No org action. Package plan only."
    package_plan
    print_package_update_suggestions

    echo ""
    echo "${GREEN}Package plan completed successfully.${RESET}"
    echo ""
    exit 0
fi

check_if_package_install_key_is_required
setup_org

if [[ "$USE_POOL" == "true" && "$RUN_PACKAGES" == "true" ]]; then
    update_packages
elif [[ "$UPDATE_PACKAGES_ONLY" == "true" ]]; then
    update_packages
elif [[ "$RUN_PACKAGES" == "true" ]]; then
    install_packages
else
    echo ""
    echo "Skipping package installation."
fi

echo ""
echo "Running selected post steps: $POST_STEPS"

if should_run_post_step "deploy"; then
    deploy_metadata
    add_post_step_run "deploy"
else
    echo "Skipping metadata deploy."
    add_post_step_skipped "deploy"
fi

if should_run_post_step "permsets"; then
    assign_permission_sets
    add_post_step_run "permsets"
else
    echo "Skipping permission set assignment."
    add_post_step_skipped "permsets"
fi

if should_run_post_step "data"; then
    import_dummy_data
    add_post_step_run "data"
else
    echo "Skipping dummy data import."
    add_post_step_skipped "data"
fi

if [[ "$RUN_PACKAGES" == "true" || "$UPDATE_PACKAGES_ONLY" == "true" ]]; then
    print_package_update_suggestions
fi

echo ""
echo "${GREEN}Scratch org setup completed successfully.${RESET}"
echo ""