#!/usr/bin/env bash
set -euo pipefail
if [ "${DOTFILES_TEST_GUEST:-}" != 1 ] || [ "$(uname -s)" != Darwin ]; then
    echo 'Run only in a disposable macOS VM.' >&2
    exit 1
fi
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
export NIX_CONFIG='experimental-features = nix-command flakes
max-jobs = 2
cores = 4'
profile=/nix/var/nix/profiles/system

host_config() {
    local marker="$1"
    cat >nix/hosts/vm.nix <<EOF
{
  system = "aarch64-darwin";
  profile = "desktop";
  homeModules = [ {
    home.file.".dotfiles-system-test".text = "$marker";
    targets.darwin.defaults."org.dotfiles.test".generation = "$marker";
  } ];
  darwinModules = [ {
    environment.etc."dotfiles-vm-marker".text = "$marker";
    system.defaults.CustomSystemPreferences."/Library/Preferences/org.dotfiles.test".generation = "$marker";
  } ];
}
EOF
}

apply() {
    ./bin/dotfiles apply --host vm --fixture
}

verify() {
    local marker="$1"
    test "$(cat /etc/dotfiles-vm-marker)" = "$marker"
    test "$(cat "$HOME/.dotfiles-system-test")" = "$marker"
    test "$(defaults read org.dotfiles.test generation)" = "$marker"
    test "$(sudo defaults read /Library/Preferences/org.dotfiles.test generation)" = "$marker"
    test "$(defaults read com.apple.dock autohide)" = 1
    LC_ALL=C /usr/sbin/softwareupdate --schedule | grep -q 'turned on'
    test "$(sudo defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload)" = 1
    test "$(sudo defaults read /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall)" = 1
    sudo launchctl print system/org.nixos.nix-daemon >/dev/null
    nix store info --store daemon
    /Applications/Ghostty.app/Contents/MacOS/ghostty +validate-config
}

case "${1:-}" in
    install)
        test ! -e "$profile"
        cp nix/hosts/default.nix nix/hosts/default.nix.original
        printf '(import ./default.nix.original) // { vm = import ./vm.nix; }\n' >nix/hosts/default.nix
        host_config a
        printf 'unmanaged fixture\n' >"$HOME/.bashrc"
        if bash bin/install --host vm --fixture; then
            echo 'Unmanaged home file was overwritten without adoption.' >&2
            exit 1
        fi
        grep -q 'unmanaged fixture' "$HOME/.bashrc"
        echo unmanaged | sudo tee /etc/dotfiles-vm-marker >/dev/null
        if bash bin/install --host vm --fixture --adopt; then
            echo 'Unmanaged system file was overwritten.' >&2
            exit 1
        fi
        test "$(cat /etc/dotfiles-vm-marker)" = unmanaged
        sudo mv /etc/dotfiles-vm-marker /etc/dotfiles-vm-marker.before-nix-darwin
        bash bin/install --host vm --fixture --adopt
        # shellcheck disable=SC1091
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        verify a
        before="$(readlink -f "$profile")"
        apply
        test "$(readlink -f "$profile")" = "$before"
        verify a
        ;;
    boot | rollback-boot)
        verify a
        ;;
    update)
        host_config b
        apply
        verify b
        stable="$(readlink -f "$profile")"
        cp nix/hosts/vm.nix nix/hosts/vm-good.nix
        cat >nix/hosts/vm.nix <<'EOF'
let base = import ./vm-good.nix; in base // {
  darwinModules = base.darwinModules ++ [ ({lib, ...}: {
    environment.etc."dotfiles-vm-marker".text = lib.mkForce "failed-system";
    system.activationScripts.postActivation.text = ''
      touch /var/tmp/dotfiles-system-failure-reached
      if [ -e /var/tmp/dotfiles-system-failure-reached ]; then exit 1; fi
    '';
  }) ];
}
EOF
        if apply; then
            echo 'Failed system activation was accepted.' >&2
            exit 1
        fi
        test -f /var/tmp/dotfiles-system-failure-reached
        test "$(readlink -f "$profile")" = "$stable"
        verify b
        cat >nix/hosts/vm.nix <<'EOF'
let base = import ./vm-good.nix; in base // {
  homeModules = base.homeModules ++ [ ({lib, ...}: {
    home.activation.fail = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      touch "$HOME/.dotfiles-home-failure-reached"
      exit 1
    '';
  }) ];
  darwinModules = base.darwinModules ++ [ ({lib, ...}: {
    environment.etc."dotfiles-vm-marker".text = lib.mkForce "failed-home";
  }) ];
}
EOF
        if apply; then
            echo 'Failed user activation was accepted.' >&2
            exit 1
        fi
        test -f "$HOME/.dotfiles-home-failure-reached"
        test "$(readlink -f "$profile")" = "$stable"
        verify b
        printf 'invalid Nix\n' >nix/hosts/default.nix
        ./bin/dotfiles rollback --system --fixture
        verify a
        ;;
    *) exit 2 ;;
esac
