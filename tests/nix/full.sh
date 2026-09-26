#!/usr/bin/env bash
set -euo pipefail
if [ "${DOTFILES_TEST_GUEST:-}" != 1 ]; then
    echo 'Run only in a disposable container or VM.' >&2
    exit 1
fi
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
./bin/dotfiles build --profile headless --public-doom
./bin/dotfiles apply --profile headless --public-doom --adopt
export PATH="$HOME/.nix-profile/bin:$PATH"
export TERM=xterm-256color
emacs --daemon=dotfiles-full
trap 'emacsclient --socket-name=dotfiles-full --eval "(kill-emacs)" >/dev/null 2>&1 || true' EXIT
test "$(emacsclient --socket-name=dotfiles-full --eval "(featurep 'doom)")" = t
./bin/dotfiles apply --profile headless --public-doom
command -v docker
command -v shellcheck
command -v gemini
codex --version
command -v devcontainer
printf '\nFull package selection and public Doom startup passed.\n'
