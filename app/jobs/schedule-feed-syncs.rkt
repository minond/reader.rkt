#lang racket/base

(require racket/sequence

         deta
         gregor

         "../entities/feed.rkt"
         "../jobs/fetch-feed-articles.rkt"

         "../lib/job.rkt"
         "../lib/parameters.rkt")

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
