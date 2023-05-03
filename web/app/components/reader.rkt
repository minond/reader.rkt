#lang racket/base

(require racket/match

         gregor
         (prefix-in : scribble/html/xml)
         (prefix-in : scribble/html/html)
         (prefix-in : scribble/html/extra)

         reader/app/models/article
         reader/app/models/feed
         reader/app/components/feed
         reader/app/components/image

         reader/lib/app/components/pagination
         reader/lib/app/components/spacer
         reader/lib/string)

(provide :reader)

(define (:reader feed-stats
                 article-summaries
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
         (values feed-stats article-summaries scheduled-feed-download)
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
          (:reader-standard-view article-summaries current-page page-count)])))

(define (:reader-standard-view article-summaries current-page page-count)
  (list (:reader/articles article-summaries)
        (:pagination current-page page-count)))

(define (:reader-zero-state)
  (:div 'class: "no-articles"
        (:script 'type: 'module 'src: "/public/reload-on-article-created.js")
        (:p "Welcome to Reader! Let's start by subscribing to a feed. Use the form below to search for something you'd like to start following.")
        (:feed/form)
        (:div 'class: "reload-page-container")))

(define (:reader-downloading-now)
  (:div 'class: "no-articles"
        (:script 'type: 'module 'src: "/public/reload-on-article-created.js")
        (:p "We're downloading that feed for you right now. In the mean time, would you like to subscribe to another feed?")
        (:feed/form)
        (:div 'class: "reload-page-container")))

(define (:reader-nothing-to-read)
  (:div 'class: "no-articles"
        (:script 'type: 'module 'src: "/public/reload-on-article-created.js")
        (:p "Looks like you're out of things to read. Would you like to subscribe to a new feed?")
        (:feed/form)
        (:div 'class: "reload-page-container")))

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

(define (:reader/articles article-summaries)
  (:div 'class: "reader-articles"
        (map :reader/article article-summaries)))

(define (:reader/article article-summary)
  (:div 'class: "reader-article"
        (:a 'href: (format "/articles/~a" (article-summary-id article-summary))
            (:div 'class: "reader-article-title"
                  (article-summary-title article-summary)))
        (:div 'class: "reader-article-details"
              (:span (article-summary-feed-title article-summary))
              (:spacer #:direction horizontal #:size tiny)
              (:entity #x000B7)
              (:spacer #:direction horizontal #:size tiny)
              (:span (~t (article-summary-date article-summary) "MMMM d, yyyy")))
        (:div 'class: "reader-article-actions vc-container"
              (:a 'href: (format "/articles/~a/archive" (article-summary-id article-summary))
                  'class: "vc"
                  (:image/archive)))
        (and (not (zero? (string-length (article-summary-description article-summary))))
             (:a 'href: (format "/articles/~a" (article-summary-id article-summary))
                 'class: "reader-article-description"
                 (:p (string-chop (article-summary-description article-summary) 300 #:end "…"))))))
