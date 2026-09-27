{
  config,
  lib,
  pkgs,
  inputs,
  profile,
  ...
}:
let
  drivers =
    pkgs.callPackage (inputs.home-manager + "/modules/targets/generic-linux/gpu/gpu-libs-env.nix")
      {
        inherit (pkgs.stdenv.hostPlatform) system;
        addNvidia = false;
        nvidia_x11 = null;
      };
in
{
  options.workstation.graphics.package = lib.mkOption {
    type = lib.types.package;
    default = drivers;
    description = "Nix graphics userspace matching the Ubuntu kernel driver.";
  };
  config = lib.mkIf (profile == "desktop") {
    systemd.services.dotfiles-graphics = {
      description = "Expose Nix graphics drivers";
      wantedBy = [ "system-manager.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "${pkgs.coreutils}/bin/rm -f /run/opengl-driver";
        ExecStart = "${pkgs.coreutils}/bin/ln -sfn ${config.workstation.graphics.package} /run/opengl-driver";
      };
    };
    workstation.requiredServices = [ "dotfiles-graphics.service" ];
  };
}
