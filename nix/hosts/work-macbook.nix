{
  system = "aarch64-darwin";
  profile = "desktop";
  homeModules = [
    {
      workstation.macos.nightShift.enable = false;
    }
  ];
  darwinModules = [ ];
}
