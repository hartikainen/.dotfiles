{
  lib,
  pkgs,
  username,
  homeDirectory,
  profile,
  fixture,
  ...
}:
let
  desktop = profile == "desktop";
  packages = import ../packages.nix {
    inherit
      pkgs
      lib
      profile
      fixture
      ;
  };
in
{
  system.stateVersion = 6;
  environment.variables.HOMEBREW_NO_ANALYTICS = "1";
  system.primaryUser = username;
  users.users.${username}.home = homeDirectory;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix-homebrew = {
    enable = true;
    user = username;
    autoMigrate = true;
    enableRosetta = false;
  };
  homebrew = {
    enable = true;
    inherit (packages.homebrew) taps;
    brews = lib.optionals (!fixture) packages.homebrew.brews;
    casks = if fixture then lib.optionals desktop [ "ghostty" ] else packages.homebrew.casks;
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
