#lang racket/base

(require (for-syntax racket/base
                     racket/syntax
                     syntax/parse)
         racket/function)

(provide safe
         task
         ok?
         err?)

(define-syntax (safe stx)
  (syntax-parse stx
    [(_ ex:expr)
     #'(with-handlers ([exn:fail? (const #f)])
         ex)]))

(define-syntax (task stx)
  (syntax-parse stx
    [(_ ex:expr)
     #'(with-handlers ([exn:fail? (const 'error)])
         ex)]))

(define (err? value)
  (equal? value 'error))

(define ok?
  (negate err?))
