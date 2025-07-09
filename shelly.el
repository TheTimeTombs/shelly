;;; shelly.el --- Library for running shell commands -*- lexical-binding: t -*-

;; Author: Thomas Freeman
;; Maintainer: Thomas Freeman
;; Version: Thomas Freeman
;; Package-Requires: ()
;; Homepage: 
;; Keywords: 


;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.


;;; Commentary:

;; 

;;; Code:


(require 'eshell)


;; Load vterm if shelly--vterm-command is called.
(autoload 'shelly--vterm-command "vterm")


(defgroup shelly nil "Customization options for Shelly.")

(defcustom shelly-remotes '("localhost")
  "A list of remote ssh connections for Shelly.

`shelly-remotes' should be a list of sting in which each element of the list is in
the form username@server."
  :type '(repeat string)
  :group 'shelly)

(defcustom shelly-default-shell "default"
  "The shell to run Shelly commands."
  :type '(string)
  :options '("default" "eshell" "vterm")
  :group 'shelly)

(defmacro shelly--as-ssh (server body)
  "Run BODY with tramp on SERVER using ssh."
  `(let* ((default-directory (expand-file-name
                              (format "/ssh:%s:~/" ,server))))
     (with-connection-local-variables
      ,body)))

(defun shelly-localhost-or-nil-p (address)
  "Return nil if host is not local, otherwise return ADDRESS."
  (or (not address)
      (string= "" address)
      (string-match "localhost" address)
      (string-match "128.0.0.1" address)))

(defun shelly-run-command (&optional command)
  "Run COMMAND with `async-shell-command'.

If COMMAND is not given, the user will be prompted for a command to enter."
  (interactive)
  (let ((cmd (or command
                 (read-string "Command: ")))
        (server (completing-read "Server: "
                                 shelly-remotes
                                 nil
                                 nil
                                 "localhost")))
    (message (format "Running: %s" cmd))
    (cond ((string= shelly-default-shell "vterm")
           (shelly--vterm-exec cmd server))
          ((string= shelly-default-shell "eshell")
           (shelly--eshell-exec cmd server))
          (t (shelly--command cmd server)))))

(defun shelly--command (command &optional server)
  "Run COMMAND with `async-shell-command'.

If SERVER is a server name of the form username@server, run the
command using ssh."
  (if (shelly-localhost-or-nil-p server)
      (async-shell-command command)
    (shelly--as-ssh server (async-shell-command command))))

(defun shelly--vterm-exec (&optional command server)
  "Insert the string COMMAND in a vterm buffer and execute it.

If SERVER is a server name of the form username@server, run the
command using ssh."
  (if (shelly-localhost-or-nil-p server)
      (shelly--vterm-send-command command)
    (shelly--as-ssh server (shelly--vterm-send-command command))))

(defun shelly--vterm-send-command (command)
  "Opens a new vterm window and insert and execute COMMAND."
  (vterm-other-window)
  (vterm-clear)
  (vterm-send-string command)
  (vterm-send-return))

(defun shelly--eshell-exec (command &optional server)
  "Run COMMAND in eshell.

If SERVER is a server name of the form username@server, run the
command using ssh."
  (if (shelly-localhost-or-nil-p server)
      (eshell-command command)
    (shelly--as-ssh server (eshell-command command))))

(defun shelly-command-to-string (command &optional remote message)
  "Run shell COMMAND in a shell and return the output as string.

If REMOTE is non-nil, the user will be prompted to select a remote server on
which to run the command using `completing-read' from the list of
`shelly-remotes'.

If MESSAGE is non-nil, then a message with COMMAND will be displayed."
  (let ((server (when remote (completing-read "Server: "
                                              shelly-remotes
                                              nil
                                              nil
                                              "localhost"))))
    (if (shelly-localhost-or-nil-p server)
        (progn (when message (message (format "Running: \'%s\'" command)))
               (shell-command-to-string command))
      (progn (when message (message (format "Running: \'%s\' on %s" command server)))
             (shelly--as-ssh server (shell-command-to-string command))))))

(provide 'shelly)

;;; shelly.el ends here
