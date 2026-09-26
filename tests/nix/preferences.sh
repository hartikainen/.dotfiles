#!/usr/bin/env bash
set -euo pipefail
if [ "${DOTFILES_TEST_GUEST:-}" != 1 ] || [ "$(uname -s)" != Linux ]; then
    echo 'Run only in a disposable Linux guest.' >&2
    exit 1
fi
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
unset DOTFILES_HOST
system="$(nix eval --impure --raw --expr builtins.currentSystem)"
cp nix/hosts/default.nix nix/hosts/default.nix.preferences-backup
trap 'mv nix/hosts/default.nix.preferences-backup nix/hosts/default.nix' EXIT
cat >nix/hosts/default.nix <<EOF
let machine = marker: {
  system = "$system";
  profile = "desktop";
  homeModules = [ {
    dconf.settings."org/gnome/desktop/interface".clock-show-date = marker == "a";
  } ];
}; in (import ./default.nix.preferences-backup) // {
  preferences-a = machine "a";
  preferences-b = machine "b";
}
EOF

apply() {
    dbus-run-session -- ./bin/dotfiles apply --host "preferences-$1" --home-only --fixture "${@:2}"
}

if [ -L "$HOME/Pictures/Screenshots" ]; then rm "$HOME/Pictures/Screenshots"; fi
mkdir -p "$HOME/Pictures/Screenshots"
printf 'existing capture\n' >"$HOME/Pictures/Screenshots/existing.png"
if apply a; then
    echo 'Unmanaged screenshot directory was overwritten.' >&2
    exit 1
fi
test "$(cat "$HOME/Pictures/Screenshots/existing.png")" = 'existing capture'
apply a --adopt
dbus-run-session -- /usr/bin/python3 tests/nix/linux-preferences.py a
find "$HOME/.local/state/dotfiles/transactions" -path '*/files/Pictures/Screenshots/existing.png' -exec grep -l 'existing capture' {} + | grep -q .
printf 'retained capture\n' >"$HOME/Pictures/Screenshots/retained.png"
apply a
dbus-run-session -- /usr/bin/python3 tests/nix/linux-preferences.py a
apply b
dbus-run-session -- /usr/bin/python3 tests/nix/linux-preferences.py b
dbus-run-session -- ./bin/dotfiles rollback --fixture
dbus-run-session -- /usr/bin/python3 tests/nix/linux-preferences.py a
test "$(cat "$HOME/Desktop/screenshots/retained.png")" = 'retained capture'
printf '\nPreference readback, screenshot adoption, repeated application, update, and rollback passed.\n'
