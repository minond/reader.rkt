#lang racket/base

(require web-server/servlet)

(provide parameter)

(define (parameter key req #:default [default #f])
  (cdr (or (assoc key (request-bindings req))
           (cons key default))))
