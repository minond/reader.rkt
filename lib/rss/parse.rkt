#lang racket/base

(require request/param
         net/url-string
         xml

         reader/lib/rss/data
         reader/lib/rss/parse-atom
         reader/lib/rss/parse-rss)

(provide fetch
         (all-from-out reader/lib/rss/data))

(define (fetch feed-url)
  (parse (download feed-url)))

(define (download url)
  (define res (get (string->url url)))
  (define headers (http-response-headers res))

  (if (and (equal? 301 (http-response-code res))
           (hash-has-key? headers "Location"))
      (download (hash-ref headers "Location"))
      (xml->xexpr
       (document-element
        (read-xml
          (open-input-string (http-response-body res)))))))

(define (parse xexpr)
  (cond
    [(atom? xexpr) (parse-atom xexpr)]
    [(rss? xexpr) (parse-rss xexpr)]
    [else #f]))
