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
  # Nix `2.34.4` prepends its shell hook to the macOS `26` defaults.
  # Remove these hashes when the pinned `nix-darwin` recognizes that installer.
  # https://github.com/NixOS/nix/blob/2.34.4/scripts/install-multi-user.sh
  environment.etc."bashrc".knownSha256Hashes = [
    "8b5e3466922d1ae34bc145e21c7e53e7329a7a7b58b148b436bd954d5e651ac3"
  ];
  environment.etc."zshrc".knownSha256Hashes = [
    "cf0f7b7775b4c058d6085d9e7e57d58c307ca43730f8e4d921a9ef4e530e7e16"
  ];
  system.defaults.CustomSystemPreferences."/Library/Preferences/com.apple.SoftwareUpdate" =
    lib.mkIf desktop
      {
        AutomaticCheckEnabled = lib.mkDefault true;
        AutomaticDownload = lib.mkDefault 1;
        CriticalUpdateInstall = lib.mkDefault 1;
      };
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
}
