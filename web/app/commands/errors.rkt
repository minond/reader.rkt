#lang racket/base

(provide unable-to-download-feed
         unable-to-find-feed)

(struct unable-to-download-feed exn:fail (feed-url user-id))
(struct unable-to-find-feed exn:fail (feed-id))
