#lang racket/base

(require (for-syntax racket/base
                     racket/syntax
                     syntax/parse)
         racket/function)

(provide safe)

(define-syntax (safe stx)
  (syntax-parse stx
    [(_ ex:expr)
     #'(with-handlers ([exn:fail? (const #f)])
         ex)]))
