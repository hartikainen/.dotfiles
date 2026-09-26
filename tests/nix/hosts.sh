#!/usr/bin/env bash
set -euo pipefail
if [ "${DOTFILES_TEST_GUEST:-}" != 1 ]; then
    echo 'Run only in a disposable container or VM.' >&2
    exit 1
fi
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
unset DOTFILES_HOST
./bin/dotfiles hosts
system="$(nix eval --impure --raw --expr builtins.currentSystem)"
inventory="$(mktemp)"
nix eval --json .#lib.hosts >"$inventory"
compatible="$(
    python3 - "$inventory" "$system" <<'PY'
import json, platform, sys
release = platform.freedesktop_os_release() if platform.system() == "Linux" else {}
for name, host in json.load(open(sys.argv[1])).items():
    if host["system"] == sys.argv[2] and all(release.get(k) == v for k, v in host["osRelease"].items()):
        print(name)
PY
)"
rm "$inventory"
for host in $compatible; do
    system_flags=()
    if [ "$(uname -s)" = Darwin ]; then
        system_flags=(--system)
    fi
    if [ "${1:-}" = --full ]; then
        ./bin/dotfiles build --host "$host" --public-doom "${system_flags[@]}"
    fi
    if [ "$(uname -s)" = Linux ]; then
        dbus-run-session -- ./bin/dotfiles apply --host "$host" --fixture --adopt
    else
        ./bin/dotfiles apply --host "$host" --fixture --adopt "${system_flags[@]}"
    fi
done

cp nix/hosts/default.nix nix/hosts/default.nix.original
trap 'mv nix/hosts/default.nix.original nix/hosts/default.nix' EXIT
cat >nix/hosts/default.nix <<EOF
let
  machine = marker: {
    system = "$system";
    profile = "headless";
    homeModules = [ ({ pkgs, ... }: {
      home.file.".dotfiles-host-test".text = marker;
      home.file.".config/user-dirs.conf".source = pkgs.writeText "host-user-dirs" marker;
      home.sessionVariables.DOTFILES_HOST_TEST = marker;
    }) ];
  };
in (import ./default.nix.original) // {
  fixture-a = machine "a";
  fixture-b = machine "b";
}
EOF
DOTFILES_HOST=fixture-a ./bin/dotfiles apply --fixture --adopt
test "$(cat "$HOME/.dotfiles-host-test")" = a
test "$(cat "$HOME/.config/user-dirs.conf")" = a
DOTFILES_HOST=nonexistent ./bin/dotfiles apply --host fixture-b --fixture
test "$(cat "$HOME/.dotfiles-host-test")" = b
profile="$HOME/.local/state/nix/profiles/home-manager"
[ -e "$profile" ] || profile="/nix/var/nix/profiles/per-user/$(id -un)/home-manager"
before="$(readlink -f "$profile")"
if ./bin/dotfiles apply --host nonexistent --fixture; then
    echo 'Unknown host activated.' >&2
    exit 1
fi
test "$before" = "$(readlink -f "$profile")"
printf 'invalid Nix expression\n' >nix/hosts/default.nix
DOTFILES_HOST=nonexistent ./bin/dotfiles rollback --fixture
test "$(cat "$HOME/.dotfiles-host-test")" = a
test "$(cat "$HOME/.config/user-dirs.conf")" = a
mv nix/hosts/default.nix.original nix/hosts/default.nix
trap - EXIT
DOTFILES_HOST=nonexistent ./bin/dotfiles apply --profile headless --fixture
test ! -e "$HOME/.dotfiles-host-test"
printf '\nNamed host activation, overrides, and source-independent rollback passed.\n'
