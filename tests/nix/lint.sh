#!/usr/bin/env bash
set -euo pipefail
shellcheck --severity=warning --external-sources bin/bootstrap bin/install tests/nix/*.sh .config/shell/platform.sh
shfmt -d -i 4 -ci bin/bootstrap bin/install tests/nix/*.sh .config/shell/platform.sh
find nix tests/nix -name '*.nix' -print0 | xargs -0 nixfmt --check
nixfmt --check flake.nix
ruff check --select F,E9 bin/dotfiles bin/export bin/test bin/test-vm bin/macos-vm nix/*.py tests/nix/*.py
ruff format --check bin/dotfiles bin/export bin/test bin/test-vm bin/macos-vm nix/*.py tests/nix/*.py
bash .github/scripts/check-agent-references.sh
