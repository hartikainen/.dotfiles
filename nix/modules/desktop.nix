{
  lib,
  pkgs,
  profile,
  homeDirectory,
  ...
}:
let
  desktop = profile == "desktop";
  defaults = lib.mapAttrs (_: lib.mapAttrs (_: lib.mkDefault));
in
{
  targets.darwin.currentHostDefaults = lib.mkIf (desktop && pkgs.stdenv.isDarwin) (defaults {
    "com.apple.ImageCapture".disableHotPlug = true;
    "com.apple.controlcenter" = {
      Bluetooth = 18;
      BatteryShowPercentage = true;
    };
    NSGlobalDomain = {
      "com.apple.mouse.tapBehavior" = 0;
      "com.apple.trackpad.enableSecondaryClick" = true;
      "com.apple.trackpad.trackpadCornerClickBehavior" = 0;
    };
  });
  dconf = lib.mkIf (desktop && pkgs.stdenv.isLinux) {
    enable = true;
    settings = defaults {
      "org/gnome/desktop/peripherals/keyboard" = {
        repeat-interval = lib.hm.gvariant.mkUint32 10;
        delay = lib.hm.gvariant.mkUint32 200;
      };
      "org/gnome/desktop/interface" = {
        clock-show-date = true;
        monospace-font-name = "Monospace 12";
      };
      "org/gnome/desktop/input-sources" = {
        sources = [
          (lib.hm.gvariant.mkTuple [
            "xkb"
            "us"
          ])
          (lib.hm.gvariant.mkTuple [
            "xkb"
            "fi"
          ])
        ];
        xkb-options = [ "ctrl:nocaps" ];
      };
      "org/gnome/terminal/legacy/keybindings" = {
        prev-tab = "<Primary><Shift>Tab";
        next-tab = "<Primary>Tab";
      };
      "org/freedesktop/ibus/panel/emoji".hotkey =
        lib.hm.gvariant.mkEmptyArray lib.hm.gvariant.type.string;
      "org/gnome/gnome-screenshot".auto-save-directory = "file://${homeDirectory}/Desktop/screenshots";
    };
  };
}
