# dotfiles

My dotfiles.

Two entry points:

- `setup/dotfiles.sh` — just the dotfiles (symlinks + local configs + git
  init). No `sudo`, no package installs, no system preference changes.
  Safe to run on someone else's machine or inside a container.
- `setup/setup.sh` — full bootstrap. Runs `dotfiles.sh` and then installs
  packages (`brew bundle` on macOS, `apt-get` on Ubuntu/Debian), applies
  system preferences (macOS `defaults`, Ubuntu `gsettings`), and offers
  to reboot.

Pass `-y` to either to skip all confirmation prompts.

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
