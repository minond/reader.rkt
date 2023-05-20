#lang racket/base

(require gregor
         reader/ffi/python)

(import feedparser)

(provide valid?
         fetch
         (struct-out feed)
         (struct-out article))

(struct feed (link title articles) #:transparent)
(struct article (link title date content) #:transparent)

(define (valid? content-or-url)
  (define raw (feedparser.parse content-or-url))
  (pydict-contains? raw.feed "title"))

; (define feed-url "https://jvns.ca/atom.xml")
; (define f (fetch feed-url))
(define (fetch feed-url)
  (define raw (feedparser.parse feed-url))
  (define articles
    (for/list ([entry (pylist->list raw.entries)])
      (article entry.link
               entry.title
               (datetime entry.updated_parsed.tm_year
                         entry.updated_parsed.tm_mon
                         entry.updated_parsed.tm_mday
                         entry.updated_parsed.tm_hour
                         entry.updated_parsed.tm_min
                         entry.updated_parsed.tm_sec
                         0)
               entry.summary)))
  (feed raw.feed.link
        raw.feed.title
        articles))
