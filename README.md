# dotfiles

Nix manages the shared user environment on `aarch64-darwin`, `x86_64-linux`, and `aarch64-linux`. Home Manager installs configuration and packages. `nix-darwin` manages macOS preferences and native Homebrew applications. Ubuntu and Debian retain their system package manager for host prerequisites.

## Install

Use a separate checkout. Do not unpack an archive over an existing installation. Check out the reviewed commit before running any setup command:

```sh
git clone https://github.com/hartikainen/.dotfiles.git workstation
cd workstation
git checkout <reviewed-commit>
git submodule update --init --recursive
git -C .config/doom checkout --detach "$(cat nix/doom-revision)"
bash bin/bootstrap
```

The Doom submodule requires access to the private repository. Bootstrap verifies the pinned Nix installer. `nix-homebrew` installs Homebrew during macOS system activation. macOS requires Apple's command-line tools; Ubuntu and Debian require administrative access for prerequisites. Open a login shell after bootstrap.

```sh
./bin/dotfiles build --profile desktop
./bin/dotfiles diff --profile desktop
./bin/dotfiles apply --profile desktop
```

On macOS, pass `--system` to build, inspect, or apply the `nix-darwin` configuration and native applications. On Linux desktops, `apply --system` also provisions Home Manager's GPU integration through a privileged helper. Use `--profile headless` for shell, development tools, tmux, and terminal Emacs without desktop applications or preferences. Linux system prerequisites are installed by bootstrap; the desktop profile writes GNOME preferences through `dconf`.

`apply` refuses unmanaged file conflicts. After inspecting `diff`, add `--adopt` to move conflicting files into the activation's backup directory before linking managed files. System-file conflicts require manual review. A parent directory symlink (including `~/.config`) requires manual migration; the installer does not traverse it. No command resets the source checkout or deletes `~/.dotfiles`.

`bin/bootstrap` installs Nix and its prerequisites. Package selection and preferences belong to the Nix modules. `bin/dotfiles` provides source filtering, conflict inspection, transactional adoption, and coordinated activation; Home Manager and Nix manage the generations.

## Ownership

- `nix/packages.nix` declares portable packages and native macOS exceptions. `nix-darwin` generates its Homebrew specification from this declaration. Emacs and its Doom packages come from Nix on every platform.
- `nix/dotfiles.json` lists portable configuration files. Add a path to this manifest when adding managed configuration. The controller copies only declared configuration and implementation files into the Nix source snapshot.
- `nix/modules/` contains platform and profile behavior. Native application configuration remains in `.config/` and the shell startup files.
- `nix/macos-defaults.json` contains macOS preferences. Unsupported or replaced preference mechanisms are recorded in `nix/preferences-exceptions.json`.

The configuration uses `~/.config` and `~/.local/share`; the controller rejects alternate `XDG_CONFIG_HOME` or `XDG_DATA_HOME` values before activation.

Git identity stays in `~/.config/git/config.local`; shell overrides stay in `~/.config/{bash,zsh}/local`. Codex and Cursor settings are merged atomically, preserving machine-owned keys. Settings merges preserve values, not comments or original formatting. Credentials, history, caches, and application state are not Nix inputs. Files copied into the Nix store must not contain secrets.

Applications managed by Nix use immutable configuration sources. Edit the checkout and apply it to change those files. Application data and local overrides remain writable. Shell startup does not depend on the checkout's location.

## Update and recover

```sh
./bin/dotfiles update --profile desktop --input nixpkgs
./bin/dotfiles diff --profile desktop
./bin/dotfiles apply --profile desktop
./bin/dotfiles rollback --profile desktop
```

`update` prepares `flake.lock`, builds the selected profile, and runs Nix checks before writing the lockfile back to the checkout. It does not activate changes. Omit `--input` to update all inputs. Review the lockfile diff and run the isolated integration tests before applying. Include `--system` when updating or applying macOS system configuration.

Home Manager records home generations in its native Nix profile, visible with `home-manager generations`. Reapplying the same generation preserves the rollback target. Activation backups are stored under `~/.local/state/dotfiles/transactions/`. Failed home activation attempts restore adopted files and mutable settings and attempt to reactivate the preceding generation. A failed recovery prints the retained activation path.

Rollback restores managed configuration and Nix package selection. It does not restore application data, remove every preference side effect, or downgrade Homebrew applications. `nix-homebrew` pins Homebrew itself and adopts an existing installation during `apply --system`. Homebrew activation disables automatic upgrades and cleanup. Upgrade native applications separately with Homebrew after reviewing its proposed changes.

## Emacs

The private Doom submodule remains separate. `nix/doom-revision` records its expected revision. Update that revision after committing intentional changes in the private repository. `nix/doom-files.json` names the files copied from it into the activation snapshot.

[`nix-doom-emacs-unstraightened`](https://github.com/marienz/nix-doom-emacs-unstraightened) builds Doom and its dependencies in the Nix store. `flake.lock` pins the framework, modules, package recipes, and package overlay. `nix/doom-pins.json` pins custom recipes without editing the private submodule. Edit the configuration or pins, then build and apply; there is no separate `doom sync` installation step. A package build failure happens before activation. Rollback restores the editor package and its configuration together.

The Nix build adapts the private configuration's `bazel-mode` package name to upstream's `bazel` library and its format-on-save exclusion to Doom's `+format-on-save-disabled-modes` setting. These compatibility changes apply to the store copy; the private checkout stays untouched.

Nix supplies the Emacs executable on macOS as well as Linux. The macOS build does not include Homebrew's `emacs-plus` patches. The invocation aliases and tmux restoration rules retain the per-project client/server workflow; the configuration does not start a shared daemon.

Doom uses the `nix` profile and stores writable state beneath the XDG cache, data, and state directories. State outside these locations is not migrated automatically. Copy state such as bookmarks or save history deliberately after validating the editor; package rollback does not roll back that data.

## Host and credential boundaries

Nix on Ubuntu or Debian manages the user environment, not the distribution's kernel, system accounts, or Docker daemon. Bootstrap installs only the prerequisites needed to use Nix. The Linux desktop profile provisions Home Manager's GPU integration with `--system`. Distribution upgrades and existing host services remain under the distribution's control. The Docker CLI comes from Nix and can connect to an existing local or remote daemon.

SSH private keys, agent authentication, and GitHub account enrollment remain machine-owned. Configure authentication before fetching the private Doom submodule. Activation does not generate, upload, replace, or import keys. Neither Nix sources nor test guests include `~/.ssh` or the host agent socket.

## Isolated validation

Run executable checks in disposable containers or VMs. Do not share the host home directory, credentials, or Docker socket with a guest.

```sh
python3 bin/test --base ubuntu:24.04
python3 bin/test --base debian:13

# Complete package selection and public Doom (no private credentials).
python3 bin/test --full
```

`bin/test` runs checks sequentially, limits guest memory and CPU use, and removes its container and image afterward. For the pinned `nixpkgs` inputs, it requires `15 GiB` free for fixture checks or `30 GiB` for `--full`, and stops if free space falls below `4 GiB`. Docker build caches remain reusable. `--storage-path` must name a path on the volume holding Docker's data (the home volume by default). `--platform linux/amd64` or `--platform linux/arm64` selects the guest architecture; cross-architecture execution requires Docker emulation support. Free space inside Docker's virtual disk must also accommodate the build.

The Docker context uses an allowlist and excludes the private Doom checkout. Integration tests run under an unprivileged guest user. They cover conflicts, adoption, repeated activation, local settings, shell startup, tmux configuration and session saving, failed builds, and generation rollback. The internal `--fixture` mode uses a smaller package selection. `--public-doom` uses the public configuration with the complete package selection. Both modes require `DOTFILES_TEST_GUEST=1`.

The Nix workflow runs Linux jobs on native architecture runners and builds the macOS system configuration in a hosted Apple Silicon VM. Public CI does not fetch the private Doom repository. `tests/nix/full.sh` builds and activates the complete headless package selection with a public Doom configuration and starts a named Emacs daemon. Dedicated hosted VM jobs exercise macOS settings, Nix-managed Homebrew and Ghostty installation, and Linux desktop GPU provisioning. Private-Doom startup, desktop rendering, keyboard handling, and clipboard interaction require their matching isolated integration checks before a workstation rollout.

In a disposable VM with the private Doom sources available, `DOTFILES_TEST_GUEST=1 bash tests/nix/private-doom.sh` verifies the full home activation, Bazel mode, Copilot's executable, and independent named Emacs daemons. This check requires the private configuration; public Docker images exclude it.

The supported installation paths are `bin/bootstrap` and `bin/dotfiles`. The repository contains no parallel application installers or preference scripts.

## Agent instructions

[`.codex/AGENTS.md`](.codex/AGENTS.md) holds personal working agreements and writing preferences. The installed `~/.codex/AGENTS.md` links to this file. Keep project APIs, build commands, and repository authorization boundaries in the project's `AGENTS.md`, with detailed conventions and examples in its contributor documentation. A project instruction file must remain usable by contributors who do not have these dotfiles.

Put essential project rules directly in `AGENTS.md` and link to supporting sections with explicit task conditions. A link is a request to read a document, not automatic inclusion of its contents. Keep specialized workflows in skills, with descriptions that identify when they apply.

Edit the tracked instruction files and start a fresh Codex session to check their effect. Verify both the loaded instructions and the resulting behavior on a representative task. See [Codex instruction discovery](https://learn.chatgpt.com/docs/agent-configuration/agents-md) for file precedence and session loading.
