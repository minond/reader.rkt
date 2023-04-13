#lang racket/base

(require racket/function)

(provide current-database-connection
         model-make-user
         model-user-encrypted-password
         model-user-salt
         model-user-id
         component-session/form
         component-user/form
         user-registration/validate
         user-registration/post
         servlet-app-dispatch
         current-request
         current-session
         current-user-id
         current-flash
         default-layout)

(define current-database-connection (make-parameter #f))

(define current-request (make-parameter #f))
(define current-session (make-parameter #f))
(define current-user-id (make-parameter #f))
(define current-flash (make-parameter identity))
(define default-layout (make-parameter identity))

(define model-make-user (make-parameter #f))
(define model-user-encrypted-password (make-parameter #f))
(define model-user-salt (make-parameter #f))
(define model-user-id (make-parameter #f))

(define component-session/form (make-parameter #f))
(define component-user/form (make-parameter #f))

(define user-registration/validate (make-parameter #f))
(define user-registration/post (make-parameter #f))

(define servlet-app-dispatch (make-parameter #f))
