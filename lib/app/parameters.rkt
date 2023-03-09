#lang racket/base

(provide current-database-connection
         model-make-user
         model-user-encrypted-password
         model-user-salt
         model-user-id
         component-session/form
         component-user/form)

(define current-database-connection (make-parameter #f))

(define model-make-user (make-parameter #f))
(define model-user-encrypted-password (make-parameter #f))
(define model-user-salt (make-parameter #f))
(define model-user-id (make-parameter #f))

(define component-session/form (make-parameter #f))
(define component-user/form (make-parameter #f))
