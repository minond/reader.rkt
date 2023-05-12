#lang racket/base

(require deta
         db

         reader/web/components/article
         reader/web/components/feed
         reader/entities/article
         reader/entities/feed
         reader/tasks/save-new-feed
         reader/tasks/fetch-feed-articles

         reader/lib/parameters
         reader/lib/job
         reader/lib/web)

(provide /feeds
         /feeds/new
         /feeds/create
         /feeds/<id>/subscribe
         /feeds/<id>/unsubscribe
         /feeds/<id>/articles
         /feeds/<id>/sync)

(define page-size 50)

(define (/feeds req)
  (let ([feed-stats (in-entities (current-database-connection)
                                 (select-feed-stats #:user-id (current-user-id)))])
    (render (:feed/list feed-stats))))

(define (/feeds/new req)
  (render (:feed/form)))

(define (/feeds/create req)
  (let* ([url (parameter 'url req)]
         [exists (lookup (current-database-connection)
                         (find-feed-by-feed-url #:user-id (current-user-id)
                                                #:feed-url url))])

    (if exists
        (with-flash #:notice (and exists "This feed already exists.")
          (redirect "/articles"))
        (with-flash #:alert "Downloading feed data and articles."
          (schedule-job! (save-new-feed (current-user-id) url))
          (redirect "/articles?scheduled=1")))))

(define (/feeds/<id>/subscribe req id)
  (query (current-database-connection) (subscribe-to-feed #:id id
                                                          #:user-id (current-user-id)))
  (with-flash #:alert "Subscribed to feed."
    (redirect-back)))

(define (/feeds/<id>/unsubscribe req id)
  (query (current-database-connection) (unsubscribe-from-feed #:id id
                                                              #:user-id (current-user-id)))
  (with-flash #:alert "Unsubscribed from feed."
    (redirect-back)))

(define (/feeds/<id>/articles req id)
  (let* ([current-page (or (string->number (parameter 'page req #:default "")) 1)]
         [page-count (ceiling (/ (lookup (current-database-connection)
                                         (count-articles-by-feed #:feed-id id
                                                                 #:user-id (current-user-id)))
                                 page-size))]
         [offset (* (- current-page 1) page-size)]
         [feed (lookup (current-database-connection)
                       (find-feed-by-id #:id id
                                        #:user-id (current-user-id)))]
         [articles (in-entities (current-database-connection)
                                (select-articles-by-feed #:feed-id id
                                                         #:user-id (current-user-id)
                                                         #:limit page-size
                                                         #:offset offset))])
    (render (:article/list feed articles current-page page-count))))

(define (/feeds/<id>/sync req id)
  (schedule-job! (fetch-feed-articles (current-user-id) id))
  (with-flash #:alert "Syncing feed"
    (redirect-back)))
