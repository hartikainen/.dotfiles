#!/bin/bash

set -eo pipefail

repoRoot="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
testDir="$(mktemp -d)"
trap 'rm -rf "${testDir}"' EXIT

# shellcheck source=setup/utils.sh
. "${repoRoot}/setup/utils.sh"
# shellcheck source=setup/install_helpers.sh
. "${repoRoot}/setup/install_helpers.sh"

config_yq_usable >/dev/null
test -z "$(missing_config_dependencies)"

(
    yq() { return 2; }
    test "$(missing_config_dependencies)" = yq
)

(
    yqBinary="$(command -v yq)"
    yq() {
        case " $* " in
            *' -o toml '*) printf 'root = []\nextra = true\n[table]\nflag = true\n' ;;
            *) "${yqBinary}" "$@" ;;
        esac
    }
    test "$(missing_config_dependencies)" = yq
)

mkdir -p "${testDir}/setup/cursor" "${testDir}/setup/codex" \
    "${testDir}/setup/install/ubuntu"
export TEST_LOG="${testDir}/steps.log"
export XDG_CONFIG_HOME="${testDir}/config"
export XDG_DATA_HOME="${testDir}/data"

steps=(
    create_directories.sh
    create_symbolic_links.sh
    create_local_config_files.sh
    cursor/cli_config.sh
    codex/config.sh
    set_github_ssh_key.sh
    update_content.sh
)
for step in "${steps[@]}"; do
    cat >"${testDir}/setup/${step}" <<SCRIPT
#!/bin/bash
printf '%s\n' '${step}' >> "\${TEST_LOG}"
[ "\${FAIL_STEP:-}" != '${step}' ]
SCRIPT
    chmod +x "${testDir}/setup/${step}"
done

cd "${testDir}/setup"

git() { printf '%s\n' "${DOTFILES_ORIGIN}"; }
print_warning() { :; }
print_error() { :; }
ask_for_confirmation() {
    printf 'prompt\n' >>"${TEST_LOG}"
    REPLY="${testReply}"
}

missing_config_dependencies() {
    if ! ${dependenciesInstalled:-false}; then
        printf 'jq\nyq\n'
    fi
    return 0
}

(
    skipQuestions=true
    : >"${TEST_LOG}"
    if do_dotfile_setup false -y; then exit 1; fi
    test ! -s "${TEST_LOG}"
)

(
    testReply=n
    : >"${TEST_LOG}"
    if do_dotfile_setup false; then exit 1; fi
    test "$(cat "${TEST_LOG}")" = prompt
)

(
    install_config_dependencies() {
        printf 'install\n' >>"${TEST_LOG}"
        return 1
    }
    : >"${TEST_LOG}"
    if do_dotfile_setup true; then exit 1; fi
    test "$(cat "${TEST_LOG}")" = install
)

(
    install_config_dependencies() { :; }
    : >"${TEST_LOG}"
    if do_dotfile_setup true; then exit 1; fi
    test ! -s "${TEST_LOG}"
)

for mode in false true; do
    (
        install_config_dependencies() {
            test "$*" = 'jq yq'
            printf 'install\n' >>"${TEST_LOG}"
            dependenciesInstalled=true
        }
        testReply=y
        : >"${TEST_LOG}"
        do_dotfile_setup "${mode}"
        {
            if ! $mode; then printf 'prompt\n'; fi
            printf 'install\n'
            printf '%s\n' "${steps[@]}"
        } >"${testDir}/expected"
        diff -u "${testDir}/expected" "${TEST_LOG}"
    )
done

dependenciesInstalled=true
install_config_dependencies() { exit 1; }
for failed in "${steps[@]}"; do
    (
        export FAIL_STEP="${failed}"
        : >"${TEST_LOG}"
        if do_dotfile_setup false; then exit 1; fi
        : >"${testDir}/expected"
        for step in "${steps[@]}"; do
            printf '%s\n' "${step}" >>"${testDir}/expected"
            if [ "${step}" = "${failed}" ]; then break; fi
        done
        diff -u "${testDir}/expected" "${TEST_LOG}"
    )
done

(
    skipQuestions=true
    : >"${TEST_LOG}"
    do_dotfile_setup false -y
    printf '%s\n' "${steps[@]:0:5}" >"${testDir}/expected"
    diff -u "${testDir}/expected" "${TEST_LOG}"
)

# Restore the platform installer after the orchestration stubs.
# shellcheck source=setup/install_helpers.sh
. "${repoRoot}/setup/install_helpers.sh"
cat >install/ubuntu/yq.sh <<'SCRIPT'
printf 'install yq\n' >>"${TEST_LOG}"
SCRIPT

(
    get_os_name() { printf ubuntu; }
    sudo() {
        printf '%s\n' "$*" >>"${TEST_LOG}"
        return "${aptResult:-0}"
    }
    : >"${TEST_LOG}"
    install_config_dependencies jq yq
    printf 'apt-get update\napt-get install -y jq\ninstall yq\n' >"${testDir}/expected"
    diff -u "${testDir}/expected" "${TEST_LOG}"

    aptResult=1
    : >"${TEST_LOG}"
    if install_config_dependencies jq yq; then exit 1; fi
    test "$(cat "${TEST_LOG}")" = 'apt-get update'
)

(
    get_os_name() { printf macos; }
    brew() { printf '%s\n' "$*" >>"${TEST_LOG}"; }
    : >"${TEST_LOG}"
    install_config_dependencies jq yq
    test "$(cat "${TEST_LOG}")" = 'install jq yq'
)

cp "${repoRoot}/setup/utils.sh" "${repoRoot}/setup/install_helpers.sh" .
cat >>utils.sh <<'SCRIPT'
ask_for_sudo() { :; }
SCRIPT
cat >>install_helpers.sh <<'SCRIPT'
verify_os() { return 0; }
missing_config_dependencies() { return 0; }
SCRIPT

for entry in dotfiles.sh setup.sh; do
    cp "${repoRoot}/setup/${entry}" .
    : >"${TEST_LOG}"
    if FAIL_STEP=codex/config.sh bash "./${entry}" -y; then exit 1; fi
    printf '%s\n' "${steps[@]:0:5}" >"${testDir}/expected"
    diff -u "${testDir}/expected" "${TEST_LOG}"
done

printf 'Dotfile setup checks passed.\n'
