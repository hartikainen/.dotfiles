#!/usr/bin/env bash
set -euo pipefail
if [ "${DOTFILES_TEST_GUEST:-}" != 1 ] || [ "$(cat /proc/1/comm)" != systemd ]; then
    echo 'Run only in a disposable booted VM.' >&2
    exit 1
fi
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
test ! -e /nix
sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl xz-utils python3
installer="$(mktemp)"
trap 'rm -f "$installer"' EXIT
curl --fail --location --proto '=https' --tlsv1.2 https://releases.nixos.org/nix/nix-2.28.5/install -o "$installer"
python3 - "$installer" <<'PY'
import hashlib, json, pathlib, sys
expected = json.loads(pathlib.Path("tests/nix/bootstrap-previous.json").read_text())["installerSha256"]
assert hashlib.sha256(pathlib.Path(sys.argv[1]).read_bytes()).hexdigest() == expected
PY
sh "$installer" --daemon --yes --no-channel-add
# shellcheck disable=SC1091
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
test "$(nix --version)" = 'nix (Nix) 2.28.5'
bash bin/bootstrap
expected_nix="$(nix --extra-experimental-features 'nix-command flakes' eval --impure --raw --expr '(builtins.getFlake ("path:" + toString ./.)).inputs.nixpkgs.legacyPackages.${builtins.currentSystem}.nix.version')"
test "$(nix --version)" = "nix (Nix) $expected_nix"
