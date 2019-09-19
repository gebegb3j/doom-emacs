;;; tools/pdf/config.el -*- lexical-binding: t; -*-

(use-package! pdf-tools
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :config
  (map! :map pdf-view-mode-map :gn "q" #'kill-current-buffer)

  (defun +pdf-cleanup-windows-h ()
    "Kill left-over annotation buffers when the document is killed."
    (when (buffer-live-p pdf-annot-list-document-buffer)
      (pdf-info-close pdf-annot-list-document-buffer))
    (when (buffer-live-p pdf-annot-list-buffer)
      (kill-buffer pdf-annot-list-buffer))
    (let ((contents-buffer (get-buffer "*Contents*")))
      (when (and contents-buffer (buffer-live-p contents-buffer))
        (kill-buffer contents-buffer))))
  (add-hook! 'pdf-view-mode-hook
    (add-hook 'kill-buffer-hook #'+pdf-cleanup-windows-h nil t))

  (setq-default pdf-view-display-size 'fit-page
                pdf-view-use-scaling t
                pdf-view-use-imagemagick nil)

  ;; Add retina support for MacOS users
  (when IS-MAC
    (advice-add #'pdf-util-frame-scale-factor :around #'+pdf--util-frame-scale-factor-a)
    (advice-add #'pdf-view-use-scaling-p :before-until #'+pdf--view-use-scaling-p-a)
    (defadvice! +pdf--supply-width-to-create-image-calls-a (orig-fn &rest args)
      :around '(pdf-annot-show-annotation
                pdf-isearch-hl-matches
                pdf-view-display-region)
      (cl-letf* ((old-create-image (symbol-function #'create-image))
                 ((symbol-function #'create-image)
                  (lambda (file-or-data &optional type data-p &rest props)
                    (apply old-create-image file-or-data type data-p
                           :width (car (pdf-view-image-size))
                           props))))
        (apply orig-fn args))))

  ;; Turn off cua so copy works
  (add-hook! 'pdf-view-mode-hook (cua-mode 0))
  ;; Handle PDF-tools related popups better
  (set-popup-rule! "^\\*Outline*" :side 'right :size 40 :select nil)
  ;; The next rules are not needed, they are defined in modules/ui/popups/+hacks.el
  ;; (set-popup-rule! "\\*Contents\\*" :side 'right :size 40)
  ;; (set-popup-rule! "* annots\\*$" :side 'left :size 40 :select nil)
  ;; Fix #1107: flickering pdfs when evil-mode is enabled
  (setq-hook! 'pdf-view-mode-hook evil-normal-state-cursor (list nil)))
