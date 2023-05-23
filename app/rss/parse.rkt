#lang racket/base

(require racket/string
         gregor
         net/url-string
         reader/ffi/python
         reader/lib/html
         (only-in reader/extractor/text extract-text)
         (only-in reader/extractor/render render-html)
         (only-in reader/extractor/content normalize-content))

(import feedparser)

(provide (struct-out feed)
         (struct-out article)
         valid?
         fetch)

(struct feed (link title articles) #:transparent)
(struct article (link title date content-html content-text) #:transparent)

(define (valid? content-or-url)
  (define raw (feedparser.parse content-or-url))
  (pydict-contains? raw.feed "title"))

(define (fetch content-or-url)
  (define raw (feedparser.parse content-or-url))
  (define articles
    (for/list ([entry (pylist->list raw.entries)])
      (define url (string->url entry.link))
      (define content (entry-content entry url))
      (article url
               (entry-title entry url)
               (entry-date entry)
               (render-html content)
               (extract-text content))))
  (feed raw.feed.link
        raw.feed.title
        articles))

(define (entry-title entry base-url)
  (define text
    (string-trim
     (string-replace-html-entities
      (extract-text
       (normalize-content entry.title base-url)))))
  (if (zero? (string-length text))
      (url->string base-url)
      text))

(define (entry-content entry base-url)
  (define content
    (cond [(pydict-contains? entry "content") entry.content]
          [(pydict-contains? entry "summary") entry.summary]
          [else #f]))
  (and content
       (normalize-content content base-url)))

(define (entry-date entry)
  (cond [(pydict-contains? entry "published_parsed")
         (pydatetime->datetime entry.published_parsed)]
        [(pydict-contains? entry "created_parsed")
         (pydatetime->datetime entry.created_parsed)]
        [(pydict-contains? entry "updated_parsed")
         (pydatetime->datetime entry.updated_parsed)]
        [else
         (now/utc)]))
