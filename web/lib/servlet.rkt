#lang racket/base

(require web-server/servlet-env
         reader/lib/path
         reader/lib/parameters)

(provide start-servlet)

(define (start-servlet)
  (serve/servlet (servlet-app-dispatch)
                 #:launch-browser? #f
                 #:extra-files-paths (list (build-path app-web-root "assets")
                                           (build-path lib-web-root "assets"))
                 #:servlet-path "/"
                 #:listen-ip (getenv "SERVER_LISTEN_IP")
                 #:port (or (and (getenv "SERVER_LISTEN_PORT")
                                 (string->number (getenv "SERVER_LISTEN_PORT")))
                            8000)
                 #:servlet-regexp #rx""))
