{
  config,
  lib,
  pkgs,
  system-manager,
  username,
  profile,
  ...
}:
let
  cfg = config.workstation;
  desktop = profile == "desktop";
  native = pkgs.writeText "native-packages.json" (
    builtins.toJSON {
      packages = cfg.nativePackages;
      dockerUser = if cfg.docker.enable then username else null;
    }
  );
  manifest = {
    inherit (cfg) requiredServices;
    nativePackages = cfg.nativePackages;
    docker = cfg.docker.enable;
  };
in
{
  imports = [
    ./docker.nix
    ./graphics.nix
  ];
  options.workstation = {
    nativePackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Ubuntu-owned desktop and operating-system integration packages.";
    };
    requiredServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Services that must be active before accepting a system generation.";
    };
  };
  config = {
    nixpkgs.config.allowUnfree = true;
    nix.enable = false;
    security.sudo.enable = false;
    security.enableWrappers = false;
    services.userborn.enable = false;
    workstation.nativePackages = [
      "dbus"
      "dbus-user-session"
      "locales"
    ]
    ++ lib.optionals desktop [
      "ubuntu-desktop-minimal"
      "dconf-service"
    ];
    workstation.requiredServices = [
      "dotfiles-os.service"
    ]
    ++ lib.optionals desktop [ "display-manager.service" ];
    system-manager.preActivationAssertions.ubuntu = {
      enable = true;
      script = ''
        . /etc/os-release
        test "$ID" = ubuntu && test "$VERSION_ID" = 26.04
      '';
    };
    systemd.services.dotfiles-os = {
      description = "Ensure Ubuntu workstation integration packages";
      wantedBy = [ "system-manager.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutStartSec = "30min";
        ExecStart = "/usr/bin/python3 ${../../native-packages.py} ${native}";
      };
    };
    # Keep this override until upstream excludes disabled `userborn` from deactivation.
    # https://github.com/numtide/system-manager/blob/185062bb39493a74599bb3cf7731ee0614cade9b/nix/modules/default.nix#L267
    build.scripts.deactivationScript = lib.mkForce (
      pkgs.writeShellScript "deactivate" ''
        export PATH=/usr/bin:/usr/sbin:/bin:/sbin
        exec ${system-manager}/bin/system-manager-engine deactivate "$@"
      ''
    );
    build.scripts.dotfiles-native = pkgs.writeShellScript "dotfiles-native" ''
      exec /usr/bin/python3 ${../../native-packages.py} ${native}
    '';
    build.scripts.dotfiles-system = pkgs.writeShellScript "dotfiles-system" ''
      exec ${pkgs.python3}/bin/python3 ${../../system-transaction.py} "$@"
    '';
    build.scripts.dotfiles-manifest = pkgs.writeText "dotfiles-manifest" (builtins.toJSON manifest);
  };
}
