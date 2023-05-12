#lang racket/base

(require racket/contract
         racket/match
         racket/string
         racket/function

         threading
         net/url-string

         (prefix-in rss- reader/rss/parse)
         reader/deducer/kind
         reader/extractor/easy
         reader/extractor/url
         reader/lib/task
         reader/lib/url)

(provide (struct-out suggestion)
         make-suggestions
         suggested-feed?)

(struct suggestion (kind url title) #:transparent)

(define (suggested-feed? suggestion)
  (and (suggestion? suggestion)
       (equal? 'feed (suggestion-kind suggestion))))

(define known-feed-paths (list "feed" "rss"))

(define/contract (make-suggestions item)
  (-> string? (listof suggestion?))
  (define url
    (~> item
        (string-trim)
        (string-replace " " "")
        (string->url)
        (fillin)))
  (match (deduce-kind url)
    ['html
     (define feed-urls
       (filter identity
               (cons (locate-feed-url url
                                      known-feed-paths)
                     (map (lambda~> (locate-feed-url known-feed-paths))
                          (extract-feed-urls (download url) url)))))
     (map (lambda (feed-url)
            (suggestion 'feed feed-url (title-for feed-url)))
          feed-urls)]
    ['feed (list (suggestion 'feed url (title-for url)))]
    [else (list)]))

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

(define (title-for url)
  (or (safe (rss-feed-title (rss-fetch url)))
      (url-host url)))
