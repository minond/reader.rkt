#lang racket/base

(require racket/string
         threading
         gregor
         uuid
         deta

         "../lib/parameters.rkt")

(provide (struct-out user)
         make-user)

(define-schema user
  ([(id (uuid-string)) string/f #:primary-key #:contract non-empty-string?]
   [email string/f #:unique #:contract non-empty-string?]
   [encrypted-password binary/f]
   [salt binary/f]
   [(created-at (now/utc)) datetime/f]))

(model-make-user make-user)
(model-user-encrypted-password user-encrypted-password)
(model-user-salt user-salt)
(model-user-id user-id)
