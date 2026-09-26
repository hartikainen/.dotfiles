flake:
let
  identity = {
    username = "dotfiles";
    homeDirectory = "/Users/dotfiles";
    profile = "desktop";
    fixture = true;
  };
  darwin = flake.lib.mkDarwin (
    identity
    // {
      modules = [
        {
          system.defaults.CustomUserPreferences."com.apple.dock".autohide = false;
        }
      ];
    }
  );
  macHome = flake.lib.mkHome (
    identity
    // {
      system = "aarch64-darwin";
      modules = [
        {
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
in
assert darwin.config.system.defaults.CustomUserPreferences."com.apple.dock".autohide == false;
assert darwin.config.system.defaults.CustomUserPreferences.NSGlobalDomain.KeyRepeat == 1;
assert macHome.config.targets.darwin.currentHostDefaults."com.apple.controlcenter".Bluetooth == 24;
assert
  macHome.config.targets.darwin.currentHostDefaults."com.apple.controlcenter".BatteryShowPercentage;
assert linuxHome.config.dconf.settings."org/gnome/desktop/interface".clock-show-date == false;
assert
  linuxHome.config.dconf.settings."org/gnome/desktop/interface".monospace-font-name == "Monospace 12";
true
