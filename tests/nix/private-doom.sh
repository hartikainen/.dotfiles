#!/usr/bin/env bash
set -euo pipefail
if [ "${DOTFILES_TEST_GUEST:-}" != 1 ]; then
    echo 'Run only in a disposable container or VM.' >&2
    exit 1
fi
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
test -f .config/doom/init.el
./bin/dotfiles apply --profile headless --adopt
export PATH="$HOME/.nix-profile/bin:$PATH"
export TERM=xterm-256color
cleanup() {
    for socket in dotfiles-private-a dotfiles-private-b; do
        emacsclient --socket-name="$socket" --eval '(kill-emacs)' >/dev/null 2>&1 || true
    done
}
trap cleanup EXIT
emacs --daemon=dotfiles-private-a
emacs --daemon=dotfiles-private-b
test "$(emacsclient --socket-name=dotfiles-private-a --eval "
  (progn
    (cl-assert (featurep 'doom))
    (cl-assert (eq doom-theme 'doom-gruvbox))
    (cl-assert (equal
      (with-temp-buffer
        (insert-file-contents (expand-file-name \"config.el\" doom-user-dir))
        (buffer-string))
      (with-temp-buffer
        (insert-file-contents (expand-file-name \"~/.config/doom/config.el\"))
        (buffer-string))))
    (require 'bazel-mode)
    (cl-assert (memq 'bazel-mode +format-on-save-disabled-modes))
    (cl-assert bazel-buildifier-before-save)
    (with-temp-buffer (bazel-mode) (cl-assert (eq major-mode 'bazel-mode)))
    (require 'copilot)
    (cl-assert (file-executable-p copilot-server-executable))
    (cl-assert (executable-find \"node\"))
    (cl-assert (executable-find \"ty\"))
    (setq dotfiles-test-marker t))")" = t
test "$(emacsclient --socket-name=dotfiles-private-b --eval "
  (and (featurep 'doom) (not (boundp 'dotfiles-test-marker)))")" = t
printf '\nPrivate Doom packages and independent named daemons passed.\n'
