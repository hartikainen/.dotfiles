#!/usr/bin/env bash
set -euo pipefail
shellcheck --severity=warning --external-sources bin/bootstrap tests/nix/*.sh .config/shell/platform.sh
shfmt -d -i 4 -ci bin/bootstrap tests/nix/*.sh .config/shell/platform.sh
find nix tests/nix -name '*.nix' -print0 | xargs -0 nixfmt --check
nixfmt --check flake.nix
ruff check --select F,E9 bin/dotfiles bin/test nix/merge-settings.py tests/nix/test_*.py
ruff format --check bin/dotfiles bin/test nix/merge-settings.py tests/nix/test_*.py
bash .github/scripts/check-agent-references.sh
