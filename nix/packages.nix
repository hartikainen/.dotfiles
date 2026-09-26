{
  pkgs,
  lib,
  profile,
  fixture,
}:
let
  desktop = profile == "desktop";
in
{
  home = lib.unique (
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
      with pkgs;
      [
        act
        aspell
        autoconf
        bash-completion
        bazel-watcher
        bazelisk
        bc
        buildifier
        buildozer
        clang-tools
        cmake
        coreutils
        curl
        delta
        devcontainer
        direnv
        docker-client
        dvc
        editorconfig-core-c
        fd
        ffmpeg
        fzf
        gawk
        gemini-cli
        gh
        ghostscript
        git
        git-absorb
        git-lfs
        gnugrep
        gnumake
        gnupg
        gnused
        gnutar
        grpc
        htop
        icu
        imagemagick
        jq
        ncurses
        ninja
        nodejs
        oh-my-posh
        openssh
        packer
        parallel
        pkgconf
        protobuf
        ripgrep
        ruff
        shellcheck
        shfmt
        texinfo
        tmux
        tree
        tree-sitter
        ty
        unzip
        uv
        yamlfmt
        yq-go
        zlib
        zsh
        zsh-completions
      ]
    )
    ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.glibcLocales ]
    ++ lib.optionals (desktop && !fixture && pkgs.stdenv.isLinux) (
      with pkgs;
      [
        # Prefer Ghostty's terminal definitions over `ncurses`.
        (lib.hiPrio ghostty)
        gimp
        imagemagick
        vlc
        vscode
        xclip
        xsel
        nerd-fonts.fira-code
        nerd-fonts.fira-mono
        nerd-fonts.jetbrains-mono
        nerd-fonts.meslo-lg
      ]
    )
    ++ lib.optionals (desktop && !fixture && pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
      pkgs.spotify
    ]
  );
  homebrew = {
    taps = [ ];
    brews = [
      "brew-cask-completion"
      "docker-completion"
      "nvm"
      "pip-completion"
    ];
    casks = lib.optionals desktop [
      "android-commandlinetools"
      "claude-code"
      "font-fira-code-nerd-font"
      "font-fira-mono-nerd-font"
      "font-jetbrains-mono-nerd-font"
      "font-meslo-lg-nerd-font"
      "gcloud-cli"
      "ghostty"
      "gimp"
      "google-chrome"
      "inkscape"
      "iterm2"
      "mactex-no-gui"
      "obsidian"
      "meshlab"
      "openscad"
      "spotify"
      "temurin"
      "telegram"
      "visual-studio-code"
      "vlc"
      "whatsapp"
    ];
  };
}
