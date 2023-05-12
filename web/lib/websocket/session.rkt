#lang racket/base

(require net/rfc6455/conn-api
         net/cookies/server
         web-server/http/request-structs

         reader/lib/server/session)

(provide lookup-ws-session
         (all-from-out reader/lib/server/session))

(define (lookup-ws-session ws-conn)
  (lookup-session (ws-conn-session-key ws-conn)))

(define (ws-conn-session-key ws-conn)
  (let* ([headers (ws-conn-base-headers ws-conn)]
         [cookie-header (findf (lambda (header)
                                 (equal? #"Cookie" (header-field header)))
                               headers)]
         [cookie-value (if cookie-header
                           (cookie-header->alist
                            (header-value cookie-header))
                           '())]
         [session-cookie (assoc #"session" cookie-value)]
         [session-key (and (pair? session-cookie)
                           (cdr session-cookie))])
    (and session-key
         (bytes->string/utf-8 session-key))))
