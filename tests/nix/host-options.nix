flake:
let
  identity = {
    username = "dotfiles";
    homeDirectory = "/Users/dotfiles";
    profile = "desktop";
    fixture = true;
  };
  macHome = flake.lib.mkHome (
    identity
    // {
      system = "aarch64-darwin";
      modules = [
        {
          targets.darwin.defaults."com.apple.dock".autohide = false;
          targets.darwin.currentHostDefaults."com.apple.controlcenter".Bluetooth = 24;
        }
      ];
    }
  );
  linuxHome = flake.lib.mkHome (
    identity
    // {
      system = "aarch64-linux";
      homeDirectory = "/home/dotfiles";
      modules = [
        {
          dconf.settings."org/gnome/desktop/interface".clock-show-date = false;
        }
      ];
    }
  );
  linuxSystem = flake.lib.mkLinux {
    system = "aarch64-linux";
    username = "dotfiles";
    homeDirectory = "/home/dotfiles";
    profile = "desktop";
    modules = [ { workstation.docker.settings.labels = [ "fixture" ]; } ];
  };
  macDocker = flake.lib.mkHome (
    identity
    // {
      system = "aarch64-darwin";
      fixture = false;
    }
  );
  macSystem = flake.lib.mkDarwin identity;

in
assert macHome.config.targets.darwin.defaults."com.apple.dock".autohide == false;
assert macHome.config.targets.darwin.defaults.NSGlobalDomain.KeyRepeat == 1;
assert !(macHome.config.targets.darwin.defaults ? "com.apple.SoftwareUpdate");
assert
  macSystem.config.system.defaults.CustomSystemPreferences."/Library/Preferences/com.apple.SoftwareUpdate".AutomaticCheckEnabled;
assert macHome.config.targets.darwin.currentHostDefaults."com.apple.controlcenter".Bluetooth == 24;
assert
  macHome.config.targets.darwin.currentHostDefaults."com.apple.controlcenter".BatteryShowPercentage;
assert linuxHome.config.dconf.settings."org/gnome/desktop/interface".clock-show-date == false;
assert
  linuxHome.config.dconf.settings."org/gnome/desktop/interface".monospace-font-name == "Monospace 12";
assert linuxHome.config.fonts.fontconfig.enable;
assert !linuxHome.config.targets.genericLinux.gpu.enable;
assert !linuxSystem.config.nix.enable;
assert !linuxSystem.config.services.userborn.enable;
assert !linuxSystem.config.security.sudo.enable;
assert !linuxSystem.config.security.enableWrappers;
assert !(linuxSystem.config.systemd.services ? suid-sgid-wrappers);
assert linuxSystem.config.workstation.docker.enable;
assert linuxSystem.config.workstation.docker.settings.log-driver == "local";
assert linuxSystem.config.systemd.services.docker.restartTriggers != [ ];
assert !(linuxSystem.config.systemd.services.docker.serviceConfig ? ExecReload);
assert builtins.elem "docker.service" linuxSystem.config.workstation.requiredServices;
assert macDocker.config.services.colima.profiles.default.settings.vmType == "vz";
assert !macDocker.config.services.colima.profiles.default.isActive;
assert
  macDocker.config.home.sessionVariables.DOCKER_HOST
  == "unix:///Users/dotfiles/.local/share/dotfiles/colima/default/docker.sock";
true
