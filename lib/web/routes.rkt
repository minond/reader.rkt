#lang racket/base

(require web-server/servlet
         (prefix-in : scribble/html/xml)
         (prefix-in : scribble/html/html)

         reader/lib/web/response
         reader/lib/web/parameters)

(provide authenticated-route
         route
         /not-found)

(define ((authenticated-route handler) req . args)
  (apply-handler handler #f req args))

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
     (apply-handler handler #f req args)]
    [(handler session req args)
     (parameterize ([current-request req])
       (with-handlers ([exn:fail? (lambda (e)
                                    (log-error e)
                                    (render #:code 500
                                            (:p 'class: "system-error"
                                                "There was an error handling your request at this time. We're looking into this!")))])
         (apply handler (cons req args))))]))
