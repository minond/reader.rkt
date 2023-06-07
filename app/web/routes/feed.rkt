#lang racket/base

(require deta
         db

         reader/web/components/article
         reader/web/components/feed
         reader/entities/article
         reader/entities/feed
         reader/jobs/save-new-feed
         reader/jobs/fetch-feed-articles

         reader/lib/parameters
         reader/lib/job
         reader/lib/task
         reader/lib/server)

(provide /feeds
         /feeds/new
         /feeds/create/v0
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

(define (/feeds/create/v0 req)
  (let* ([url (parameter 'url req)]
         [exists (lookup (current-database-connection)
                         (find-feed-by-feed-url #:user-id (current-user-id)
                                                #:feed-url url))])

    (cond
      [exists
       (with-flash #:notice (and exists "This feed already exists.")
         (redirect "/articles"))]
      [else
       (define result
         (task (save-new-feed/handler
                 (save-new-feed (current-user-id) url))))
       (if (err? result)
           (with-flash #:notice "There was an error fetching this feed, please try again."
             (redirect "/articles"))
           (with-flash #:alert "Downloading feed data and articles."
             (redirect "/articles")))])))

(define (/feeds/create req)
  (sleep 2)
  (json 'ok #t 'feed-id "fake"))
  ; (define data (request-json req))
  ; (define url (hash-ref data 'url))
  ;
  ; (let/cc return
  ;   (define exists (lookup (current-database-connection)
  ;                          (find-feed-by-feed-url #:user-id (current-user-id)
  ;                                                 #:feed-url url)))
  ;   (when exists
  ;     (return (json 'ok #f 'duplicate #t #:code 409)))
  ;   (define result
  ;     (task (save-new-feed/handler
  ;            (save-new-feed (current-user-id) url))))
  ;   (when (err? result)
  ;     (return (json 'ok #f #:code 422)))
  ;   (json 'ok #t 'feed-id (feed-id result))))

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
