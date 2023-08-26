#lang racket/base

(require (prefix-in : scribble/html/xml)
         (prefix-in : scribble/html/html)
         (prefix-in : scribble/html/extra)

         "../../../lib/server/flash.rkt")

(provide :flash
         :flash-message)

(define (:flash)
  (let ([alert (read-flash 'alert)]
        [notice (read-flash 'notice)])
    (list (and alert (:flash-message 'alert alert))
          (and notice (:flash-message 'notice notice)))))

(define (:flash-message kind text)
  (:div 'class: (format "flash ~a" kind)
        (:div 'class: "flash-text" text)))
