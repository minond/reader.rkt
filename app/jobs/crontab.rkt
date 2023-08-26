#lang racket/base

(require "../jobs/schedule-feed-syncs.rkt"
         "../lib/crontab.rkt")

(provide start-crontab)

(define (start-crontab)
  (crontab [@every-minute (run schedule-feed-syncs)]))
