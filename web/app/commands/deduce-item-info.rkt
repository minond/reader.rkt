#lang racket/base

(require racket/contract
         racket/match
         racket/string

         threading
         net/url-string

         (prefix-in rss- reader/lib/rss/parse)
         reader/lib/deducer/kind
         reader/lib/extractor
         reader/lib/extractor/url
         reader/lib/task
         reader/lib/url)

(provide (struct-out deduction)
         deduce-item-info
         deduced-feed?)

(struct deduction (kind url title) #:transparent)

(define (deduced-feed? deduction)
  (and (deduction? deduction)
       (equal? 'feed (deduction-kind deduction))))

(define known-feed-paths (list "feed" "rss"))

(define/contract (deduce-item-info item)
  (-> string? (listof deduction?))
  (define url
    (~> item
        (string-trim)
        (string-replace " " "")
        (string->url)
        (fillin)))
  (match (deduce-kind url)
    ['html
     (define feed-url
       (or (locate-feed-url url
                            known-feed-paths)
           (locate-feed-url (extract-feed-url (download url) url)
                            known-feed-paths)))
     (if feed-url
         (list (deduction 'feed feed-url (title-for feed-url)))
         (list))]
    ['feed (list (deduction 'feed url (title-for url)))]
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
