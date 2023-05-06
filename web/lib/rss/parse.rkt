#lang racket/base

(require request/param
         net/url-string
         xml

         reader/lib/net
         reader/lib/rss/data
         reader/lib/rss/parse-atom
         reader/lib/rss/parse-rss)

(provide fetch
         parse
         read
         (all-from-out reader/lib/rss/data))

(define (fetch feed-url)
  (parse (read (download feed-url))))

(define (parse xexpr)
  (cond
    [(atom? xexpr) (parse-atom xexpr)]
    [(rss? xexpr) (parse-rss xexpr)]
    [else #f]))

(define (read res)
  (xml->xexpr
   (document-element
    (read-xml
     (open-input-string (http-response-body res))))))
