#lang racket/base

(require gregor
         net/url-string
         reader/ffi/python)

(import feedparser)

(provide (struct-out feed)
         (struct-out article)
         valid?
         fetch)

(struct feed (link title articles) #:transparent)
(struct article (link title date content) #:transparent)

(define (valid? content-or-url)
  (define raw (feedparser.parse content-or-url))
  (pydict-contains? raw.feed "title"))

(define (fetch content-or-url)
  (define raw (feedparser.parse content-or-url))
  (define articles
    (for/list ([entry (pylist->list raw.entries)])
      (article (string->url entry.link)
               entry.title
               (entry-date entry)
               (entry-content entry))))
  (feed raw.feed.link
        raw.feed.title
        articles))

(define (entry-content entry)
  (cond [(pydict-contains? entry "summary") entry.summary]
        [(pydict-contains? entry "content") entry.content]
        [else #f]))

(define (entry-date entry)
  (cond [(pydict-contains? entry "published_parsed")
         (pydatetime->datetime entry.published_parsed)]
        [(pydict-contains? entry "created_parsed")
         (pydatetime->datetime entry.created_parsed)]
        [(pydict-contains? entry "updated_parsed")
         (pydatetime->datetime entry.updated_parsed)]
        [else
         (now/utc)]))
