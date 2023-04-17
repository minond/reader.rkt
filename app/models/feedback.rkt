#lang racket/base

(require racket/string
         gregor
         deta)

(provide (schema-out feedback))

(define-schema feedback
  #:table "feedback"
  ([id id/f #:primary-key #:auto-increment]
   [user-id id/f]
   [location-url string/f #:contract non-empty-string?]
   [content string/f #:contract non-empty-string?]
   [(created-at (now/utc)) datetime/f]))
