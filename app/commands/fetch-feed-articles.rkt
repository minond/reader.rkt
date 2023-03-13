#lang racket/base

(require deta
         (prefix-in : scribble/html/xml)

         reader/app/models/article
         reader/app/models/feed
         reader/app/commands/errors

         reader/lib/parameters
         reader/lib/extractor
         reader/lib/extractor/render
         reader/lib/extractor/metadata
         (prefix-in rss- reader/lib/rss/parse))

(provide fetch-feed-articles)

(define (fetch-feed-articles user-id feed-id)
  (define feed-record
    (lookup (current-database-connection)
            (find-feed-by-id #:id feed-id
                             #:user-id user-id)))
  (unless feed-record
    (raise (unabled-to-find-feed "failed"
                                 (current-continuation-marks)
                                 feed-id)))

  (define feed-url (feed-feed-url feed-record))
  (define feed-data (rss-fetch feed-url))
  (unless feed-data
    (raise (unabled-to-download-feed "failed"
                                     (current-continuation-marks)
                                     feed-url
                                     user-id)))

  (for ([article-data (rss-feed-articles feed-data)])
    (define link (rss-article-link article-data))
    (log-info "extracting content for ~a" link)
    (define-values (content metadata media) (extract link))

    (insert-one! (current-database-connection)
                 (make-article #:user-id user-id
                               #:feed-id feed-id
                               #:link link
                               #:title (or (metadata-title metadata)
                                           (rss-article-title article-data))
                               #:description (or (metadata-description metadata) "")
                               #:type (or (metadata-type metadata) "")
                               #:date (rss-article-date article-data)
                               #:content-data "" ; TODO
                               #:content-text "" ; TODO
                               #:content-html (:xml->string (render-content content))))))
