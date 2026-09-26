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
  macOverrides = flake.lib.mkHome (
    identity
    // {
      system = "aarch64-darwin";
      modules = [
        {
          workstation.macos = {
            keyMappings = [ ];
            nightShift = {
              enable = true;
              start = "18:30";
              end = "07:15";
              temperature = 80;
            };
          };
          targets.darwin.defaults.NSGlobalDomain."com.apple.mouse.scaling" = 2.0;
        }
      ];
    }
  );
  macHeadless = flake.lib.mkHome (
    identity
    // {
      system = "aarch64-darwin";
      profile = "headless";
      fixture = false;
    }
  );

in
assert macHome.config.targets.darwin.defaults."com.apple.dock".autohide == false;
assert macHome.config.targets.darwin.defaults.NSGlobalDomain.KeyRepeat == 1;
assert linuxHome.config.home.file ? "Pictures/Screenshots";
assert !(macHome.config.home.file ? "Pictures/Screenshots");
assert macHome.config.targets.darwin.defaults.NSGlobalDomain."com.apple.mouse.scaling" == 3.0;
assert macHome.config.targets.darwin.defaults.NSGlobalDomain."com.apple.trackpad.scaling" == 1.5;
assert macHome.config.targets.darwin.defaults."com.apple.WindowManager".StandardHideWidgets;
assert macHome.config.targets.darwin.defaults."com.apple.WindowManager".StageManagerHideWidgets;
assert macOverrides.config.targets.darwin.defaults.NSGlobalDomain."com.apple.mouse.scaling" == 2.0;
assert macOverrides.config.workstation.macos.keyMappings == [ ];
assert macOverrides.config.workstation.macos.nightShift.start == "18:30";
assert macOverrides.config.workstation.macos.nightShift.end == "07:15";
assert macOverrides.config.workstation.macos.nightShift.temperature == 80;
assert macOverrides.config.launchd.agents.dotfiles-night-shift.enable;
assert macDocker.config.workstation.macos.nightShift.start == "17:00";
assert macDocker.config.workstation.macos.nightShift.end == "06:00";
assert macDocker.config.workstation.macos.nightShift.temperature == 100;
assert macDocker.config.launchd.agents.dotfiles-night-shift.enable;
assert !(macHome.config.launchd.agents ? dotfiles-night-shift);
assert macHome.config.launchd.agents.dotfiles-keyboard.config.RunAtLoad;
assert macHome.config.launchd.agents.dotfiles-keyboard.config.StartInterval == 60;
assert
  macHome.config.workstation.macos.keyMappings == [
    {
      HIDKeyboardModifierMappingSrc = 30064771129;
      HIDKeyboardModifierMappingDst = 30064771296;
    }
    {
      HIDKeyboardModifierMappingSrc = 30064771296;
      HIDKeyboardModifierMappingDst = 30064771129;
    }
  ];
assert !(macHeadless.config.launchd.agents ? dotfiles-keyboard);
assert !(macHeadless.config.launchd.agents ? dotfiles-night-shift);
assert !(linuxHome.config.launchd.agents ? dotfiles-keyboard);
assert !(linuxHome.config.launchd.agents ? dotfiles-night-shift);
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
