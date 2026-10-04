#!/usr/bin/env bash
set -euo pipefail

if [ "${DOTFILES_TEST_GUEST:-}" != 1 ]; then
    echo 'Run only in a disposable container or VM.' >&2
    exit 1
fi
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
python3 -m unittest discover -s tests/nix -p 'test_*.py'

mkdir -p "$HOME/.config/git" "$HOME/.codex" "$HOME/.config/cursor"
printf '[user]\nname = Fixture User\nemail = fixture@example.invalid\n' >"$HOME/.config/git/config.local"
printf '[projects."/fixture"]\ntrust_level = "trusted"\n' >"$HOME/.codex/config.toml"
printf '{"authInfo":{"fixture":true}}\n' >"$HOME/.config/cursor/cli-config.json"
if [ -L "$HOME/.bashrc" ]; then rm "$HOME/.bashrc"; fi
printf 'unmanaged fixture\n' >"$HOME/.bashrc"
if ./bin/dotfiles apply --profile headless --fixture; then
    echo 'Expected a conflict on the unmanaged .bashrc.' >&2
    exit 1
fi
grep -q 'unmanaged fixture' "$HOME/.bashrc"
./bin/dotfiles apply --profile headless --fixture --adopt
profile="$HOME/.local/state/nix/profiles/home-manager"
[ -e "$profile" ] || profile="/nix/var/nix/profiles/per-user/$(id -un)/home-manager"
first="$(readlink -f "$profile")"
./bin/dotfiles apply --profile headless --fixture
test "$first" = "$(readlink -f "$profile")"

export PATH="$HOME/.nix-profile/bin:$PATH"
export TERM=xterm-256color
bash -lc 'test -n "$XDG_CONFIG_HOME"; command -v tmux; command -v emacs'
bash -ic 'alias emacs; test "$(git config --global --includes user.name)" = "Fixture User"'
bash -ic 'review-pr --help' >/dev/null
zsh -ic 'alias emacs; test -n "$XDG_STATE_HOME"'
grep -q /fixture "$HOME/.codex/config.toml"
jq -e '.authInfo.fixture' "$HOME/.config/cursor/cli-config.json"
tmux -L dotfiles-test -f "$HOME/.config/tmux/tmux.conf" new-session -d
trap 'tmux -L dotfiles-test kill-server 2>/dev/null || true' EXIT
test "$(tmux -L dotfiles-test show-option -gv set-clipboard)" = on
test "$(tmux -L dotfiles-test show-option -gwv pane-scrollbars)" = off
test "$(tmux -L dotfiles-test show-option -gv prefix)" = 'C-\'
socket="$(tmux -L dotfiles-test display-message -p '#{socket_path},#{pid},0')"
TMUX="$socket" bash "$HOME/.local/share/tmux/plugins/tmux-resurrect/scripts/save.sh"
test -e "$HOME/.local/share/tmux/resurrect/last" || test -e "$HOME/.tmux/resurrect/last"
emacs -Q --batch --eval '(princ emacs-version)'

cp flake.nix flake.nix.test-backup
printf 'invalid Nix expression\n' >flake.nix
if ./bin/dotfiles apply --profile headless --fixture; then
    mv flake.nix.test-backup flake.nix
    echo 'Expected an invalid configuration to fail before activation.' >&2
    exit 1
fi
mv flake.nix.test-backup flake.nix
test "$first" = "$(readlink -f "$profile")"

cp nix/settings/codex.toml nix/settings/codex.toml.test-backup
printf 'invalid = [\n' >nix/settings/codex.toml
if ./bin/dotfiles apply --profile headless --fixture; then
    mv nix/settings/codex.toml.test-backup nix/settings/codex.toml
    echo 'Expected a settings failure after the write boundary.' >&2
    exit 1
fi
mv nix/settings/codex.toml.test-backup nix/settings/codex.toml
test "$first" = "$(readlink -f "$profile")"
grep -q /fixture "$HOME/.codex/config.toml"

printf '\n# rollback fixture\n' >>.config/bash/options
./bin/dotfiles apply --profile headless --fixture
second="$(readlink -f "$profile")"
test "$first" != "$second"
./bin/dotfiles rollback --profile headless --fixture
test "$first" = "$(readlink -f "$profile")"
test "$(git config --global --includes user.name)" = 'Fixture User'
printf '\nIntegration checks passed. Private Doom and graphical behavior require separate checks.\n'
