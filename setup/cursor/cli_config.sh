#!/bin/bash
#
# Cursor's CLI config is the one file under `.config/` that cannot be
# symlinked out of this repo. The CLI rewrites the whole document when a
# session ends, and it keeps `authInfo` and three server caches in there
# alongside the settings, so a symlink would commit identity and churn on
# every run. This syncs the keys below and leaves the rest alone.
#
#     cli_config.sh apply    # this repo wins, machine-owned keys untouched
#     cli_config.sh export   # capture local changes back into the seed
#
# `apply` runs as part of `setup.sh`. `export` is by hand, when an allowlist
# entry or a display setting is worth keeping.

cd "$(dirname "${BASH_SOURCE[0]}")" &&
    . "../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

declare -r SEED_FILE="cli-config.json"

# The keys this repo owns. Everything omitted belongs to the machine: the
# model picker (`model`, `selectedModel`, `modelParameters`,
# `modelSelectionHistory`, `hasChangedDefaultModel`, `maxMode`), the
# `privacyCache`, `serverConfigCache`, and `autoReviewAvailabilityCache`
# entries, `authInfo`, the `runEverythingSettingsPrompt*` counters, and
# `version`, which the CLI repairs for itself.
declare -r -a TRACKED_KEYS=(
    "approvalMode"
    "attribution"
    "autoAcceptWebSearch"
    "display"
    "editor"
    "exploreSubagentModel"
    "hints"
    "modelSlashCommands"
    "network"
    "notifications"
    "permissions"
    "rewind"
    "sandbox"
)

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Mirrors the CLI's own resolution order, so a machine that sets neither
# variable lands on `~/.cursor` the way the CLI does.
cursor_config_file() {

    if [ -n "${CURSOR_CONFIG_DIR}" ]; then
        printf "%s/cli-config.json" "${CURSOR_CONFIG_DIR}"
    elif [ -n "${XDG_CONFIG_HOME}" ]; then
        printf "%s/cursor/cli-config.json" "${XDG_CONFIG_HOME}"
    else
        printf "%s/.cursor/cli-config.json" "${HOME}"
    fi

}

tracked_keys_json() {

    printf "%s\n" "${TRACKED_KEYS[@]}" | jq -R . | jq -s -c .

}

warn_if_cli_running() {

    if pgrep -f "cursor-agent" >/dev/null 2>&1; then
        print_warning "cursor-agent is running and rewrites this file when it exits"
    fi

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

apply_seed() {

    local liveFile
    liveFile="$(cursor_config_file)"

    local liveDir
    liveDir="$(dirname "${liveFile}")"

    [ -d "${liveDir}" ] || mkdir -p "${liveDir}"

    warn_if_cli_running

    if [ ! -f "${liveFile}" ]; then
        cp "${SEED_FILE}" "${liveFile}"
        print_result $? "${liveFile}"
        return
    fi

    # `*` merges objects recursively but replaces arrays wholesale, which is
    # what the allowlists want, the seed being the source of truth for them.
    if ! jq -s '.[0] * .[1]' "${liveFile}" "${SEED_FILE}" >"${liveFile}.new"; then
        rm -f "${liveFile}.new"
        print_error "${liveFile}"
        return 1
    fi

    mv "${liveFile}.new" "${liveFile}"
    print_result $? "${liveFile}"

}

export_seed() {

    local liveFile
    liveFile="$(cursor_config_file)"

    if [ ! -f "${liveFile}" ]; then
        print_error "${liveFile} does not exist"
        return 1
    fi

    if ! jq -S --argjson keys "$(tracked_keys_json)" \
        'with_entries(select(.key as $k | $keys | index($k)))' \
        "${liveFile}" >"${SEED_FILE}.new"; then
        rm -f "${SEED_FILE}.new"
        print_error "${SEED_FILE}"
        return 1
    fi

    mv "${SEED_FILE}.new" "${SEED_FILE}"
    print_result $? "${SEED_FILE}"

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple "\n • Cursor CLI config\n\n"

    if ! cmd_exists "jq"; then
        print_error "jq is required"
        exit 1
    fi

    case "${1:-apply}" in
        apply) apply_seed ;;
        export) export_seed ;;
        *)
            print_error "usage: $(basename -- "${BASH_SOURCE[0]}") [apply|export]"
            exit 1
            ;;
    esac

}

main "$@"
