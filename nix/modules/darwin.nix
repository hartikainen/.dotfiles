{
  lib,
  username,
  homeDirectory,
  profile,
  fixture,
  ...
}:
let
  desktop = profile == "desktop";
  ledger = builtins.fromJSON (builtins.readFile ../packages.json);
  entries = builtins.attrNames ledger;
  brews = builtins.filter (
    name: ledger.${name}.owner == "homebrew" && ledger.${name}.profile == "headless"
  ) entries;
  casks = builtins.filter (
    name: ledger.${name}.owner == "homebrew" && ledger.${name}.profile == "desktop"
  ) entries;
in
{
  system.stateVersion = 6;
  system.primaryUser = username;
  users.users.${username}.home = homeDirectory;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  homebrew = {
    enable = !fixture;
    taps = [
      "d12frosted/emacs-plus"
      "hashicorp/tap"
    ];
    inherit brews;
    casks = lib.optionals desktop casks;
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };
  };
  system.defaults.CustomUserPreferences = lib.mkIf desktop (
    builtins.fromJSON (
      builtins.replaceStrings [ "@HOME@" ] [ homeDirectory ] (builtins.readFile ../macos-defaults.json)
    )
  );
}
