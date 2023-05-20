#lang racket/base

(require gregor
         reader/ffi/python
         reader/rss/data)

(import feedparser)

(provide valid?
         fetch
         (all-from-out reader/rss/data))

(define (valid? content-or-url)
  (define raw (feedparser.parse content-or-url))
  (not (pydict-ref raw "bozo_exception" #f)))

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
