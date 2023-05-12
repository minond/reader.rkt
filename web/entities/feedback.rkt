#lang racket/base

(require racket/string
         gregor
         uuid
         deta)

(provide (schema-out feedback))

(define-schema feedback
  #:table "feedback"
  ([(id (uuid-string)) string/f #:primary-key #:contract non-empty-string?]
   [user-id string/f]
   [location-url string/f #:contract non-empty-string?]
   [content string/f #:contract non-empty-string?]
   [(created-at (now/utc)) datetime/f]))
