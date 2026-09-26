#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
nix eval --json --impure --expr '
  let flake = builtins.getFlake ("path:" + toString ./.);
  in builtins.map (system: builtins.map (profile:
    (flake.lib.mkHome {
      inherit system profile;
      username = "dotfiles";
      homeDirectory = if system == "aarch64-darwin" then "/Users/dotfiles" else "/home/dotfiles";
      fixture = true;
    }).activationPackage.drvPath
  ) [ "headless" "desktop" ]) [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ]
'
nix eval --raw .#darwinConfigurations.desktop.system.drvPath
