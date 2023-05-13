#lang racket/base

(require reader/jobs/schedule-feed-syncs
         reader/lib/crontab)

(provide start-crontab)

(define (start-crontab)
  (crontab [@every-minute (run schedule-feed-syncs)]))
