{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.workstation.docker = {
    enable = lib.mkEnableOption "the system Docker daemon" // {
      default = true;
    };
    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Docker daemon settings.";
    };
  };
  config = lib.mkIf config.workstation.docker.enable {
    workstation.nativePackages = [ "apparmor" ];
    workstation.requiredServices = [ "docker.service" ];
    workstation.docker.settings.log-driver = lib.mkDefault "local";
    environment.etc."docker/daemon.json".text = builtins.toJSON config.workstation.docker.settings;
    systemd.services.docker = {
      description = "Docker Application Container Engine";
      wantedBy = [ "system-manager.target" ];
      requires = [ "dotfiles-os.service" ];
      after = [
        "dotfiles-os.service"
        "network-online.target"
        "apparmor.service"
      ];
      wants = [
        "network-online.target"
        "apparmor.service"
      ];
      path = [ "/usr" ];
      restartTriggers = [ config.environment.etc."docker/daemon.json".source ];
      serviceConfig = {
        Type = "notify";
        ExecStart = "${pkgs.docker}/bin/dockerd --config-file=/etc/docker/daemon.json";
        Restart = "on-failure";
        RestartSec = 2;
        TimeoutStartSec = 120;
        Delegate = true;
        KillMode = "process";
        TasksMax = "infinity";
        LimitNOFILE = 1048576;
        OOMScoreAdjust = -500;
      };
    };
  };
}
