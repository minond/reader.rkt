#lang racket/base

(require web-server/servlet-env
         reader/app/dispatch)

(provide start-servlet)

(define (start-servlet)
  (serve/servlet app-dispatch
                 #:launch-browser? #f
                 #:servlet-path "/"
                 #:port 8000
                 #:servlet-regexp #rx""))
