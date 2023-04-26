#lang info

(define name "reader")
(define build-deps '("rackunit-lib" "overeasy"))
(define deps '("deta" "request" "gregor" "css-expr" "crypto" "rfc6455" "markdown" "uuid"
               ; html-parsing
               "mcfly"
               ; openapi
               "http-easy" "monotonic" "yaml"))
