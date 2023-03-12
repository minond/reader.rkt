#lang racket/base

(require (prefix-in html- reader/lib/extractor/html))

(provide find-attribute
         read-attribute)

(define (read-attribute lst name #:default [default #f])
  (define attr (find-attribute lst name))
  (if attr
      (html-attribute-value attr)
      default))

(define (find-attribute lst name)
  (findf (lambda (attr)
           (equal? name (html-attribute-name attr)))
         lst))
