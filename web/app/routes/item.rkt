#lang racket/base

(require racket/match

         request/param
         net/url-string

         (prefix-in rss- reader/lib/rss/parse)
         reader/lib/deducer/kind
         reader/lib/extractor
         reader/lib/extractor/url
         reader/lib/url
         reader/lib/web)

(provide /item/deduce)

(define (/item/deduce req)
  (define url (fillin (string->url (parameter 'url req))))
  (match (deduce-kind url)
    [#f (info)]
    ['html
     (define feed-url
       (extract-feed-url (download url)
                         url))
     (if feed-url
         (info "feed" feed-url)
         (info))]
    ['feed (info "feed" url)]))

(define (info [kind #f] [feed-url #f])
  (json 'kind kind
        'feed-url (and (url? feed-url)
                       (url->string feed-url))
        'feed-title (and (equal? kind "feed") feed-url
                         (title feed-url))))

(define (title feed-url)
  (define feed (rss-fetch feed-url))
  (rss-feed-title feed))
