#lang racket/base

(require #;racket/string
         #;racket/match
         #;racket/list

         #;gregor
         db
         (prefix-in : scribble/html/xml)
         (prefix-in : scribble/html/html)
         (prefix-in : scribble/html/extra)

         #;reader/app/models/article
         reader/app/models/feed
         #;reader/app/components/feed

         #;reader/lib/app/components/spacer
         #;reader/lib/app/components/pagination)

(provide :reader)

(define (:reader feed-stats articles)
  (map :reader/feed-item feed-stats))

(define (:reader/feed-item feed-stat)
  (:div 'class: "reader-feed-item"
        (:div 'class: "reader-feed-item-image"
              (:reader/feed-item-image feed-stat))
        (:div 'class: "reader-feed-item-title"
              (feed-stats-title feed-stat))
        (:div 'class: "reader-feed-item-count"
              (feed-stats-unarchived-count feed-stat))))

(define (:reader/feed-item-image feed-stat)
  (if (sql-null? (feed-stats-logo-url feed-stat))
      (:span)
      (:img 'src: (feed-stats-logo-url feed-stat))))
