#lang racket/base

(require (prefix-in : scribble/html/xml)
         (prefix-in : scribble/html/html)
         (prefix-in : scribble/html/extra)

         reader/app/models/article
         reader/app/models/feed

         reader/lib/app/components/pagination
         reader/lib/string)

(provide :reader)

(define (:reader feed-stats articles current-page page-count)
  (:div 'class: "reader"
        (:div 'class: "reader-container"
              (:reader/feeds feed-stats)
              (:reader/articles articles))
        (:pagination current-page page-count)))

(define (:reader/feeds feed-stats)
  (:div 'class: "reader-feeds"
        (:reader-feed-item 'today "Today" 0 #:bold #t)
        (:reader-feed-item 'unread "Unread" 0 #:bold #t)
        (:reader-feed-item 'starred "Starred" 0 #:bold #t)
        (map :reader/feed-stat/feed-item feed-stats)))

(define (:reader/feed-stat/feed-item feed-stat)
  (:reader-feed-item
   (feed-stats-id feed-stat)
   (feed-stats-title feed-stat)
   (feed-stats-unarchived-count feed-stat)))

(define (:reader-feed-item id title count #:bold [bold #f])
  (:div 'class: "reader-feed-item"
        (:a 'href: (format "/feeds/~a/articles" id)
            'class: (string-join+  "reader-feed-item-title" (and bold "fwb"))
            title)
        (:div 'class: "reader-feed-item-count" (and (not (zero? count))
                                                    count))))

(define (:reader/articles articles)
  (:div 'class: "reader-articles"
        (map :reader/article articles)))

(define (:reader/article article)
  (:a 'href: (format "/articles/~a" (article-id article))
      'class: "reader-article"
      (:span 'class: "reader-article-title" (article-title article))
      (:span 'class: "reader-article-description" (article-description article))))
