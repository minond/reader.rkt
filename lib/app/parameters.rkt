#lang racket/base

(provide current-database-connection
         model-user-encrypted-password
         model-user-salt
         model-user-id
         component-session/form)

(define current-database-connection (make-parameter #f))

(define model-user-encrypted-password (make-parameter #f))
(define model-user-salt (make-parameter #f))
(define model-user-id (make-parameter #f))

(define component-session/form (make-parameter #f))
