{
  config,
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
  ledger = builtins.fromJSON (builtins.readFile ../packages.json);
  packageNames = map (entry: entry.package) (
    builtins.filter (entry: entry.owner == "nix") (builtins.attrValues ledger)
  );
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
  doomFiles =
    if builtins.pathExists ../../.config/doom/config.el then
      map (name: root + "/.config/doom/${name}") (
        builtins.fromJSON (builtins.readFile ../doom-files.json)
      )
    else
      [ ];
  sourceFile = path: { source = root + "/${path}"; };
  plugin = name: source: {
    name = ".local/share/tmux/plugins/${name}";
    value.source = source;
  };
in
{
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
    packages = lib.unique (
      (with pkgs; [
        bashInteractive
        zsh
        tmux
        bc
        git
        ripgrep
        fd
        fzf
        jq
        yq-go
        python3
        oh-my-posh
        gnused
        ncurses
        curl
        unzip
        gnumake
        stdenv.cc
      ])
      ++ lib.optionals (!fixture) (
        map (name: lib.getAttrFromPath (lib.splitString "." name) pkgs) (
          builtins.filter (
            name:
            !(builtins.elem name [
              "bash"
              "python313"
            ])
          ) packageNames
        )
      )
      ++ lib.optionals pkgs.stdenv.isLinux [
        pkgs.emacs-nox
        pkgs.glibcLocales
      ]
      ++ lib.optionals (desktop && pkgs.stdenv.isLinux) [ config.targets.genericLinux.gpu.setupPackage ]
      ++ lib.optionals (desktop && pkgs.stdenv.isLinux && !fixture) (
        with pkgs;
        [
          ghostty
          gimp
          imagemagick
          vlc
          xclip
          xsel
          nerd-fonts.fira-code
          nerd-fonts.jetbrains-mono
        ]
      )
    );
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
        map (path: {
          name = ".config/doom/" + lib.removePrefix (toString ../../.config/doom + "/") (toString path);
          value.source = path;
        }) doomFiles
      )
      // builtins.listToAttrs (
        map (name: {
          name = ".agents/skills/${name}";
          value.source = root + "/.agents/skills/${name}";
        }) skillNames
      )
      // builtins.listToAttrs [
        (plugin "tpm" inputs.tpm)
        (plugin "tmux-resurrect" inputs.resurrect)
        (plugin "tmux-continuum" inputs.continuum)
      ]
      // {
        ".local/share/oh-my-zsh".source = inputs.oh-my-zsh;
        ".config/dotfiles/doom-source".source = inputs.doom;
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
        "''${CODEX_HOME:-$HOME/.codex}/config.toml" ${../../setup/codex/config.toml}
      run ${(pkgs.python3.withPackages (p: [ p.tomli-w ]))}/bin/python3 ${../merge-settings.py} \
        "''${CURSOR_CONFIG_DIR:-$HOME/.config/cursor}/cli-config.json" ${../../setup/cursor/cli-config.json}
    '';
    activation.hostPreferences = lib.mkIf (desktop && pkgs.stdenv.isDarwin) (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run /usr/bin/defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true
        run /usr/bin/defaults -currentHost write com.apple.controlcenter Bluetooth -int 18
        run /usr/bin/defaults -currentHost write -g com.apple.mouse.tapBehavior -int 0
        run /usr/bin/defaults -currentHost write -g com.apple.trackpad.enableSecondaryClick -bool true
        run /usr/bin/defaults -currentHost write -g com.apple.trackpad.trackpadCornerClickBehavior -int 0
      ''
    );
  };
  programs.home-manager.enable = true;
  targets.genericLinux.enable = pkgs.stdenv.isLinux;
  targets.genericLinux.gpu.enable = pkgs.stdenv.isLinux && desktop;
  dconf = lib.mkIf (desktop && pkgs.stdenv.isLinux) {
    enable = true;
    settings = {
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
