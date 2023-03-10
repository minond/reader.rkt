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

(define (download feed-url)
  (let* ([response (get (string->url feed-url))]
         [body (http-response-body response)]
         [root (read-xml (open-input-string body))]
         [elem (document-element root)])
    (xml->xexpr elem)))

(define (parse xexpr)
  (cond
    [(atom? xexpr) (parse-atom xexpr)]
    [(rss? xexpr) (parse-rss xexpr)]
    [else #f]))
