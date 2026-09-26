;;; bazel-mode.el --- Compatibility for the private Doom package name -*- lexical-binding: t; -*-
;; Version: 0.0.3
;; Package-Requires: ((emacs "28.1"))

;;; Commentary:
;; The private configuration loads `bazel-mode`; upstream provides `bazel`.

;;; Code:
(require 'bazel)
(defvaralias 'bazel-mode-buildifier-before-save 'bazel-buildifier-before-save)
(provide 'bazel-mode)
;;; bazel-mode.el ends here
