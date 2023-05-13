#lang racket/base

(require request/param
         net/url-string)

(provide download)

(define (download str)
  (define url (if (string? str)
                  (string->url str)
                  str))

  (define res (get url))
  (define headers (http-response-headers res))

  (if (and (equal? 301 (http-response-code res))
           (hash-has-key? headers "Location"))
      (download (hash-ref headers "Location"))
      res))
