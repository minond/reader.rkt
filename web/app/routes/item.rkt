#lang racket/base

(require racket/match
         racket/string

         threading
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
  (define known-feed-paths (list "feed" "rss"))
  (define url
    (~> (parameter 'url req)
        (string-trim)
        (string-replace " " "")
        (string->url)
        (fillin)))
  (match (deduce-kind url)
    [#f (info)]
    ['html
     (define feed-url
       (or (locate-feed-url url
                            known-feed-paths)
           (locate-feed-url (extract-feed-url (download url) url)
                            known-feed-paths)))
     (if feed-url
         (info "feed" feed-url)
         (info))]
    ['feed (info "feed" url)]))

(define (info [kind #f] [feed-url #f])
  (define (title feed-url)
    (define feed (rss-fetch feed-url))
    (rss-feed-title feed))
  (json 'kind kind
        'url (and (url? feed-url)
                  (url->string feed-url))
        'title (and (equal? kind "feed") feed-url
                    (or (safe (title feed-url))
                        (url-host feed-url)))))

(define (locate-feed-url url paths-to-try)
  (define kind (and url (deduce-kind url)))
  (cond [(not url) #f]
        [(equal? kind 'feed) url]
        [(not (null? paths-to-try))
         (set! url (string->url (url->string url)))
         (set-url-path! url (list (path/param (car paths-to-try)
                                              null)))
         (locate-feed-url url (cdr paths-to-try))]
        [else #f]))
