#lang racket/base

(require racket/runtime-path
         web-server/servlet-env
         reader/lib/parameters)

(provide start-servlet)

(define-runtime-path app-root "../app")

(define (start-servlet)
  (serve/servlet (servlet-app-dispatch)
                 #:launch-browser? #f
                 #:extra-files-paths (list (build-path app-root "assets"))
                 #:servlet-path "/"
                 #:port 8000
                 #:servlet-regexp #rx""))
