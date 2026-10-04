{
  config,
  lib,
  pkgs,
  profile,
  fixture,
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
  nightShift = pkgs.writeShellScript "dotfiles-night-shift" ''
    set -eu
    ${pkgs.nightlight}/bin/nightlight schedule ${lib.escapeShellArg cfg.nightShift.start} ${lib.escapeShellArg cfg.nightShift.end}
    ${pkgs.nightlight}/bin/nightlight temp ${toString cfg.nightShift.temperature}
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
    nightShift = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = !fixture;
        description = "Manage the Night Shift schedule and warmth through CoreBrightness.";
      };
      start = lib.mkOption {
        type = lib.types.strMatching "([01][0-9]|2[0-3]):[0-5][0-9]";
        default = "17:00";
        description = "Local time when Night Shift starts.";
      };
      end = lib.mkOption {
        type = lib.types.strMatching "([01][0-9]|2[0-3]):[0-5][0-9]";
        default = "06:00";
        description = "Local time when Night Shift ends.";
      };
      temperature = lib.mkOption {
        type = lib.types.ints.between 0 100;
        default = 100;
        description = "Night Shift warmth, from 0 (least warm) to 100 (most warm).";
      };
    };
  };

  config = lib.mkIf desktop {
    home.packages = lib.optionals cfg.nightShift.enable [ pkgs.nightlight ];
    home.activation = {
      macosPreferenceLogs = lib.hm.dag.entryBetween [ "setupLaunchAgents" ] [ "writeBoundary" ] ''
        run mkdir -p "${config.xdg.stateHome}/macos-preferences"
      '';
      keyboardMapping = lib.hm.dag.entryAfter [ "setDarwinDefaults" ] ''
        run ${keyboard}
      '';
      nightShift = lib.mkIf cfg.nightShift.enable (
        lib.hm.dag.entryAfter [ "setDarwinDefaults" ] ''
          run ${nightShift}
        ''
      );
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
      dotfiles-night-shift = lib.mkIf cfg.nightShift.enable {
        enable = true;
        config = {
          ProgramArguments = [ "${nightShift}" ];
          RunAtLoad = true;
          LimitLoadToSessionType = "Aqua";
          StandardOutPath = "${config.xdg.stateHome}/macos-preferences/night-shift.log";
          StandardErrorPath = "${config.xdg.stateHome}/macos-preferences/night-shift.log";
        };
      };
    };
  };
}
