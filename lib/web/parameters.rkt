#lang racket/base

(require racket/function)

(provide current-request
         current-session
         current-user-id
         current-flash
         default-layout)

(define current-request (make-parameter #f))
(define current-session (make-parameter #f))
(define current-user-id (make-parameter #f))
(define current-flash (make-parameter identity))
(define default-layout (make-parameter identity))
