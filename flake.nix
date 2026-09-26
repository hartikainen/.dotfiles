{
  description = "Portable workstation and home configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
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
          ];
        };
      mkDarwin =
        {
          username,
          homeDirectory,
          profile,
          fixture ? false,
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
          ];
        };
    in
    {
      lib = { inherit mkHome mkDarwin; };
      homeConfigurations = builtins.listToAttrs (
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
      );
      darwinConfigurations.desktop = mkDarwin {
        username = "dotfiles";
        homeDirectory = "/Users/dotfiles";
        profile = "desktop";
      };
      checks = forAll (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
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
