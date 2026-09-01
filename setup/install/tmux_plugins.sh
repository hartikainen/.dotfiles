#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" &&
    . "../utils.sh"

if [ -z ${XDG_DATA_HOME+x} ]; then
    echo "$(basename -- "${BASH_SOURCE[0]}"):
The \$XDG_DATA_HOME variable must be set for this setup script to function
properly."
    exit 1
fi

# Kept in sync with `TMUX_PLUGIN_MANAGER_PATH` in `.config/tmux/tmux.conf`,
# which has to spell the path out because tmux does not expand `$VAR` in an
# option value.
declare -r PLUGIN_DIRECTORY="${XDG_DATA_HOME}/tmux/plugins"
declare -r TMUX_CONF="../../.config/tmux/tmux.conf"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Clone and update plugins with `git` rather than through
# `tpm/bin/install_plugins`. Those entry points read the install path out of a
# running server's environment, so they start one, and a server started
# without a session takes the default socket even under `TMUX_TMPDIR` on
# Homebrew's tmux 3.7. An install script has no business anywhere near the
# socket the user's session lives on.

plugin_repositories() {

    # Matches the `set -g @plugin 'user/repo'` lines, i.e. the same syntax tpm
    # reads at runtime, so the config stays the single source of truth for
    # which plugins are installed.
    awk '/^[ \t]*set(-option)? +-g +@plugin/ {
             gsub(/'\''/, ""); gsub(/"/, ""); print $4
         }' "${TMUX_CONF}"

}

install_plugin() {

    local -r repository="$1"
    local -r name="$(basename "${repository}")"
    local -r directory="${PLUGIN_DIRECTORY}/${name}"

    if [ ! -d "${directory}/.git" ]; then
        rm -rf "${directory}"
        execute \
            "git clone --depth 1 https://github.com/${repository} ${directory}" \
            "tmux (clone ${name})"
    else
        execute \
            "git -C ${directory} pull --ff-only --depth 1" \
            "tmux (update ${name})"
    fi

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple "\n   tmux plugins\n\n"

    mkd "${PLUGIN_DIRECTORY}"

    # tpm is not in the `@plugin` list: it is what reads that list.
    install_plugin "tmux-plugins/tpm"

    local repository
    while read -r repository; do
        [ -n "${repository}" ] && install_plugin "${repository}"
    done < <(plugin_repositories)

}

main
