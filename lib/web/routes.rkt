#lang racket/base

(require db/base
         web-server/servlet
         (prefix-in : scribble/html/xml)
         (prefix-in : scribble/html/html)

         reader/lib/web/response
         reader/lib/web/session
         reader/lib/web/parameters)

(provide authenticated-route
         route
         /not-found)

(define ((authenticated-route handler) req . args)
  (let ([session (lookup-session req)])
    (if (not (authenticated? session))
        (redirect-to (new-session-route) permanently)
        (apply-handler handler session req args))))

(define ((route handler) req . args)
  (apply-handler handler req args))

(define (/not-found req)
  (log-warning "not found: ~a ~a"
               (request-method req)
               (url->string (request-uri req)))
  (render #:code 404
          (:p 'class: "system-error"
              "Page not found.")))

(define apply-handler
  (case-lambda
    [(handler req args)
     (apply-handler handler (lookup-session req) req args)]
    [(handler session req args)
     (parameterize ([current-request req]
                    [current-session session]
                    [current-user-id (and (session? session)
                                          (session-user-id session))])
       (with-handlers ([exn:fail? (lambda (e)
                                    (log-error (exn-message e))
                                    (render #:code 500 error-response))])
         (apply handler (cons req args))))]))

(define error-response
  (:p 'class: "system-error"
      "There was an error handling your request at this time. We're looking into this!"))
