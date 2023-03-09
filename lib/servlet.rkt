#lang racket/base

(require web-server/servlet-env
         reader/lib/app/parameters)

(provide start-servlet)

(define (start-servlet)
  (serve/servlet (servlet-app-dispatch)
                 #:launch-browser? #f
                 #:servlet-path "/"
                 #:port 8000
                 #:servlet-regexp #rx""))
