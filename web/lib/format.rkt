#lang racket/base

(require gregor)

(provide date->rfc7231)

(define (date->rfc7231 date)
  (~t date "E, dd MMM yyyy HH:mm:ss"))
