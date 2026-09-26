{
  lib,
  pkgs,
  fixture,
  profile,
  homeDirectory,
  ...
}:
let
  hasPrivate = builtins.pathExists ../../.config/doom/init.el;
  pins = builtins.fromJSON (builtins.readFile ../doom-pins.json);
  pinDeclarations = pkgs.writeText "doom-pins.el" (
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: revision: ''(package! ${name} :pin "${revision}")'') pins
    )
  );
  doomDir =
    if hasPrivate then
      pkgs.runCommand "doom-config" { } ''
        mkdir -p "$out"
        cp -R ${../../.config/doom}/. "$out/"
        chmod -R u+w "$out"
        # Doom's format module uses a disabled-mode list for save exclusions.
        substituteInPlace "$out/config.el" \
          --replace-fail '+format-on-save-enabled-modes' '+format-on-save-disabled-modes'
        printf '\n' >> "$out/packages.el"
        cat ${pinDeclarations} >> "$out/packages.el"
      ''
    else
      ../../tests/nix/doom;
in
{
  programs.doom-emacs = {
    enable = !fixture;
    inherit doomDir;
    doomLocalDir = "${homeDirectory}/.local/share/nix-doom";
    emacs =
      if pkgs.stdenv.isDarwin then
        pkgs.emacs
      else if profile == "desktop" then
        pkgs.emacs-pgtk
      else
        pkgs.emacs-nox;
    experimentalFetchTree = true;
    emacsPackageOverrides =
      _self: super:
      lib.optionalAttrs (super ? bazel-mode) {
        bazel-mode = super.bazel-mode.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            cp ${../emacs/bazel-mode.el} bazel-mode.el
            chmod u+w bazel-mode.el
          '';
        });
      };
    extraPackages = epkgs: [ epkgs.treesit-grammars.with-all-grammars ];
  };
  home.packages = lib.optionals fixture [
    (if pkgs.stdenv.isDarwin then pkgs.emacs else pkgs.emacs-nox)
  ];
}
