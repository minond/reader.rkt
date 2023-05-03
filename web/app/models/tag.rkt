#lang racket/base

(require racket/string
         racket/contract

         threading
         gregor
         uuid
         deta)

(provide (except-out (schema-out tag)
                     make-tag)
         (schema-out article-tag)
         (rename-out [make-tag-override make-tag]))

(define-schema tag
  ([(id (uuid-string)) string/f #:primary-key #:contract non-empty-string?]
   [label string/f #:contract non-empty-string?]
   [color string/f #:contract non-empty-string?]
   [(approved #f) boolean/f]
   [(created-at (now/utc)) datetime/f]))

(define-schema article-tag
  #:table "article_tags"
  ([(id (uuid-string)) string/f #:primary-key #:contract non-empty-string?]
   [article-id string/f #:contract non-empty-string?]
   [tag-id string/f #:contract non-empty-string?]
   [set-by symbol/f #:contract (one-of/c 'system 'user)]
   [(created-at (now/utc)) datetime/f]))

(define/contract (make-tag-override #:label label)
  (-> #:label string? tag?)
  (make-tag #:label label
            #:color (generate-random-tag-color)))

(define (generate-random-tag-color)
  (format "#~a"
          (number->string
           (+ (arithmetic-shift (random 126 256) 16)
              (arithmetic-shift (random 126 256) 8)
              (arithmetic-shift (random 126 256) 0))
           16)))
