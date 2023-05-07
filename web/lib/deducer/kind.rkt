#lang racket/base

(require racket/string
         racket/contract

         threading
         request/param
         net/url-string
         net/mime-type

         reader/lib/net
         reader/lib/url
         reader/lib/web
         reader/lib/task
         (prefix-in rss- reader/lib/rss/parse))

(provide deduce-kind)

(define kind+mime-types
  (hash 'feed (list "application/atom+xml"
                    "application/rss+xml"
                    "application/xml"
                    "text/xml")
        'html (list "text/html")))

(define/contract (deduce-kind resource)
  (-> (or/c string? url?) (or/c symbol? #f))
  (let/cc return
    (define url (fillin (as-url resource)))
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
      (let ([res (safe (download url))])
        (and res
             (or (mime-type-from-headers res)
                 (mime-type-from-content res))))))

(define (mime-type-from-path url)
  (define mime-type (path-mime-type (url->path url)))
  (and mime-type (bytes->string/utf-8 mime-type)))

(define (mime-type-from-headers res)
  (hash-ref (http-response-headers res)
            "Content-Type" #f))

(define (mime-type-from-content res)
  (or (safe (~> res
                (rss-read)
                (rss-parse)
                (rss-feed?)
                (and _ "application/xml")))
      (safe (~> res
                (http-response-body)
                (string-contains? "<html")
                (and _ "text/html")))))
