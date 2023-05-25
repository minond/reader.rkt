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

(define (fetch feed-url)
  (define raw (feedparser.parse feed-url))
  (define articles
    (for/list ([entry (pylist->list raw.entries)])
      (log-info "rss-parse article: ~a" entry.link)
      (define url (string->url entry.link))
      (define content (entry-content entry url))
      (article url
               (entry-title entry url)
               (entry-date entry)
               (and content (render-html content))
               (and content (extract-text content)))))
  (define link
    (or (and (pydict-contains? raw.feed "link") raw.feed.link)
        feed-url))
  (define title
    (or (and (pydict-contains? raw.feed "title") raw.feed.title)
        feed-url))
  (feed link title articles))

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
  (define raw-content-objs
    (and (pydict-contains? entry "content")
         (pylist->list entry.content)))
  (define raw-content-obj
    (and (list? raw-content-objs)
         (not (null? raw-content-objs))
         (car raw-content-objs)))
  (define content
    (cond [(and (pydict? raw-content-obj)
                (pydict-contains? raw-content-obj "value"))
           raw-content-obj.value]
          [(pydict-contains? entry "summary")
           entry.summary]
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
