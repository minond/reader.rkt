#lang racket/base

(require racket/match

         request/param
         net/url-string

         reader/app/components/item

         (prefix-in rss- reader/lib/rss/parse)
         reader/lib/deducer/kind
         reader/lib/extractor
         reader/lib/extractor/url
         reader/lib/task
         reader/lib/url
         reader/lib/web)

(provide /item/add
         /item/deduce)

(define (/item/add req)
  (render (:item/add)))

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
  (define (title feed-url)
    (define feed (rss-fetch feed-url))
    (rss-feed-title feed))
  (json 'kind kind
        'feed-url (and (url? feed-url)
                       (url->string feed-url))
        'feed-title (and (equal? kind "feed") feed-url
                         (or (safe (title feed-url))
                             (url-host feed-url)))))
