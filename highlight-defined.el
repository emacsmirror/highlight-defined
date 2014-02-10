;;; highlight-defined.el --- Syntax highlighting of known Elisp symbols -*- lexical-binding: t -*-

;; Author: Fanael Linithien <fanael4@gmail.com>
;; URL: https://github.com/Fanael/highlight-defined
;; Version: 0.1
;; Package-Requires: ((emacs "24"))

;; This file is NOT part of GNU Emacs.

;; Copyright (c) 2014, Fanael Linithien
;; All rights reserved.
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are
;; met:
;;
;;   * Redistributions of source code must retain the above copyright
;;     notice, this list of conditions and the following disclaimer.
;;   * Redistributions in binary form must reproduce the above copyright
;;     notice, this list of conditions and the following disclaimer in the
;;     documentation and/or other materials provided with the distribution.
;;   * Neither the name of the copyright holder(s) nor the names of any
;;     contributors may be used to endorse or promote products derived from
;;     this software without specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
;; IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
;; TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
;; PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
;; OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
;; EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
;; PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
;; PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
;; LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
;; NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

;;; Commentary:

;; Minor mode providing syntax highlighting of known Emacs Lisp symbols.
;;
;; Currently the code distinguishes Lisp functions, built-in functions,
;; macros, faces and variables.
;;
;; To enable call `highlight-defined-mode'.

;;; Code:

(require 'advice)

(defgroup highlight-defined nil
  "Highlight defined Emacs Lisp symbols."
  :prefix "highlight-defined-"
  :group 'faces)

(defface highlight-defined-function-name-face
  '((t :inherit font-lock-function-name-face))
  "Face used to highlight function names."
  :group 'highlight-defined
  :group 'faces)

(defface highlight-defined-builtin-function-name-face
  '((t :inherit highlight-defined-function-name-face))
  "Face used to highlight built-in function names."
  :group 'highlight-defined
  :group 'faces)

(defface highlight-defined-macro-name-face
  '((t :inherit highlight-defined-function-name-face))
  "Face used to highlight macro names."
  :group 'highlight-defined
  :group 'faces)

(defface highlight-defined-variable-name-face
  '((t :inherit font-lock-variable-name-face))
  "Face used to highlight variable names."
  :group 'highlight-defined
  :group 'faces)

(defface highlight-defined-face-name-face
  '((t :inherit highlight-defined-variable-name-face))
  "Face used to highlight face names."
  :group 'highlight-defined
  :group 'faces)


(defvar highlight-defined--face nil)

(defsubst highlight-defined--matcher-internal (end getunadviseddefinition)
  (catch 'highlight-defined--matcher-internal
    (while (re-search-forward "\\_<.+?\\_>" end t)
      (let ((symbol (intern-soft (buffer-substring-no-properties (match-beginning 0) (match-end 0)))))
        (when symbol
          (let ((face (cond
                       ((fboundp symbol)
                        (let ((func (funcall getunadviseddefinition (symbol-function symbol))))
                          (while (symbolp func)
                            (setq func (symbol-function func)))
                          (cond
                           ((subrp func) 'highlight-defined-builtin-function-name-face)
                           ((eq 'macro (car-safe func)) 'highlight-defined-macro-name-face)
                           (t 'highlight-defined-function-name-face))))
                       ((special-variable-p symbol) 'highlight-defined-variable-name-face)
                       ((facep symbol) 'highlight-defined-face-name-face)
                       (t nil))))
            (when face
              (setq highlight-defined--face face)
              (throw 'highlight-defined--matcher-internal t))))))
    nil))

(defconst highlight-defined--get-unadvised-definition
  ;; In Emacs < 24.4 `ad-get-orig-definition' is a macro that's
  ;; useless unless it's passed a quoted symbol.
  (if (eq 'macro (car-safe (symbol-function 'ad-get-orig-definition)))
      'identity
    'ad-get-orig-definition))

(defun highlight-defined--matcher (end)
  (highlight-defined--matcher-internal end highlight-defined--get-unadvised-definition))

;;;###autoload
(define-minor-mode highlight-defined-mode
  "Minor mode for highlighting known Emacs Lisp functions and variables.

Toggle highlight defined mode on or off.

With a prefix argument ARG, enable highlight defined mode if ARG is
positive, and disable it otherwise. If called from Lisp, enable
the mode if ARG is omitted or nil, and toggle it if ARG is `toggle'."
  :init-value nil
  :lighter ""
  :keymap nil
  (let ((keywords '((highlight-defined--matcher . highlight-defined--face))))
    (font-lock-remove-keywords nil keywords)
    (when highlight-defined-mode
      (font-lock-add-keywords nil keywords 'append)))
  ;; Refresh font locking.
  (when font-lock-mode
    (font-lock-mode -1)
    (font-lock-mode 1)))

(provide 'highlight-defined)
;;; highlight-defined.el ends here
