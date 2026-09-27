#!/usr/bin/env bash
set -euo pipefail
if [ "${DOTFILES_TEST_GUEST:-}" != 1 ] || [ "$(uname -s)" != Darwin ]; then
    echo 'Run only in a disposable macOS VM.' >&2
    exit 1
fi
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
unset DOTFILES_HOST
cp nix/hosts/default.nix nix/hosts/default.nix.preferences-backup
trap 'mv nix/hosts/default.nix.preferences-backup nix/hosts/default.nix' EXIT
cat >nix/hosts/default.nix <<'EOF'
let machine = marker: {
  system = "aarch64-darwin";
  profile = "desktop";
  homeModules = [ {
    workstation.macos.symbolicHotKeys."60".enabled = marker == "b";
  } ];
}; in (import ./default.nix.preferences-backup) // {
  preferences-a = machine "a";
  preferences-b = machine "b";
}
EOF

apply() {
    ./bin/dotfiles apply --host "preferences-$1" --home-only --fixture "${@:2}"
}

python3 tests/nix/macos-preferences.py seed
apply a --adopt
python3 tests/nix/macos-preferences.py verify a
apply a
python3 tests/nix/macos-preferences.py verify a
apply b
python3 tests/nix/macos-preferences.py verify b
./bin/dotfiles rollback --fixture
python3 tests/nix/macos-preferences.py verify a
printf '\nPreference readback and unrelated shortcuts survived repeated application, update, and rollback.\n'
