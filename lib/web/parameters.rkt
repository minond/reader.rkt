#lang racket/base

(require racket/function)

(provide current-request
         default-layout)

(define current-request (make-parameter #f))
(define default-layout (make-parameter identity))
