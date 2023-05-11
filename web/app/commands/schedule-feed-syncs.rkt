#lang racket/base

(require racket/sequence

         deta
         gregor

         reader/app/models/feed
         reader/app/commands/fetch-feed-articles

         reader/lib/job
         reader/lib/parameters)

(provide schedule-feed-syncs)

(define (schedule-feed-syncs)
  (let ([feeds (sequence->list
                (in-entities (current-database-connection)
                             (select-feeds-in-need-of-sync)))])
    (for/list ([feed feeds])
      (update-one! (current-database-connection)
                   (set-feed-last-sync-attempted-at feed (now/utc)))
      (schedule-job! (fetch-feed-articles (feed-user-id feed)
                                          (feed-id feed))))))
