{
  config,
  lib,
  pkgs,
  profile,
  ...
}:
let
  cfg = config.workstation.macos;
  desktop = pkgs.stdenv.isDarwin && profile == "desktop";
  keyboard = pkgs.writeShellScript "dotfiles-keyboard" ''
    /usr/bin/hidutil property --set ${
      lib.escapeShellArg (
        builtins.toJSON {
          UserKeyMapping = cfg.keyMappings;
        }
      )
    }
  '';
in
{
  options.workstation.macos = {
    keyMappings = lib.mkOption {
      type = lib.types.listOf (lib.types.attrsOf lib.types.int);
      default = [
        {
          HIDKeyboardModifierMappingSrc = 30064771129;
          HIDKeyboardModifierMappingDst = 30064771296;
        }
        {
          HIDKeyboardModifierMappingSrc = 30064771296;
          HIDKeyboardModifierMappingDst = 30064771129;
        }
      ];
      description = "User key mappings, defaulting to a Caps Lock and left Control swap.";
    };
  };

  config = lib.mkIf desktop {
    home.activation = {
      macosPreferenceLogs = lib.hm.dag.entryBetween [ "setupLaunchAgents" ] [ "writeBoundary" ] ''
        run mkdir -p "${config.xdg.stateHome}/macos-preferences"
      '';
      keyboardMapping = lib.hm.dag.entryAfter [ "setDarwinDefaults" ] ''
        run ${keyboard}
      '';
    };
    launchd.agents = {
      dotfiles-keyboard = {
        enable = true;
        config = {
          ProgramArguments = [ "${keyboard}" ];
          RunAtLoad = true;
          # HID mappings disappear after reboot or the last keyboard disconnects.
          # https://developer.apple.com/library/archive/technotes/tn2450/_index.html
          StartInterval = 60;
          LimitLoadToSessionType = "Aqua";
          StandardOutPath = "${config.xdg.stateHome}/macos-preferences/keyboard.log";
          StandardErrorPath = "${config.xdg.stateHome}/macos-preferences/keyboard.log";
        };
      };
    };
  };
}
