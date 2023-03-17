#lang racket/base

(require #;racket/string
         #;racket/match
         #;racket/list

         #;gregor
         (prefix-in : scribble/html/xml)
         (prefix-in : scribble/html/html)
         (prefix-in : scribble/html/extra)

         #;reader/app/models/article
         reader/app/models/feed
         #;reader/app/components/feed

         reader/lib/string)

(provide :reader)

(define (:reader feed-stats articles)
  (:div 'class: "reader"
        (:reader/feeds feed-stats)))

(define (:reader/feeds feed-stats)
  (:div 'class: "reader-feeds"
        (:reader-feed-item "Today" 0 #:bold #t)
        (:reader-feed-item "Unread" 0 #:bold #t)
        (:reader-feed-item "Starred" 0 #:bold #t)
        (map :reader/feed-stat/feed-item feed-stats)))

(define (:reader/feed-stat/feed-item feed-stat)
  (:reader-feed-item
   (feed-stats-title feed-stat)
   (feed-stats-unarchived-count feed-stat)))

(define (:reader-feed-item title count #:bold [bold #f])
  (:div 'class: "reader-feed-item"
        (:div 'class: (string-join+  "reader-feed-item-title" (and bold "fwb")) title)
        (:div 'class: "reader-feed-item-count" (and (not (zero? count))
                                                    count))))
