{
  config,
  lib,
  pkgs,
  profile,
  ...
}:
let
  paths = config.workstation.macos.finderSidebarPaths;
  sidebar = pkgs.stdenv.mkDerivation {
    name = "dotfiles-finder-sidebar";
    src = ../finder-sidebar.c;
    dontUnpack = true;
    buildPhase = ''
      $CC -Wall -Wextra -Werror -Wno-deprecated-declarations \
        "$src" -framework CoreServices -o finder-sidebar
    '';
    installPhase = ''
      mkdir -p "$out/bin"
      cp finder-sidebar "$out/bin/"
    '';
  };
in
{
  options.workstation.macos.finderSidebarPaths = lib.mkOption {
    type = lib.types.listOf (lib.types.strMatching "/.*");
    default = [
      config.home.homeDirectory
      "${config.home.homeDirectory}/Development"
      "${config.home.homeDirectory}/tmp"
    ];
    description = "Folders to create and add to Finder favorites, preserving existing sidebar entries.";
  };

  config = lib.mkIf (pkgs.stdenv.isDarwin && profile == "desktop" && paths != [ ]) {
    home.activation.finderSidebar = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p -- ${lib.escapeShellArgs paths}
      if ! run ${sidebar}/bin/finder-sidebar ${lib.escapeShellArgs paths}; then
        warnEcho "Finder sidebar setup failed; retry activation from a macOS graphical session."
      fi
    '';
  };
}
