{
  config,
  lib,
  pkgs,
  homeDirectory,
  profile,
  fixture,
  ...
}:
{
  services.colima = lib.mkIf (pkgs.stdenv.isDarwin && profile == "desktop" && !fixture) {
    enable = true;
    colimaHomeDir = ".local/share/dotfiles/colima";
    dockerPackage = pkgs.docker-client;
    profiles.default = {
      isActive = false;
      isService = true;
      setDockerHost = true;
      settings = {
        vmType = "vz";
        mountType = "virtiofs";
        runtime = "docker";
        cpu = 4;
        memory = 4;
        disk = 100;
        autoActivate = false;
        forwardAgent = false;
        mounts = [
          {
            location = homeDirectory;
            writable = true;
          }
        ];
      };
    };
  };
  launchd.agents = lib.mkIf config.services.colima.enable {
    colima-default.config = {
      KeepAlive = lib.mkForce true;
      ThrottleInterval = 10;
    };
  };
  home.activation = lib.mkIf config.services.colima.enable {
    colimaLogDirectory = lib.hm.dag.entryBefore [ "setupLaunchAgents" ] ''
      run mkdir -p "${config.xdg.stateHome}/colima"
    '';
    colimaHealth = lib.hm.dag.entryAfter [ "setupLaunchAgents" ] ''
      if [ -z "''${DRY_RUN_CMD:-}" ]; then
        ready=0
        for attempt in $(${pkgs.coreutils}/bin/seq 1 120); do
          if ${pkgs.docker-client}/bin/docker --host ${lib.escapeShellArg config.home.sessionVariables.DOCKER_HOST} info >/dev/null 2>&1; then
            ready=1
            break
          fi
          sleep 5
        done
        if [ "$ready" != 1 ]; then
          echo "Colima failed to become ready; inspect ${config.xdg.stateHome}/colima/default.log" >&2
          exit 1
        fi
      fi
    '';
  };
}
