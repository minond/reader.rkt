#lang racket/base

(require racket/string
         racket/contract

         threading
         request/param
         net/url-string
         net/mime-type

         reader/lib/net
         reader/lib/url
         reader/lib/web)

(provide deduce-kind)

(define kind+mime-types
  (hash 'feed (list "application/atom+xml"
                    "application/rss+xml"
                    "application/xml"
                    "text/xml")
        'html (list "text/html")))

(define/contract (deduce-kind maybe-url)
  (-> (or/c string? url?) (or/c symbol? #f))
  (let/cc return
    (define url (as-url maybe-url))
    (define mime-type (mime-type* url))
    (unless mime-type
      (return #f))
    (define kind
      (findf (lambda (kind)
               (define possible-mime-types (hash-ref kind+mime-types kind))
               (findf (lambda~> (string-prefix? mime-type _))
                      possible-mime-types))
             (hash-keys kind+mime-types)))
    (unless kind
      (log-warning "unable to deduce kind for ~a"
                   (url->string url)))
    kind))

(define (mime-type* url)
  (or (mime-type-from-path url)
      (mime-type-from-headers url)))

(define (mime-type-from-path url)
  (define mime-type (path-mime-type (url->path url)))
  (and mime-type (bytes->string/utf-8 mime-type)))

(define (mime-type-from-headers url)
  (hash-ref (http-response-headers (download url))
            "Content-Type" #f))
