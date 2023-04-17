#lang racket/base

(require racket/string
         threading
         gregor
         uuid
         deta)

(provide (schema-out registration-invitation)
         find-available-registration-invitation)

(define-schema registration-invitation
  #:table "registration_invitations"
  ([(id (uuid-string)) string/f #:primary-key #:contract non-empty-string?]
   [code string/f #:contract non-empty-string?]
   [(available #t) boolean/f]
   [user-id string/f #:nullable]
   [user-registered-at datetime/f #:nullable]
   [(created-at (now/utc)) datetime/f]))

(define (find-available-registration-invitation #:code code)
  (~> (from registration-invitation #:as ri)
      (where (and (= ri.code ,code)
                  ri.available))
      (limit 1)))
