#lang racket/base

(require json
         web-server/servlet)

(provide parameter
         request-json)

(define (parameter key req #:default [default #f])
  (cdr (or (assoc key (request-bindings req))
           (cons key default))))

(define (request-json req)
  (string->jsexpr
   (bytes->string/utf-8
    (request-post-data/raw req))))
