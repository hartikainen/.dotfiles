{
  description = "Portable workstation and home configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    system-manager.url = "github:numtide/system-manager/release-26.05";
    system-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    doom-nix = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    oh-my-zsh = {
      url = "github:ohmyzsh/ohmyzsh";
      flake = false;
    };
    resurrect = {
      url = "github:tmux-plugins/tmux-resurrect";
      flake = false;
    };
    continuum = {
      url = "github:tmux-plugins/tmux-continuum";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
      ...
    }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAll = nixpkgs.lib.genAttrs systems;
      hosts = import ./nix/hosts;
      hostInventory = nixpkgs.lib.mapAttrs (
        name: host:
        assert nixpkgs.lib.assertMsg (builtins.elem host.system systems)
          "Unsupported system for host ${name}";
        assert nixpkgs.lib.assertMsg (builtins.elem host.profile [
          "desktop"
          "headless"
        ]) "Unsupported profile for host ${name}";
        assert nixpkgs.lib.assertMsg (
          host.system == "aarch64-darwin" || (host.darwinModules or [ ]) == [ ]
        ) "Darwin modules require a macOS host: ${name}";
        assert nixpkgs.lib.assertMsg (
          host.system != "aarch64-darwin" || (host.linuxModules or [ ]) == [ ]
        ) "Linux modules require a Linux host: ${name}";
        {
          inherit (host) system profile;
          osRelease = host.osRelease or { };
        }
      ) hosts;
      getHost = name: hostInventory.${name} or (throw "Unknown host: ${name}");
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      mkHome =
        {
          system,
          username,
          homeDirectory,
          profile,
          fixture ? false,
          modules ? [ ],
        }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor system;
          extraSpecialArgs = {
            inherit
              inputs
              username
              homeDirectory
              profile
              fixture
              ;
          };
          modules = [
            inputs.doom-nix.homeModule
            ./nix/modules/home.nix
          ]
          ++ modules;
        };
      mkDarwin =
        {
          username,
          homeDirectory,
          profile,
          fixture ? false,
          modules ? [ ],
        }:
        nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = {
            inherit
              username
              homeDirectory
              profile
              fixture
              ;
          };
          modules = [
            inputs.nix-homebrew.darwinModules.nix-homebrew
            ./nix/modules/darwin.nix
          ]
          ++ modules;
        };
      mkHostHome =
        {
          host,
          username,
          homeDirectory,
          fixture ? false,
        }:
        mkHome {
          inherit username homeDirectory fixture;
          inherit (getHost host) system profile;
          modules = hosts.${host}.homeModules or [ ];
        };
      mkLinux =
        {
          system,
          username,
          homeDirectory,
          profile,
          fixture ? false,
          modules ? [ ],
        }:
        inputs.system-manager.lib.makeSystemConfig {
          specialArgs = {
            inherit
              inputs
              username
              homeDirectory
              profile
              fixture
              ;
          };
          modules = [
            { nixpkgs.hostPlatform = system; }
            ./nix/modules/linux
          ]
          ++ modules;
        };
      mkHostLinux =
        {
          host,
          username,
          homeDirectory,
          fixture ? false,
        }:
        assert nixpkgs.lib.assertMsg (
          (getHost host).system != "aarch64-darwin"
        ) "Host ${host} is not a Linux machine";
        mkLinux {
          inherit username homeDirectory fixture;
          inherit (getHost host) system profile;
          modules = hosts.${host}.linuxModules or [ ];
        };
      mkHostDarwin =
        {
          host,
          username,
          homeDirectory,
          fixture ? false,
        }:
        assert nixpkgs.lib.assertMsg (
          (getHost host).system == "aarch64-darwin"
        ) "Host ${host} is not a macOS machine";
        mkDarwin {
          inherit username homeDirectory fixture;
          inherit (getHost host) profile;
          modules = hosts.${host}.darwinModules or [ ];
        };
    in
    {
      packages = forAll (system: {
        codex = (pkgsFor system).callPackage ./nix/packages/codex.nix { };
      });
      lib = {
        inherit
          mkHome
          mkDarwin
          mkHostHome
          mkHostDarwin
          mkLinux
          mkHostLinux
          ;
        hosts = hostInventory;
      };
      systemConfigs = nixpkgs.lib.mapAttrs (
        host: _:
        mkHostLinux {
          inherit host;
          username = "dotfiles";
          homeDirectory = "/home/dotfiles";
        }
      ) (nixpkgs.lib.filterAttrs (_: machine: machine.system != "aarch64-darwin") hostInventory);
      homeConfigurations =
        builtins.listToAttrs (
          nixpkgs.lib.concatMap (
            system:
            map
              (profile: {
                name = "${system}-${profile}";
                value = mkHome {
                  inherit system profile;
                  username = "dotfiles";
                  homeDirectory = if system == "aarch64-darwin" then "/Users/dotfiles" else "/home/dotfiles";
                };
              })
              [
                "headless"
                "desktop"
              ]
          ) systems
        )
        // nixpkgs.lib.mapAttrs (
          host: machine:
          mkHostHome {
            inherit host;
            username = "dotfiles";
            homeDirectory = if machine.system == "aarch64-darwin" then "/Users/dotfiles" else "/home/dotfiles";
          }
        ) hostInventory;
      darwinConfigurations = {
        desktop = mkDarwin {
          username = "dotfiles";
          homeDirectory = "/Users/dotfiles";
          profile = "desktop";
        };
      }
      // nixpkgs.lib.mapAttrs (
        host: _:
        mkHostDarwin {
          inherit host;
          username = "dotfiles";
          homeDirectory = "/Users/dotfiles";
        }
      ) (nixpkgs.lib.filterAttrs (_: machine: machine.system == "aarch64-darwin") hostInventory);
      checks = forAll (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          codex = self.packages.${system}.codex;
          lint =
            pkgs.runCommand "dotfiles-lint"
              {
                nativeBuildInputs = [
                  pkgs.shellcheck
                  pkgs.shfmt
                  pkgs.nixfmt
                  pkgs.ruff
                  pkgs.bash
                ];
              }
              ''
                cp -R ${self} source
                chmod -R u+w source
                cd source
                bash tests/nix/lint.sh
                touch "$out"
              '';
          controller =
            pkgs.runCommand "dotfiles-controller-tests"
              {
                nativeBuildInputs = [
                  (pkgs.python3.withPackages (p: [ p.tomli-w ]))
                  pkgs.git
                ];
              }
              ''
                cp -R ${self} source
                chmod -R u+w source
                cd source
                python3 -m unittest discover -s tests/nix -p 'test_*.py'
                touch "$out"
              '';
        }
      );
      devShells = forAll (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              python3
              git
              jq
              yq-go
              shellcheck
              shfmt
              nixfmt
              ruff
            ];
          };
        }
      );
    };
}
