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
nix eval --json --impure --expr '
  let flake = builtins.getFlake ("path:" + toString ./.);
  in builtins.map (host:
    let machine = flake.lib.hosts.${host};
        identity = {
          inherit host;
          username = "dotfiles";
          homeDirectory = if machine.system == "aarch64-darwin" then "/Users/dotfiles" else "/home/dotfiles";
          fixture = true;
        };
    in {
      inherit host;
      home = (flake.lib.mkHostHome identity).activationPackage.drvPath;
      darwin = if machine.system == "aarch64-darwin" then (flake.lib.mkHostDarwin identity).system.drvPath else null;
    }
  ) (builtins.attrNames flake.lib.hosts)
'
nix eval --json --impure --expr '
  import ./tests/nix/host-options.nix (builtins.getFlake ("path:" + toString ./.))
'
