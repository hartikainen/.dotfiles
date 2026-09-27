#!/usr/bin/env bash
set -euo pipefail
if [ "${DOTFILES_TEST_GUEST:-}" != 1 ] || [ "$(cat /proc/1/comm)" != systemd ]; then
    echo 'Run only in a disposable booted VM.' >&2
    exit 1
fi
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
# shellcheck disable=SC1091
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
export NIX_CONFIG='experimental-features = nix-command flakes
max-jobs = 2
cores = 2'
system="$(nix eval --impure --raw --expr builtins.currentSystem)"
profile=/nix/var/nix/profiles/system-manager-profiles/system-manager

host_config() {
    local marker="$1"
    cat >nix/hosts/vm.nix <<EOF
{
  system = "$system";
  profile = "desktop";
  osRelease = { ID = "ubuntu"; VERSION_ID = "26.04"; };
  homeModules = [ { home.file.".dotfiles-system-test".text = "$marker"; } ];
  linuxModules = [ {
    environment.etc."dotfiles-vm-marker".text = "$marker";
    workstation.docker.settings.labels = if "$marker" == "b" then [ "dotfiles-generation=b" ] else [ ];
  } ];
}
EOF
}

apply() {
    dbus-run-session -- ./bin/dotfiles apply --host vm --fixture
}

wait_boot_services() {
    local boot_deadline=$((SECONDS + 600)) unit
    for unit in docker.service dotfiles-os.service dotfiles-graphics.service display-manager.service; do
        until systemctl is-active --quiet "$unit"; do
            if [ "$SECONDS" -ge "$boot_deadline" ]; then
                systemctl status "$unit" --no-pager || true
                return 1
            fi
            sleep 2
        done
    done
}

verify() {
    local marker="$1"
    test "$(cat /etc/dotfiles-vm-marker)" = "$marker"
    test "$(cat "$HOME/.dotfiles-system-test")" = "$marker"
    systemctl is-active --quiet docker.service
    systemctl is-active --quiet dotfiles-graphics.service
    systemctl is-active --quiet display-manager.service
    test -L /run/opengl-driver
    getent passwd "$(id -u)" >/dev/null
    test "$(stat -c %a /etc/passwd)" = 644
    test "$(stat -c %a /etc/group)" = 644
    sudo "$(readlink -f "$profile")/bin/dotfiles-system" check "$(readlink -f "$profile")"
    if [ -f "$HOME/.test-docker-bin" ]; then
        sudo "$(cat "$HOME/.test-docker-bin")" info --format '{{json .Labels}}' |
            python3 -c 'import json, sys; labels = json.load(sys.stdin) or []; assert ("dotfiles-generation=b" in labels) == (sys.argv[1] == "b")' "$marker"
    fi
}

case "${1:-}" in
    install)
        test ! -e "$profile"
        cp nix/hosts/default.nix nix/hosts/default.nix.original
        printf '(import ./default.nix.original) // { vm = import ./vm.nix; }\n' >nix/hosts/default.nix
        host_config a
        echo original | sudo tee /etc/dotfiles-vm-marker >/dev/null
        candidate="$(./bin/dotfiles build --host vm --fixture | tail -n 1)"
        if sudo "$candidate/bin/dotfiles-system" check "$candidate"; then
            echo 'Unmanaged system file was overwritten without adoption.' >&2
            exit 1
        fi
        test "$(cat /etc/dotfiles-vm-marker)" = original
        dbus-run-session -- bash bin/install --host vm --fixture --adopt
        verify a
        before="$(readlink -f "$profile")"
        apply
        test "$(readlink -f "$profile")" = "$before"
        verify a
        ;;
    containers)
        nix build --impure --out-link /tmp/docker-probe-image --expr '
          let f = builtins.getFlake ("path:" + toString ./.);
              p = import f.inputs.nixpkgs { system = builtins.currentSystem; };
          in p.dockerTools.buildLayeredImage {
            name = "dotfiles-probe"; tag = "test";
            contents = [ p.busybox ];
            config.Cmd = [ "/bin/sleep" "infinity" ];
          }
        '
        docker_bin="$(nix build --impure --no-link --print-out-paths --expr '(builtins.getFlake ("path:" + toString ./.)).inputs.nixpkgs.legacyPackages.${builtins.currentSystem}.docker-client')/bin/docker"
        printf '%s\n' "$docker_bin" >"$HOME/.test-docker-bin"
        sudo "$docker_bin" load -i "$(readlink -f /tmp/docker-probe-image)"
        sudo "$docker_bin" run -d --name dotfiles-probe --restart unless-stopped -v dotfiles-probe:/data dotfiles-probe:test
        sudo "$docker_bin" exec dotfiles-probe sh -c 'echo retained >/data/marker'
        sudo "$docker_bin" exec dotfiles-probe nslookup example.com
        ;;
    boot)
        wait_boot_services
        verify a
        docker_bin="$(cat "$HOME/.test-docker-bin")"
        "$docker_bin" info >/dev/null
        test "$("$docker_bin" exec dotfiles-probe cat /data/marker)" = retained
        ;;
    update)
        bash bin/bootstrap --upgrade-nix
        expected_nix="$(nix eval --impure --raw --expr '(builtins.getFlake ("path:" + toString ./.)).inputs.nixpkgs.legacyPackages.${builtins.currentSystem}.nix.version')"
        test "$(nix --version)" = "nix (Nix) $expected_nix"
        daemon_pid="$(systemctl show nix-daemon.service --property MainPID --value)"
        test "$(sudo readlink "/proc/$daemon_pid/exe")" = "$(readlink -f /nix/var/nix/profiles/default/bin/nix-daemon)"
        docker_pid="$(systemctl show docker.service --property MainPID --value)"
        host_config b
        apply
        verify b
        test "$(systemctl show docker.service --property MainPID --value)" != "$docker_pid"
        stable="$(readlink -f "$profile")"
        cp nix/hosts/vm.nix nix/hosts/vm-good.nix
        cat >nix/hosts/vm.nix <<'EOF'
let base = import ./vm-good.nix; in base // {
  linuxModules = base.linuxModules ++ [ ({pkgs, ...}: {
    systemd.services.dotfiles-failure = {
      wantedBy = [ "system-manager.target" ];
      serviceConfig = { Type = "oneshot"; ExecStart = "${pkgs.coreutils}/bin/false"; };
    };
    workstation.requiredServices = [ "dotfiles-failure.service" ];
    environment.etc."dotfiles-failure-marker".text = "must be recovered";
  }) ];
}
EOF
        if apply; then
            echo 'Failed system service was accepted.' >&2
            exit 1
        fi
        test "$(readlink -f "$profile")" = "$stable"
        test ! -e /etc/dotfiles-failure-marker
        verify b
        cat >nix/hosts/vm.nix <<'EOF'
let base = import ./vm-good.nix; in base // {
  homeModules = base.homeModules ++ [ ({ lib, ... }: {
    home.activation.fail = lib.hm.dag.entryAfter [ "linkGeneration" ] "exit 1";
  }) ];
  linuxModules = base.linuxModules ++ [ ({lib, ...}: {
    environment.etc."dotfiles-vm-marker".text = lib.mkForce "failed-home";
  }) ];
}
EOF
        if apply; then
            echo 'Failed user activation was accepted.' >&2
            exit 1
        fi
        test "$(readlink -f "$profile")" = "$stable"
        verify b
        printf 'invalid Nix\n' >nix/hosts/default.nix
        dbus-run-session -- ./bin/dotfiles rollback --system --fixture
        verify a
        docker_bin="$(cat "$HOME/.test-docker-bin")"
        test "$(sudo "$docker_bin" exec dotfiles-probe cat /data/marker)" = retained
        ;;
    rollback-boot)
        wait_boot_services
        verify a
        docker_bin="$(cat "$HOME/.test-docker-bin")"
        test "$(sudo "$docker_bin" exec dotfiles-probe cat /data/marker)" = retained
        printf '\nClean install, repeat, reboot, update, failure recovery, and paired rollback passed.\n'
        ;;
    *) exit 2 ;;
esac
