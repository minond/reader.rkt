#lang racket/base

(require gregor
         net/url-string
         reader/ffi/python
         reader/extractor/text
         (only-in reader/extractor/content normalize-content))

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
      (define url (string->url entry.link))
      (article url
               (entry-title entry url)
               (entry-date entry)
               (entry-content entry))))
  (feed raw.feed.link
        raw.feed.title
        articles))

(define (entry-title entry base-url)
  (extract-text
   (normalize-content entry.title base-url)))

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
