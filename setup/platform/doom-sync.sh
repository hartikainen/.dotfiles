#!/usr/bin/env bash
set -euo pipefail

sourceDir="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/doom-source"
target="${XDG_CONFIG_HOME:-$HOME/.config}/emacs"
if [ ! -f "${XDG_CONFIG_HOME:-$HOME/.config}/doom/init.el" ]; then
    echo 'Doom configuration is absent; initialize the private submodule before applying.' >&2
    exit 1
fi
if [ ! -e "$sourceDir/bin/doom" ]; then
    echo 'Apply the home configuration before doom-sync.' >&2
    exit 1
fi
revision="$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve())' "$sourceDir")"
if [ -e "$target" ] && [ ! -f "$target/.dotfiles-source" ]; then
    if [ "${DOTFILES_ADOPT:-}" != 1 ]; then
        echo "Unmanaged Doom installation at $target; use --adopt to retain a backup." >&2
        exit 1
    fi
    mv "$target" "${target}.backup.$(date +%s)"
fi
for legacy in "$HOME/.emacs" "$HOME/.emacs.el" "$HOME/.emacs.d"; do
    if [ -e "$legacy" ] || [ -L "$legacy" ]; then
        if [ "${DOTFILES_ADOPT:-}" != 1 ]; then
            echo "Emacs loads $legacy before the managed configuration; use --adopt to back it up." >&2
            exit 1
        fi
        mv "$legacy" "${legacy}.backup.$(date +%s)"
    fi
done
if [ ! -e "$target" ] || [ "$(cat "$target/.dotfiles-source")" != "$revision" ]; then
    candidate="$(mktemp -d "${target}.candidate.XXXXXX")"
    cp -R "$sourceDir/." "$candidate/"
    chmod -R u+w "$candidate"
    git -C "$candidate" init -q
    git -C "$candidate" add .
    git -C "$candidate" -c user.name=dotfiles -c user.email=dotfiles@localhost -c commit.gpgsign=false commit -qm 'Initialize pinned Doom source'
    printf '%s\n' "$revision" >"$candidate/.dotfiles-source"
    if [ -e "$target" ]; then
        mv "$target" "${target}.backup.$(date +%s)"
    fi
    mv "$candidate" "$target"
fi
"$target/bin/doom" install -! --no-env --no-config
"$target/bin/doom" sync -!
