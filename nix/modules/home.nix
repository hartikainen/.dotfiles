{
  lib,
  pkgs,
  inputs,
  username,
  homeDirectory,
  profile,
  fixture,
  ...
}:
let
  root = ../..;
  desktop = profile == "desktop";
  portableFiles = builtins.fromJSON (builtins.readFile ../dotfiles.json);
  selectedFiles = builtins.filter (
    path:
    !(lib.hasPrefix ".agents/skills/" path)
    && (desktop || !(lib.hasPrefix ".config/ghostty/" path || lib.hasPrefix ".config/kitty/" path))
  ) portableFiles;
  skillNames = lib.unique (
    map (path: builtins.elemAt (lib.splitString "/" path) 2) (
      builtins.filter (lib.hasPrefix ".agents/skills/") portableFiles
    )
  );
  sourceFile = path: { source = lib.mkDefault (root + "/${path}"); };
  plugin = name: source: {
    name = ".local/share/tmux/plugins/${name}";
    value.source = source;
  };
in
{
  imports = [
    ./desktop.nix
    ./colima.nix
    ./doom.nix
  ];
  assertions = [
    {
      assertion = builtins.elem profile [
        "headless"
        "desktop"
      ];
      message = "Choose desktop or headless.";
    }
  ];
  home = {
    inherit username homeDirectory;
    stateVersion = "26.05";
    packages =
      (import ../packages.nix {
        inherit
          pkgs
          lib
          profile
          fixture
          ;
      }).home;
    sessionVariables = lib.optionalAttrs pkgs.stdenv.isLinux {
      LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
    };
    file =
      builtins.listToAttrs (
        map (path: {
          name = path;
          value = sourceFile path;
        }) selectedFiles
      )
      // builtins.listToAttrs (
        map (name: {
          name = ".agents/skills/${name}";
          value.source = root + "/.agents/skills/${name}";
        }) skillNames
      )
      // builtins.listToAttrs [
        (plugin "tmux-resurrect" inputs.resurrect)
        (plugin "tmux-continuum" inputs.continuum)
      ]
      // {
        ".local/share/oh-my-zsh".source = inputs.oh-my-zsh;
      };
    activation.localConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "$HOME/.config/bash" "$HOME/.config/zsh" "$HOME/.config/git"
      if [ ! -e "$HOME/.config/bash/local" ]; then run touch "$HOME/.config/bash/local"; fi
      if [ ! -e "$HOME/.config/zsh/local" ]; then
        run cp ${pkgs.writeText "zsh-local" ''
          [ -f "''${XDG_CONFIG_HOME}/bash/local" ] && . "''${XDG_CONFIG_HOME}/bash/local"
        ''} "$HOME/.config/zsh/local"
        run chmod u+w "$HOME/.config/zsh/local"
      fi
      if [ ! -e "$HOME/.config/git/config.local" ]; then run touch "$HOME/.config/git/config.local"; fi
      ${lib.optionalString desktop ''run mkdir -p "$HOME/Desktop/screenshots"''}
    '';
    activation.agentSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run ${(pkgs.python3.withPackages (p: [ p.tomli-w ]))}/bin/python3 ${../merge-settings.py} \
        "''${CODEX_HOME:-$HOME/.codex}/config.toml" ${../settings/codex.toml}
      run ${(pkgs.python3.withPackages (p: [ p.tomli-w ]))}/bin/python3 ${../merge-settings.py} \
        "''${CURSOR_CONFIG_DIR:-$HOME/.config/cursor}/cli-config.json" ${../settings/cursor.json}
    '';
  };
  programs.home-manager.enable = true;
  targets.genericLinux.enable = pkgs.stdenv.isLinux;
  targets.genericLinux.gpu.enable = false;
}
