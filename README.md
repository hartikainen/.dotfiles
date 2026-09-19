# dotfiles

My dotfiles.

Two entry points:

- `setup/dotfiles.sh` installs symlinks, local configuration, Cursor settings,
  and Codex settings. It checks for `jq` and a TOML-compatible `yq` before
  changing configuration and prompts to install missing dependencies.
  Dependency installation uses `apt-get` on Ubuntu/Debian and requires
  Homebrew on macOS. It leaves system preferences alone.
- `setup/setup.sh` installs configuration dependencies automatically, applies
  the dotfiles, and then installs the full package selection
  (`brew bundle` on macOS, `apt-get` on Ubuntu/Debian), applies
  system preferences (macOS `defaults`, Ubuntu `gsettings`), and offers
  to reboot.

Pass `-y` to skip the dotfile confirmation prompts. With `setup/dotfiles.sh`,
missing dependencies cause a failure under `-y`; run interactively to approve
their installation. Configuration failures stop setup before the repository
update step.

## Dotfiles only

ubuntu / debian:
```
bash -c "$(wget -qO - https://raw.githubusercontent.com/hartikainen/.dotfiles/main/setup/dotfiles.sh)"
```

macos:
```
bash -c "$(curl -LsS https://raw.githubusercontent.com/hartikainen/.dotfiles/main/setup/dotfiles.sh)"
```

## Full bootstrap

ubuntu / debian:
```
bash -c "$(wget -qO - https://raw.githubusercontent.com/hartikainen/.dotfiles/main/setup/setup.sh)"
```

macos:
```
bash -c "$(curl -LsS https://raw.githubusercontent.com/hartikainen/.dotfiles/main/setup/setup.sh)"
```
