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
bash setup/platform/bootstrap.sh
```

The Doom submodule requires access to the private repository. Bootstrap verifies pinned Nix and Homebrew installers. macOS requires Apple's command-line tools; Ubuntu and Debian require administrative access for prerequisites. Open a login shell after bootstrap.

```sh
./bin/dotfiles build --profile desktop
./bin/dotfiles diff --profile desktop
./bin/dotfiles apply --profile desktop
```

On macOS, pass `--system` to build, inspect, or apply the `nix-darwin` configuration and native applications. On Linux desktops, `apply --system` also provisions Home Manager's GPU integration through a privileged helper. Use `--profile headless` for shell, development tools, tmux, and terminal Emacs without desktop applications or preferences. Linux system prerequisites are installed by bootstrap; the desktop profile writes GNOME preferences through `dconf`.

`apply` refuses unmanaged file conflicts. After inspecting `diff`, add `--adopt` to move conflicting files into the activation's backup directory before linking managed files. System-file conflicts require manual review. A parent directory symlink (including `~/.config`) requires manual migration; the installer does not traverse it. No command resets the source checkout or deletes `~/.dotfiles`.

`setup/dotfiles.sh`, `setup/setup.sh`, and `setup/update_content.sh` forward to `apply`, `bootstrap`, and `update`. They require an explicit profile. The `-y` flag is not a substitute for conflict review or adoption.

## Ownership

- `nix/packages.json` records the package owner and profile for each entry in the original Homebrew selection. Portable tools come from Nix. `.Brewfile` contains only native macOS exceptions, including Ghostty and `emacs-plus`.
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

Successful home activations retain the active and preceding generations as Nix GC roots under `~/.local/state/dotfiles`. Reapplying the same generation preserves the rollback target. Activation backups are stored beneath that directory's `transactions/` subdirectory. Failed home activation attempts restore adopted files and mutable settings and attempt to reactivate the preceding generation. A failed recovery prints the retained activation path.

Rollback restores managed configuration and Nix package selection. It does not restore application data, remove every preference side effect, or downgrade Homebrew applications. Homebrew activation disables automatic upgrades and cleanup. Upgrade native applications separately with Homebrew after reviewing its proposed changes.

## Emacs

The Doom configuration, invocation aliases, and tmux restoration rules retain the workspace behavior. The client/server workflow is outside this migration. The private submodule remains separate. `nix/doom-revision` records the migration baseline without changing the workspace's pre-existing gitlink difference. Update that revision after committing intentional changes in the private repository. `nix/doom-files.json` names the files copied from it into the activation snapshot.

A complete `apply` runs the pinned Doom framework's installer and synchronization command. To retry synchronization independently:

```sh
./bin/dotfiles doom-sync --profile desktop
```

An unmanaged Emacs installation requires `--adopt`, which retains a backup. Doom's writable package installation remains outside Nix generations. Its framework is locked by `flake.lock`, but custom package recipes may still fetch unpinned revisions. Doom synchronization and its package state are not covered by Nix rollback. A synchronization failure leaves the home generation active and can be retried with `doom-sync`.

## Isolated validation

Run executable checks in disposable containers or VMs. Do not share the host home directory, credentials, or Docker socket with a guest.

```sh
docker build --build-arg BASE=ubuntu:24.04 -f tests/nix/Dockerfile -t dotfiles-test .
docker run --rm dotfiles-test
docker build --build-arg BASE=debian:13 -f tests/nix/Dockerfile -t dotfiles-test-debian .
docker run --rm dotfiles-test-debian
```

The Docker context uses an allowlist and excludes the private Doom checkout. Integration tests run under an unprivileged guest user. They cover conflicts, adoption, repeated activation, local settings, shell startup, tmux configuration and session saving, failed builds, and generation rollback. The internal `--fixture` mode uses a smaller package selection and requires `DOTFILES_TEST_GUEST=1`.

The Nix workflow evaluates all platform/profile combinations, runs Linux jobs on native architecture runners, and builds the macOS system configuration in a hosted Apple Silicon VM. Public CI does not fetch the private Doom repository. Its Emacs smoke check establishes executable startup, not private-Doom or GUI behavior. Dedicated hosted VM jobs exercise macOS settings and Linux desktop GPU provisioning. Full package builds, private-Doom startup, desktop rendering, keyboard handling, and clipboard interaction require their matching isolated integration checks before a workstation rollout.

The scripts under `setup/install/` and `setup/preferences/` remain as migration references until platform validation establishes parity. The supported entry points do not invoke them.
