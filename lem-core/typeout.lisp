(in-package :lem)

(export '(*typeout-mode-keymap*
          typeout-mode
          pop-up-typeout-window))

(define-minor-mode typeout-mode
    (:name "typeout"
     :keymap *typeout-mode-keymap*)
  (setf (variable-value 'truncate-lines :buffer (current-buffer)) nil))

(define-key *typeout-mode-keymap* "q" 'dismiss-typeout-window)
(define-key *typeout-mode-keymap* "Space" 'next-page-or-dismiss-typeout-window)
(define-key *typeout-mode-keymap* "Backspace" 'previous-page)

(defvar *typeout-window* nil)
(defvar *typeout-before-window* nil)

#|
(defun pop-up-typeout-window (buffer fn &key focus erase (read-only t))
  (let ((window (display-buffer buffer)))
    (with-current-window window
      (with-buffer-read-only buffer nil
        (when erase
          (erase-buffer buffer))
        (typeout-mode t)
        (when fn
          (save-excursion
            (with-open-stream (out (make-buffer-output-stream (buffer-end-point buffer)))
              (funcall fn out)))))
      (when read-only
        (setf (buffer-read-only-p buffer) t)))
    (when focus
      (setf (current-window) window))
    window))
|#

(defun pop-up-typeout-window (buffer fn &key focus erase (read-only t))
  (declare (ignore focus))
  (let ((already-created-p (if *typeout-window* t nil)))
    (with-buffer-read-only buffer nil
      (when erase
        (erase-buffer buffer))
      (when fn
        (with-open-stream (out (make-buffer-output-stream (buffer-end-point buffer)))
          (funcall fn out)
          (fresh-line out)
          (unless already-created-p
            (let* ((text "Press Space to continue")
                   (line (concatenate 'string
                                      (make-string (- (floor (display-width) 2)
                                                      (floor (length text) 2)
                                                      1)
                                                   :initial-element #\_)
                                      " "
                                      text
                                      " "))
                   (line (concatenate 'string
                                      line
                                      (make-string (- (display-width) (length text))
                                                   :initial-element #\_))))
              (write-line line out))))))
    (when read-only
      (setf (buffer-read-only-p buffer) t))
    (let* ((window-height
             (min (display-height) (buffer-nlines buffer)))
           (window
             (cond (already-created-p
                    (lem::window-set-size *typeout-window* (display-width) window-height)
                    (redraw-display*)
                    *typeout-window*)
                   (t
                    (let ((window (make-floating-window buffer 0 0 (display-width) window-height nil)))
                      (setf *typeout-window* window
                            *typeout-before-window* (current-window))
                      window)))))
      (setf (current-window) window)
      (typeout-mode t)
      window)))

(define-command dismiss-typeout-window () ()
  (when *typeout-window*
    (setf (current-window) *typeout-before-window*)
    (delete-window *typeout-window*)
    (setf *typeout-window* nil
          *typeout-before-window* nil)
    (redraw-display t)))

(define-command next-page-or-dismiss-typeout-window () ()
  (next-page)
  (when (last-line-p (current-point))
    (dismiss-typeout-window)))
