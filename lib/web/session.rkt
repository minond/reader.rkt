#lang racket/base

(require gregor
         web-server/servlet
         web-server/http/id-cookie

         reader/lib/web/parameters
         reader/lib/format
         reader/lib/random)

(provide lookup-session
         create-session+cookie
         destroy-session+cookie
         update-session+cookie
         authenticated?
         new-session-route
         (struct-out session))

(define new-session-route (make-parameter "/sessions/new"))

(struct session (key user-id flash))
(define session-cookie-name "session")
(define sessions (make-hash))

(define (get-session-cookie req)
  (findf (lambda (cookie)
           (equal? session-cookie-name
                   (client-cookie-name cookie)))
         (request-cookies req)))

(define (lookup-session req-or-string)
  (let/cc return
    (when (string? req-or-string)
      (return (session-ref req-or-string)))
    (unless (request? req-or-string)
      (return (session #f #f #f)))
    (define session-cookie (get-session-cookie req-or-string))
    (unless session-cookie
      (return (session #f #f #f)))
    (session-ref (client-cookie-value session-cookie))))

(define (session-ref key)
  (hash-ref sessions key (session #f #f #f)))

(define (create-session user-id flash #:key [-key #f])
  (let* ([key (or -key (random-string))]
         [data (session key user-id flash)])
    (hash-set! sessions key data)
    key))

(define (create-session+cookie #:user-id user-id #:flash [flash #f] #:key [key #f])
  (make-cookie session-cookie-name
               (create-session user-id flash #:key key)
               #:path "/"
               #:expires (date->rfc7231 (+years (now/utc) 1))))

(define (destroy-session+cookie req)
  (define session-cookie (get-session-cookie req))
  (when session-cookie
    (hash-remove! sessions
                  (client-cookie-value session-cookie)))
  (logout-id-cookie session-cookie-name #:path "/"))

(define (update-session+cookie session #:user-id [user-id #f]
                               #:flash [flash #f])
  (let ([orig-user-id (session-user-id session)]
        [orig-flash (session-flash session)])
    (create-session+cookie #:user-id (or user-id orig-user-id)
                           #:flash (or flash orig-flash)
                           #:key (session-key session))))

(define authenticated?
  (case-lambda
    [() (authenticated? (current-session))]
    [(session) (and session (session-user-id session))]))
