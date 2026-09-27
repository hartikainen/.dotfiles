{
  config,
  lib,
  pkgs,
  profile,
  ...
}:
let
  shortcuts =
    (builtins.fromJSON (builtins.readFile ../macos-defaults.json))
    ."com.apple.symbolichotkeys".AppleSymbolicHotKeys;
in
{
  options.workstation.macos.symbolicHotKeys = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
    default = { };
    description = "Managed symbolic shortcuts; other shortcut entries remain user-owned.";
  };
  config = lib.mkIf (pkgs.stdenv.isDarwin && profile == "desktop") {
    workstation.macos.symbolicHotKeys = lib.mapAttrs (_: lib.mapAttrs (_: lib.mkDefault)) shortcuts;
    assertions = [
      {
        assertion = !(config.targets.darwin.defaults ? "com.apple.symbolichotkeys");
        message = "Use workstation.macos.symbolicHotKeys to preserve unrelated macOS shortcuts.";
      }
    ];
    home.activation.macosShortcuts = lib.hm.dag.entryAfter [ "setDarwinDefaults" ] ''
      run ${pkgs.python3}/bin/python3 ${../macos-shortcuts.py} ${pkgs.writeText "macos-shortcuts.json" (builtins.toJSON config.workstation.macos.symbolicHotKeys)}
    '';
  };
}
