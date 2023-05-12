#lang racket/base

(require racket/runtime-path)

(provide app-web-root
         lib-web-root)

(define-runtime-path app-web-root "../web")
(define-runtime-path lib-web-root "./app/web")
