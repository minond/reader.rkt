#lang racket/base

(require racket/match
         (prefix-in : scribble/html/xml)
         (prefix-in : scribble/html/html)
         (prefix-in : scribble/html/extra)

         reader/app/models/article
         reader/app/models/feed
         reader/app/components/feed

         reader/lib/app/components/pagination
         reader/lib/string)

(provide :reader)

(define (:reader feed-stats
                 articles
                 scheduled-feed-download
                 current-page
                 page-count)
  (:div 'class: "reader"
        ;;     +-------+----------+-----------+------------------------------------------------+
        ;;     | Feeds | Articles | Scheduled | Description                                    |
        ;;     |-------+----------+-----------+------------------------------------------------|
        ;; (1) | No    | No       | No        | User who should subscribe to their first feed. |
        ;; (2) | No    | No       | Yes       | User who just subscribed to their first feed.  |
        ;; (3) | Yes   | No       | Yes       | user who just subscribed to a feed.            |
        ;; (4) | Yes   | No       | No        | User who ran out of content.                   |
        ;; (5) | Yes   | Yes      | No        | User with content.                             |
        ;; (6) | Yes   | Yes      | Yes       | User with content.                             |
        ;; (7) | No    | Yes      | Yes       | Error state, no feeds but has orphan articles. |
        ;; (8) | No    | Yes      | No        | Error state, no feeds but has orphan articles. |
        ;;     |-------+----------+-----------+------------------------------------------------|
        (match/values
         (values feed-stats articles scheduled-feed-download)
         ;; (1)
         [((list) (list) #f)
          (:reader-zero-state)]
         ;; (2/3)
         [(_ (list) #t)
          (:reader-downloading-now)]
         ;; (4)
         [((list _ ...) (list) #f)
          (:reader-nothing-to-read)]
         ;; (5/6/7/8)
         [(_ (list _ ...) _)
          (:reader-standard-view articles current-page page-count)])))

(define (:reader-standard-view articles current-page page-count)
  (list (:reader/articles articles)
        (:pagination current-page page-count)))

(define (:reader-zero-state)
  (:div 'class: "no-articles"
        (:p "Welcome to Reader! Let's start by subscribing to a feed. Use the form below to search for something you'd like to start following.")
        (:feed/form)))

(define (:reader-downloading-now)
  (:div 'class: "no-articles"
        (:p "We're downloading that feed for you right now. In the mean time, would you like to subscribe to another feed?")
        (:feed/form)))

(define (:reader-nothing-to-read)
  (:div 'class: "no-articles"
        (:p "Looks like you're out of things to read. Would you like to subscribe to a new feed?")
        (:feed/form)))

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
      'title: ""
      (:div 'class: "reader-article-title"
            (article-title article))
      (and (not (zero? (string-length (article-description article))))
           (:p 'class: "reader-article-description"
               (string-chop (article-description article) 300 #:end "…")))))
