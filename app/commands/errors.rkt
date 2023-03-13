#lang racket/base

(provide unabled-to-download-feed
         unabled-to-find-feed)

(struct unabled-to-download-feed exn:fail (feed-url user-id))
(struct unabled-to-find-feed exn:fail (feed-id))
