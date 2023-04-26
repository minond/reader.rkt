#lang racket/base

(require racket/runtime-path)

(provide app-root
         lib-app-root)

(define-runtime-path app-root "../app")
(define-runtime-path lib-app-root "./app")
