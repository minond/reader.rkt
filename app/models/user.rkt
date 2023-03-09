#lang racket/base

(require racket/string
         threading
         gregor
         deta

         reader/lib/parameters)

(provide (struct-out user)
         make-user)

(define-schema user
  ([id id/f #:primary-key #:auto-increment]
   [email string/f #:unique #:contract non-empty-string?]
   [encrypted-password binary/f]
   [salt binary/f]
   [(created-at (now/utc)) datetime/f]))

(model-make-user make-user)
(model-user-encrypted-password user-encrypted-password)
(model-user-salt user-salt)
(model-user-id user-id)
