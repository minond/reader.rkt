#lang racket/base

(require (prefix-in x: xml))

(provide attr
         find-attr
         read-attr)

(define (attr name lst #:default [default #f])
  (read-attr (find-attr name lst) default))

(define (find-attr name lst)
  (findf (lambda (attr)
           (equal? name (x:attribute-name attr)))
         lst))

(define (read-attr attr [default #f])
  (if (x:attribute? attr)
      (x:attribute-value attr)
      default))
