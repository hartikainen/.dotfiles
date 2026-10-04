flake:
let
  home =
    system: profile: modules:
    flake.lib.mkHome {
      inherit system profile modules;
      username = "dotfiles";
      homeDirectory = "/Users/dotfiles";
      fixture = true;
    };
  desktop = home "aarch64-darwin" "desktop" [ ];
  disabled = home "aarch64-darwin" "desktop" [
    { workstation.macos.finderSidebarPaths = [ ]; }
  ];
  custom = home "aarch64-darwin" "desktop" [
    { workstation.macos.finderSidebarPaths = [ "/Users/dotfiles/Project Files" ]; }
  ];
in
assert
  desktop.config.workstation.macos.finderSidebarPaths == [
    "/Users/dotfiles"
    "/Users/dotfiles/Development"
  ];
assert desktop.config.home.activation ? finderSidebar;
assert !(disabled.config.home.activation ? finderSidebar);
assert !((home "aarch64-darwin" "headless" [ ]).config.home.activation ? finderSidebar);
assert !((home "aarch64-linux" "desktop" [ ]).config.home.activation ? finderSidebar);
assert custom.config.workstation.macos.finderSidebarPaths == [ "/Users/dotfiles/Project Files" ];
true
