#lang racket/base

(provide current-database-connection)

(define current-database-connection (make-parameter #f))
