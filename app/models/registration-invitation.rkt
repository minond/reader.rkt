#lang racket/base

(require racket/string
         threading
         gregor
         deta)

(provide (schema-out registration-invitation)
         find-available-registration-invitation)

(define-schema registration-invitation
  #:table "registration_invitations"
  ([id id/f #:primary-key #:auto-increment]
   [code string/f #:contract non-empty-string?]
   [(available #t) boolean/f]
   [user-id id/f #:nullable]
   [user-registered-at datetime/f #:nullable]
   [(created-at (now/utc)) datetime/f]))

(define (find-available-registration-invitation #:code code)
  (~> (from registration-invitation #:as ri)
      (where (and (= ri.code ,code)
                  ri.available))
      (limit 1)))
