#lang racket/base

(require web-server/servlet-env
         reader/lib/app
         reader/lib/parameters)

(provide start-servlet)

(define (start-servlet)
  (serve/servlet (servlet-app-dispatch)
                 #:launch-browser? #f
                 #:extra-files-paths (list (build-path app-root "assets"))
                 #:servlet-path "/"
                 #:port 8000
                 #:servlet-regexp #rx""))
