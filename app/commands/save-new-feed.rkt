#lang racket/base

(require deta

         reader/app/models/feed
         reader/app/commands/errors
         reader/app/commands/fetch-feed-articles

         reader/lib/parameters
         (prefix-in rss- reader/lib/rss/parse))

(provide save-new-feed)

(define (save-new-feed user-id feed-url)
  (define feed-data (rss-fetch feed-url))
  (unless feed-data
    (raise (unabled-to-download-feed "failed"
                                     (current-continuation-marks)
                                     feed-url
                                     user-id)))

  (define feed-record
    (insert-one! (current-database-connection)
                 (make-feed #:user-id user-id
                            #:feed-url feed-url
                            #:link (rss-feed-link feed-data)
                            #:title (rss-feed-title feed-data))))

  (log-info "saved feed record, fetching articles")
  (fetch-feed-articles user-id (feed-id feed-record)))
