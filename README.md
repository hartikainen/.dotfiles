# dotfiles

Nix manages the shared user environment on `aarch64-darwin`, `x86_64-linux`, and `aarch64-linux`. Home Manager installs configuration and packages. `nix-darwin` manages macOS system configuration and native Homebrew applications. `system-manager` manages Ubuntu `26.04` services and system files. Ubuntu owns the kernel, login stack, and desktop session. Debian supports the user environment only.

## Install

Use a separate checkout. Do not unpack an archive over an existing installation. Check out the reviewed commit before running any setup command:

```sh
git clone https://github.com/hartikainen/.dotfiles.git workstation
cd workstation
git checkout <reviewed-commit>
git submodule update --init --recursive
bash bin/install --host personal-macbook
```

Start with an installed OS, an administrator account, and network access. OS installation, disk encryption, initial account creation, and credential enrollment or restoration are prerequisites. The Doom submodule requires access to the private repository. Bootstrap installs OS prerequisites, including Apple's command-line tools when offered by `softwareupdate`, and verifies the pinned Nix installer. If Git is unavailable, download and extract the reviewed repository archive first, run `bash bin/bootstrap`, then clone the reviewed commit and initialize its submodule. Alternatively, transfer an archive prepared with `bin/export --private-doom` from a trusted checkout. `nix-homebrew` installs Homebrew during macOS system activation. Log out and back in after installation to load shell variables and Linux group membership.

```sh
./bin/dotfiles build --profile desktop
./bin/dotfiles diff --profile desktop
./bin/dotfiles apply --profile desktop
```

A named host provisions both system and user configuration. Use `--home-only` to inspect or apply only Home Manager. Generic `--profile` commands manage only the user environment unless passed `--system`; Linux system provisioning requires Ubuntu `26.04`. The `headless` profile retains shell tools, tmux, and terminal Emacs without desktop applications or preferences. `bash bin/install --host NAME` bootstraps dependencies and applies the named configuration; it accepts `--adopt` after conflicts have been reviewed.

`apply` refuses unmanaged file conflicts. After inspecting `diff`, add `--adopt` to move conflicting files into the activation's backup directory before linking managed files. Linux system-file conflicts follow the same explicit adoption rule, with root-only backups under `/var/lib/dotfiles-system/transactions`. Existing Ubuntu Docker or containerd packages must be removed deliberately before adopting the Nix daemon; preserve `/var/lib/docker`. A parent directory symlink (including `~/.config`) requires manual migration; the installer does not traverse it. No command resets the source checkout or deletes `~/.dotfiles`.

On macOS, `nix-darwin` backs up recognized OS and Nix installer files before replacing them. It refuses other `/etc` conflicts even with `--adopt`; inspect and archive the reported files with the `.before-nix-darwin` suffix before retrying. The declaration recognizes the Nix `2.34.4` shell hooks on macOS `26` by their complete file hashes.

`bin/bootstrap` installs Nix and its prerequisites. Package selection and preferences belong to the Nix modules. `bin/dotfiles` provides source filtering, conflict inspection, transactional adoption, and coordinated activation; Home Manager and Nix manage the generations.

## Ownership

- `nix/packages.nix` declares portable packages and native macOS exceptions. `nix-darwin` generates its Homebrew specification from this declaration. Emacs and its Doom packages come from Nix on every platform.
- `nix/dotfiles.json` lists portable configuration files. Add a path to this manifest when adding managed configuration. `nix/sources.py` selects implementation files and generates `.dockerignore`; regenerate it with `python3 nix/sources.py > .dockerignore`. The source tests check that the generated allowlist matches the declarations. The controller copies only selected configuration and implementation files into the Nix source snapshot.
- `nix/modules/` contains platform and profile behavior. Native application configuration remains in `.config/` and the shell startup files.
- `nix/macos-defaults.json` contains macOS preferences. Unsupported or replaced preference mechanisms are recorded in `nix/preferences-exceptions.json`.

The configuration uses `~/.config` and `~/.local/share`; the controller rejects alternate `XDG_CONFIG_HOME` or `XDG_DATA_HOME` values before activation.

Git identity stays in `~/.config/git/config.local`; shell overrides stay in `~/.config/{bash,zsh}/local`. Codex and Cursor settings are merged atomically, preserving machine-owned keys. Settings merges preserve values, not comments or original formatting. Credentials, history, caches, and application state are not Nix inputs. Files copied into the Nix store must not contain secrets.

Applications managed by Nix use immutable configuration sources. Edit the checkout and apply it to change those files. Application data and local overrides remain writable. Shell startup does not depend on the checkout's location.

## Machines

`nix/hosts/default.nix` registers machine definitions. Each file selects the platform and profile and can add Home Manager modules through `homeModules`. Mac definitions can also add `nix-darwin` modules through `darwinModules`; Linux definitions use `linuxModules` for `system-manager`.

| Host | Platform | Profile | Distribution |
| --- | --- | --- | --- |
| `personal-macbook` | `aarch64-darwin` | `desktop` | macOS |
| `work-macbook` | `aarch64-darwin` | `desktop` | macOS |
| `personal-desktop` | `x86_64-linux` | `desktop` | Ubuntu `26.04` |
| `work-desktop` | `x86_64-linux` | `desktop` | Ubuntu `26.04` |

The definitions share the package and preference defaults. Add only each machine's differences. The desktop definitions require Ubuntu `26.04` through `osRelease`; bootstrap does not install or upgrade the distribution. Configuration names do not change the operating system's hostname. The controller uses the invoking account's username and home directory.

Linux `arm64` remains supported as `aarch64-linux`. For an ARM machine, add a host with that `system` value or use a generic profile; the desktop and headless profiles are evaluated for both Linux architectures.

```sh
./bin/dotfiles hosts
./bin/dotfiles build --host work-macbook
./bin/dotfiles diff --host work-macbook
./bin/dotfiles apply --host work-macbook
```

Host selection checks the machine's OS, architecture, and any declared `osRelease` requirements before building or activating. The generic `--profile desktop` and `--profile headless` selections remain available on all supported platforms. `--host` and `--profile` are mutually exclusive.

For a machine-specific default, put `export DOTFILES_HOST=work-macbook` in its shell `local` file. An explicit `--host` or `--profile` takes precedence over that variable. Rollback ignores `DOTFILES_HOST` and rejects `--host`; it uses the retained generations, including when a host definition is broken:

```sh
./bin/dotfiles rollback
# Restore the preceding successful home and system pair.
./bin/dotfiles rollback --system
```

For example, a Mac definition can add a development tool and override one shared preference:

```nix
{
  system = "aarch64-darwin";
  profile = "desktop";
  homeModules = [
    ({ pkgs, ... }: {
      home.packages = [ pkgs.go ];
      targets.darwin.defaults."com.apple.dock".autohide = false;
    })
  ];
}
```

Module lists accept file paths, so related machines can import a shared work or personal module under `nix/modules/`. Package lists merge with the shared selection. Shared macOS and GNOME preference values use `lib.mkDefault`, so a host can override one key while retaining the others. Portable dotfile sources also use `lib.mkDefault`; override a file's `home.file.<path>.source` with a host-specific source under `nix/`. Keep credentials and mutable application state outside these modules.

All hosts share `flake.lock`. Review and test lockfile updates together, then apply the reviewed repository commit to each machine when ready. The named `homeConfigurations`, macOS `darwinConfigurations`, and Linux `systemConfigs` exports use the placeholder account `dotfiles` for evaluation; use `bin/dotfiles` to build for the actual account.

## Update and recover

```sh
./bin/dotfiles update --host personal-desktop --input nixpkgs
./bin/dotfiles diff --host personal-desktop
./bin/dotfiles apply --host personal-desktop
./bin/dotfiles rollback --system
```

`update` prepares `flake.lock`, builds the selected profile, and runs Nix checks before writing the lockfile back to the checkout. It does not activate changes. Omit `--input` to update all inputs. Review the lockfile diff and run the isolated integration tests before applying. Named host updates build both the system and user closures. `system-manager` follows the pinned `nixpkgs`; review compatibility before updating either input.

Home Manager records home generations in its native Nix profile, visible with `home-manager generations`. Reapplying the same generation preserves the rollback target. Activation backups are stored under `~/.local/state/dotfiles/transactions/`. Failed home activation attempts restore adopted files and mutable settings and attempt to reactivate the preceding generation. A failed recovery prints the retained activation path.

`rollback --system` uses the preceding successful pair in `~/.local/state/dotfiles/system-deployments.json`, so an unrelated user-only activation cannot silently select a mismatched system. It requires retained store paths and refuses a pair that no longer matches the active profiles.

System and home activation are separate transactions. A power failure between them can leave a mixed pair. Inspect the deployment journal and native profiles, repair any pending system transaction, then reactivate the chosen retained system generation and its paired home generation before applying again. On Linux, use that system generation's `bin/dotfiles-system apply` with `sudo` and its own store path as the argument; run the paired home generation's `activate` as the user. The controller refuses to guess a rollback target for a mixed pair. A first macOS activation has no preceding system generation to restore; inspect a failed attempt's changes and backups before retrying.

Rollback restores managed configuration and Nix package selection. It does not restore application data, remove every preference side effect, or downgrade Homebrew applications. `nix-homebrew` pins Homebrew itself and adopts an existing installation during `apply --system`. Homebrew activation disables automatic upgrades and cleanup. Upgrade native applications separately with Homebrew after reviewing its proposed changes.

## Emacs

The private Doom submodule remains separate. Its Git submodule reference is the authoritative revision. Commit intentional changes in the private repository, stage `.config/doom` in the parent repository, and build and test before committing that reference. Deployment requires a clean private checkout matching the staged reference. All tracked Doom files, including snippets, enter the source snapshot; ignored runtime files and Git metadata do not. Keep secrets outside the private configuration as well as the public repository.

`python3 bin/export /path/to/workstation.tar --private-doom` creates an archive for a disposable guest or a machine without Git authentication. It checks the private checkout against the submodule reference and includes a generated `nix/doom-source.json` receipt containing the revision and file hashes. The installer checks exported files against that receipt. The receipt detects changed or incomplete exports; it is not a signature, so transfer the archive through a trusted channel. A plain private file copy without Git metadata or an export receipt is rejected. Omit `--private-doom` to export public sources only. Archives contain configuration, not SSH keys or Git credential storage, and are created with owner-only permissions.

[`nix-doom-emacs-unstraightened`](https://github.com/marienz/nix-doom-emacs-unstraightened) builds Doom and its dependencies in the Nix store. `flake.lock` pins the framework, modules, package recipes, and package overlay. `nix/doom-pins.json` pins custom recipes without editing the private submodule. Edit the configuration or pins, then build and apply; there is no separate `doom sync` installation step. A package build failure happens before activation. Rollback restores the editor package and its configuration together.

The Nix build adapts the private configuration's `bazel-mode` package name to upstream's `bazel` library and its format-on-save exclusion to Doom's `+format-on-save-disabled-modes` setting. These compatibility changes apply to the store copy; the private checkout stays untouched. The Doom module owns `~/.config/doom` and links files from the same effective configuration used to build the editor, including recipe pins and compatibility changes. Edit the source checkout and rebuild rather than editing these managed files.

Nix supplies the Emacs executable on macOS as well as Linux. The macOS build does not include Homebrew's `emacs-plus` patches. The invocation aliases and tmux restoration rules retain the per-project client/server workflow; the configuration does not start a shared daemon.

Doom uses the `nix` profile and stores writable state beneath the XDG cache, data, and state directories. State outside these locations is not migrated automatically. Copy state such as bookmarks or save history deliberately after validating the editor; package rollback does not roll back that data.

## Host and credential boundaries

| Component | Owner |
| --- | --- |
| User packages, dotfiles, GNOME and macOS preferences, Emacs | Home Manager |
| macOS system configuration and Homebrew applications | `nix-darwin` |
| macOS Docker VM, configuration, and login service | Home Manager's Colima module |
| Ubuntu Docker daemon, `/etc/docker/daemon.json`, graphics userspace links, system units | `system-manager` |
| Ubuntu kernel, drivers, PAM, privileged wrappers, D-Bus, GNOME session, display manager | Ubuntu packages declared through `workstation.nativePackages` |
| Nix daemon and its service | Bootstrap on Linux; `nix-darwin` after macOS system activation |
| Human accounts, credentials, application data | Machine owner |

`nix/modules/linux/` separates Docker, graphics, and OS integration. Host `linuxModules` can extend `workstation.nativePackages`, add services through `systemd.services`, add files through `environment.etc`, and declare health checks in `workstation.requiredServices`. Services required for a usable workstation must appear in that list. Use `environment.systemPackages` only for system administration tools that Home Manager does not install.

`system-manager` uses `reload-or-restart` for changed services. Docker omits `ExecReload` so a generation change restarts the daemon and applies settings that cannot be reloaded. Give host services the same treatment when their package or configuration changes require a restart.

The Ubuntu desktop declaration installs `ubuntu-desktop-minimal` and `dconf-service` when absent. This preserves Ubuntu's kernel and login integration rather than replacing them with NixOS components. An installation using the standalone Home Manager `non-nixos-gpu-setup` helper must archive its unit and `tmpfiles` configuration and disable `non-nixos-gpu.service` before adoption; preflight refuses competing ownership. Mesa userspace comes from the pinned Home Manager graphics derivation and is exposed at `/run/opengl-driver` by the system module. Proprietary NVIDIA machines need a host override of `workstation.graphics.package` matching their Ubuntu kernel driver; that hardware path is not covered by the virtual GPU tests.

The audit retains the legacy shell tools, development packages, Ghostty, tmux, Nix-built Emacs, GNOME keyboard settings, application preferences, fonts, and clipboard tools. `nix/preferences-exceptions.json` records obsolete or private preference interfaces. Linux Docker includes a daemon, persistent data, restart-on-boot service, and membership in the `docker` group (which grants root-equivalent access). macOS uses a separate Colima profile under `~/.local/share/dotfiles/colima`, launched at graphical login with Apple's virtualization backend. `DOCKER_HOST` selects its socket without changing existing Docker contexts. Colima mounts the user's home for development bind mounts; it does not forward the SSH agent.

Colima does not import Docker Desktop images, containers, or volumes. Export application data from an existing Docker backend before moving its workloads to Colima; each backend retains its own data.

[`system-manager`'s `release-26.05` branch](https://github.com/numtide/system-manager/tree/release-26.05) matches the pinned `nixpkgs` release and documents Nix `2.32` or later as its tested baseline. Bootstrap pins Nix `2.34.4` and upgrades an older official multi-user installation through the pinned `nixpkgs` package. `bash bin/bootstrap --upgrade-nix` requests that upgrade explicitly on bootstrap-owned installations. After macOS system activation, update Nix through `nix-darwin` with the host configuration. Other Nix installers retain responsibility for their own upgrades. System rollback does not downgrade the bootstrap-owned Linux Nix daemon; macOS follows its selected `nix-darwin` generation. Ubuntu package updates remain the responsibility of Ubuntu Software Updater or `apt`; `dotfiles update` does not perform a distribution upgrade.

The system transaction checks conflicts, installs missing native prerequisites before the service activation deadline, activates the candidate, verifies managed files and required services, and registers it only after health checks pass. A failed system activation attempts to restore the previous system before Home Manager runs. A failed home activation attempts to restore both components. Root-only transaction state retains adoption backups. After an interrupted system activation, repair the recorded operation before applying again:

```sh
sudo /nix/var/nix/gcroots/dotfiles-system-pending/bin/dotfiles-system repair /nix/var/nix/gcroots/dotfiles-system-pending
```

Repair restores the preceding managed generation. Inspect the retained transaction backups for manual edits made before adoption, especially after interruption. Review any recovery error before retrying. Linux system generations live in `/nix/var/nix/profiles/system-manager-profiles/system-manager`; macOS generations live in `/nix/var/nix/profiles/system`. Avoid garbage-collecting generations needed for recovery.

Rollback does not uninstall Ubuntu packages or Apple command-line tools, reverse maintainer scripts, remove added group memberships, downgrade the OS or bootstrap-owned Linux Nix daemon, restore Docker volumes or Colima disks, downgrade Homebrew applications, or erase every preference written by an earlier configuration. A Docker data-format upgrade can require a data backup to downgrade its daemon safely. Removing a Colima profile from Nix does not delete its VM. Back up application data separately and review service-specific upgrade notes. Interrupted Ubuntu package transactions can require `sudo dpkg --configure -a` before reapplying.

SSH private keys, agent authentication, and GitHub account enrollment remain machine-owned. Configure authentication before fetching the private Doom submodule. Activation does not generate, upload, replace, or import keys. Neither Nix sources nor test guests include `~/.ssh` or the host agent socket.

## Isolated validation

Run executable checks in disposable containers or VMs. Do not share the host home directory, credentials, or Docker socket with a guest.

```sh
python3 bin/test --base ubuntu:26.04
python3 bin/test --base debian:13

# Complete package selection and public Doom (no private credentials).
python3 bin/test --full

# Boot Ubuntu, install, reboot, update, and recover.
python3 bin/test-vm --arch x86_64-linux
python3 bin/test-vm --arch aarch64-linux

# Open a clean Ubuntu guest and perform installation manually.
python3 bin/test-vm --arch x86_64-linux --interactive

# Transfer the pinned private Doom configuration at runtime.
python3 bin/test-vm --arch x86_64-linux --interactive --private-doom

# Verify automatic upgrade from the installer in `tests/nix/bootstrap-previous.json`.
python3 bin/test-vm --arch aarch64-linux --upgrade-from-previous
```

`bin/test` runs checks sequentially, limits guest memory and CPU use, and removes its container and image afterward. For the pinned `nixpkgs` inputs, it requires `15 GiB` free for fixture checks or `30 GiB` for `--full`, and stops if free space falls below `4 GiB`. Docker build caches remain reusable. `--storage-path` must name a path on the volume holding Docker's data (the home volume by default). `--platform linux/amd64` or `--platform linux/arm64` selects the guest architecture; cross-architecture execution requires Docker emulation support. Free space inside Docker's virtual disk must also accommodate the build.

The Docker context uses a generated allowlist and excludes the private Doom checkout and export receipt. Integration tests run under an unprivileged guest user. They cover conflicts, adoption, repeated activation, local settings, shell startup, tmux configuration and session saving, failed builds, and generation rollback. The internal `--fixture` mode uses a smaller package selection. `--public-doom` uses a minimal smoke-test Doom configuration with the complete package selection; it does not reproduce private themes, keybindings, or modules. Both modes require `DOTFILES_TEST_GUEST=1`.

`tests/nix/Dockerfile` preinstalls Nix and test dependencies. Its `/work` directory contains repository source; copying that source does not activate the dotfiles. Use `bin/test-vm --interactive` to begin before bootstrap in an Ubuntu `26.04` VM with an administrator account and network access. The runner copies public source to `~/dotfiles` and opens SSH without installing Nix or applying configuration. The shell prints the installation command and, for an `aarch64-linux` guest, the host configuration edit needed to match its architecture. `bin/install --host personal-desktop --public-doom` with `DOTFILES_TEST_GUEST=1` provisions the full system and user package selection using public Doom. Use `--fixture` instead for a smaller trial. Public-Doom mode avoids credential enrollment; the private setup requires the prerequisites above.

The interactive VM has a terminal console. It supports system services, Docker's daemon, and reboots, but does not expose a graphical desktop. After leaving the guest shell, choose `r` to reconnect or `q` to delete the VM. A guest reboot disconnects SSH; choose `r` to wait for it and reconnect. The disk survives reconnections and reboots within the runner session. Exiting the runner deletes the VM and its changes. The runner shares no host directories, credentials, or Docker socket with the guest.

Pass `--private-doom` with `--interactive` to transfer your pinned Doom sources into the guest. The launcher prepares a checked export and copies it into the container after image creation; private files never enter Docker build layers or build caches. The archive is deleted after transfer, and the guest and container are removed when the runner exits. Inside the guest, run `bash bin/install --host personal-desktop` without either test configuration flag. The ARM guest prints its host architecture edit. Use `--adopt` only after reviewing conflicts. This mode requires no guest GitHub credentials.

`tests/nix/evaluate.sh` evaluates every named host with the fixture package selection and checks preference override behavior. `tests/nix/hosts.sh` activates the named hosts matching the guest's platform and distribution and verifies module overrides and rollback with an invalid registry. `bin/test --full` also builds each matching host with its complete package selection and public Doom configuration. Foreign-platform Doom builds require a matching builder; Linux container checks do not replace macOS VM validation.

The Nix workflow runs Linux jobs on native architecture runners and builds the macOS system configuration in a hosted Apple Silicon VM. Public CI does not fetch the private Doom repository. `tests/nix/full.sh` builds and activates the complete headless package selection with a public Doom configuration and starts a named Emacs daemon. Ubuntu VM tests use checksum-pinned cloud images from `tests/nix/vm-images.json`, generated guest-only SSH keys, and QEMU inside an unprivileged Docker runner. They exercise host installation, conflicts, repeated application, Docker networking and persistent volumes, reboot, configuration updates, failed system and user activations, and paired rollback with a broken source registry. `tests/nix/vm.py` uses software emulation by default and uses `/dev/kvm` when the Linux host exposes it for a matching guest architecture. It requires no macOS hypervisor installation. Software emulation makes package builds and OS installation slower than hardware virtualization. The runner requires `40 GiB` free for the pinned Ubuntu `26.04` fixtures and removes its VM, container, and image afterward.

The macOS CI job checks settings, Homebrew, and Ghostty in a hosted VM. For clean-OS lifecycle checks, copy the public checkout without `.config/doom` into a disposable Apple Silicon macOS VM. Do not attach host directories, credentials, or an SSH agent. Inside that guest, run `DOTFILES_TEST_GUEST=1 bash tests/nix/macos-system.sh install`, reboot, run the `boot` and `update` stages, reboot again, and run `rollback-boot`. The fixture checks bootstrap, conflicts, repeat application, user and system preferences, failed activations, and paired rollback with a broken registry. It requires an administrator account with `sudo` access and uses Homebrew's Ghostty package.

For a manual macOS installation trial, start a separate fresh guest from [Tart's vanilla macOS image](https://tart.run/quick-start/), copy the public source into it, and run `DOTFILES_TEST_GUEST=1 bash bin/install --host personal-macbook --fixture` from that source directory inside the guest. This runs bootstrap and applies the fixture system and user configuration. Inspect any reported conflicts before repeating with `--adopt`, then reboot and explore. Use a separate guest for the automated lifecycle stages, which intentionally introduce failures and leave an invalid source registry to test recovery.

[Tart documents Apple's nested virtualization support for Linux guests only](https://tart.run/faq/); the Colima `vz` backend cannot be validated inside its macOS guests. The macOS fixture excludes Colima. Keep that runtime check outstanding rather than substituting a passing Linux result or macOS evaluation. Private-Doom startup, desktop rendering, keyboard handling, and clipboard interaction also require their matching isolated integration checks before a workstation rollout.

In a disposable VM with the private Doom sources available, `DOTFILES_TEST_GUEST=1 bash tests/nix/private-doom.sh` verifies the full home activation, Bazel mode, Copilot's executable, and independent named Emacs daemons. This check requires the private configuration; public Docker images exclude it.

The installation entry point is `bin/install`; `bin/bootstrap` and `bin/dotfiles` expose its bootstrap and configuration steps separately. The repository contains no parallel application installers or preference scripts.
