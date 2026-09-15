#!/bin/bash
#
# Codex writes its own settings back into `config.toml` through
# `ConfigEditsBuilder`, which follows symlinks to the final target, so
# symlinking that file out of this repo would commit project trust levels,
# hook trust hashes, and TUI counters on every run. Codex offers no include
# mechanism to split them, so this syncs the keys below and leaves the rest
# alone, the same way `cursor/cli_config.sh` handles the Cursor CLI.
#
#     config.sh apply    # this repo wins, machine-owned keys untouched
#     config.sh export   # capture local changes back into the seed
#
# `apply` runs as part of `setup.sh`. `export` is by hand, when a setting is
# worth keeping.
#
# MCP servers are deliberately absent. Codex merges a trusted project's
# `.codex/config.toml` over the user file, which is where per-repository
# servers belong.

cd "$(dirname "${BASH_SOURCE[0]}")" &&
    . "../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

declare -r SEED_FILE="config.toml"

# The keys this repo owns. Everything omitted belongs to the machine:
# `projects` (per-path trust levels), `hooks.state` (hook trust hashes),
# `tui` (theme, keymap, and the model availability counters), `notice`
# (acknowledgements and migration timestamps), `mcp_servers`, and the
# `features` flags.
declare -r -a TRACKED_KEYS=(
    "model"
    "model_reasoning_effort"
    "service_tier"
    "approvals_reviewer"
    "agents"
)

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Codex resolves its home from `CODEX_HOME`, falling back to `~/.codex`.
# There is no XDG fallback, unlike the Cursor CLI.
codex_config_file() {

    if [ -n "${CODEX_HOME:-}" ]; then
        printf "%s/config.toml" "${CODEX_HOME}"
    else
        printf "%s/.codex/config.toml" "${HOME}"
    fi

}

tracked_keys_expression() {

    local key
    local expression=""

    for key in "${TRACKED_KEYS[@]}"; do
        [ -n "${expression}" ] && expression="${expression}, "
        expression="${expression}\"${key}\""
    done

    printf "pick([%s])" "${expression}"

}

warn_if_codex_running() {

    if pgrep -x "codex" >/dev/null 2>&1; then
        print_warning "codex is running and rewrites this file when it exits"
    fi

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

apply_seed() {

    local liveFile
    liveFile="$(codex_config_file)"

    local liveDir
    liveDir="$(dirname "${liveFile}")"

    [ -d "${liveDir}" ] || mkdir -p "${liveDir}"

    warn_if_codex_running

    if [ ! -f "${liveFile}" ]; then
        cp "${SEED_FILE}" "${liveFile}"
        print_result $? "${liveFile}"
        return
    fi

    # `*` merges tables recursively and replaces scalars, so the seed wins on
    # the keys it declares and every machine-owned table survives untouched.
    if ! yq eval-all -p toml -o toml \
        'select(fileIndex == 0) * select(fileIndex == 1)' \
        "${liveFile}" "${SEED_FILE}" >"${liveFile}.new"; then
        rm -f "${liveFile}.new"
        print_error "${liveFile}"
        return 1
    fi

    # TOML encoding must preserve the merged values.
    if ! yq eval-all -e -p toml -o json \
        '((select(fileIndex == 0) * select(fileIndex == 1)) | sort_keys(..) | to_json) ==
            (select(fileIndex == 2) | sort_keys(..) | to_json)' \
        "${liveFile}" "${SEED_FILE}" "${liveFile}.new" >/dev/null; then
        rm -f "${liveFile}.new"
        print_error 'TOML output changed config values; upgrade `yq` and retry'
        return 1
    fi

    mv "${liveFile}.new" "${liveFile}"
    print_result $? "${liveFile}"

}

export_seed() {

    local liveFile
    liveFile="$(codex_config_file)"

    if [ ! -f "${liveFile}" ]; then
        print_error "${liveFile} does not exist"
        return 1
    fi

    if ! yq -p toml -o toml "$(tracked_keys_expression)" \
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

    print_in_purple "\n • Codex config\n\n"

    if ! cmd_exists "yq"; then
        print_error "yq is required"
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

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
