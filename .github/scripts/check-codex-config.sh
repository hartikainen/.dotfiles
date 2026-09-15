#!/bin/bash

set -eo pipefail

repoRoot="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
testDir="$(mktemp -d)"
trap 'rm -rf "${testDir}"' EXIT

mkdir -p "${testDir}/setup/codex"
cp "${repoRoot}/setup/codex/config.sh" "${testDir}/setup/codex/"
cp "${repoRoot}/setup/utils.sh" "${testDir}/setup/"

# shellcheck source=setup/codex/config.sh
. "${testDir}/setup/codex/config.sh"

codex_config_file() {
    printf '%s/live/config.toml' "${testDir}"
}

cat >config.toml <<'TOML'
model = "gpt-6-astra"
model_reasoning_effort = "high"
root_list = ["seed"]
empty_list = []

[agents]
max_concurrent_threads_per_session = 4

[tui]
whimsy = false
TOML

main apply >"${testDir}/apply.log"
cmp config.toml "$(codex_config_file)"

cat >"$(codex_config_file)" <<'TOML'
local_setting = "keep"

[projects."/tmp/codex-config-test"]
trust_level = "trusted"

[tui]
whimsy = true
theme = "local"

[agents]
max_concurrent_threads_per_session = 1

[agents.reviewer]
config_file = "review.toml"
TOML

main apply >"${testDir}/apply.log"
yq -e -p toml -o json '
    .model == "gpt-6-astra" and
    .model_reasoning_effort == "high" and
    (.root_list | length) == 1 and .root_list[0] == "seed" and
    (.empty_list | length) == 0 and
    .local_setting == "keep" and
    .projects."/tmp/codex-config-test".trust_level == "trusted" and
    .tui.whimsy == false and
    .tui.theme == "local" and
    .agents.max_concurrent_threads_per_session == 4 and
    .agents.reviewer.config_file == "review.toml" and
    (.agents | length) == 2
' "$(codex_config_file)" >/dev/null

cp "$(codex_config_file)" "${testDir}/applied.toml"
main apply >"${testDir}/apply.log"
cmp "${testDir}/applied.toml" "$(codex_config_file)"

cat >"$(codex_config_file)" <<'TOML'
[[local_rows]]
name = "keep"
TOML

main apply >"${testDir}/apply.log"
yq -e -p toml -o json '
    .model == "gpt-6-astra" and
    (.root_list | length) == 1 and .root_list[0] == "seed" and
    (.empty_list | length) == 0 and
    (.local_rows | length) == 1 and .local_rows[0].name == "keep" and
    .tui.whimsy == false
' "$(codex_config_file)" >/dev/null

cp "$(codex_config_file)" "${testDir}/applied.toml"
yqBinary="$(command -v yq)"
yq() {
    case " $* " in
        *' -o toml '*)
            "${yqBinary}" "$@" | awk '
                /^model = / { model = $0; next }
                /^\[agents\]$/ { print; print model; next }
                { print }
            '
            ;;
        *) "${yqBinary}" "$@" ;;
    esac
}

if main apply >"${testDir}/apply.log" 2>&1; then
    printf 'Corrupt TOML output accepted.\n' >&2
    exit 1
fi
cmp "${testDir}/applied.toml" "$(codex_config_file)"
test ! -e "$(codex_config_file).new"
unset -f yq

printf 'model = [\n' >config.toml
if main apply >"${testDir}/apply.log" 2>&1; then
    printf 'Invalid seed accepted.\n' >&2
    exit 1
fi
cmp "${testDir}/applied.toml" "$(codex_config_file)"

printf 'Codex config checks passed.\n'
