#lang racket/base

(require deta

         "../../entities/feedback.rkt"
         "../../lib/parameters.rkt"
         "../../lib/server.rkt")

(provide /feedback/create)

(define (/feedback/create req)
  (define location-url (parameter 'location-url req))
  (define content (parameter 'content req))
  (insert-one! (current-database-connection)
               (make-feedback #:user-id (current-user-id)
                              #:location-url location-url
                              #:content content))
  (json 'ok #t))
