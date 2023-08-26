#lang racket/base

(require racket/contract
         racket/match
         racket/string
         racket/function
         racket/list

         threading
         net/url-string

         (prefix-in rss- "../rss/parse.rkt")
         "../deducer/kind.rkt"
         "../extractor/easy.rkt"
         "../extractor/url.rkt"
         "../lib/task.rkt"
         "../lib/url.rkt")

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
       (dedupe
        (filter url?
                (cons (locate-feed-url url
                                       known-feed-paths)
                      (map (lambda~> (locate-feed-url known-feed-paths))
                           (extract-feed-urls (download url) url))))))
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

(define (dedupe urls)
  (define (strip-slashes url)
    (regexp-replace #px"/+$" (url->string url) ""))
  (remove-duplicates
   urls
   (lambda (a b)
     (equal? (strip-slashes a)
             (strip-slashes b)))))
