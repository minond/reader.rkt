#lang racket/base

(require racket/function

         db
         deta
         gregor
         net/url-string
         (prefix-in : scribble/html/xml)

         reader/entities/article
         reader/entities/feed

         reader/lib/html
         reader/lib/parameters
         reader/lib/websocket/message
         reader/extractor/goose
         (prefix-in rss- reader/rss/parse))

(provide fetch-feed-articles
         fetch-feed-articles/handler)

(struct fetch-feed-articles (user-id feed-id) #:prefab)

(define (fetch-feed-articles/handler cmd)
  (define user-id (fetch-feed-articles-user-id cmd))
  (define feed-id (fetch-feed-articles-feed-id cmd))

  (log-info "user-id: ~a" user-id)
  (log-info "feed-id: ~a" feed-id)

  (define feed-record
    (lookup (current-database-connection)
            (find-feed-by-id #:id feed-id
                             #:user-id user-id)))
  (unless feed-record
    (error 'fetch-feed-articles
           "unable to find feed ~a for user ~a"
           feed-id user-id))

  (define feed-url (feed-feed-url feed-record))
  (log-info "feed-url: ~a" feed-url)

  (define feed-data (rss-fetch feed-url))
  (unless feed-data
    (error 'fetch-feed-articles
           "unable to download feed at ~a for ~a"
           feed-url user-id))

  (update-one! (current-database-connection)
               (update-feed-last-sync-attempted-at
                feed-record (const (now/utc))))

  (log-info "saving new articles for feed-id: ~a" feed-id)
  (save-new-articles user-id feed-id feed-data)
  (log-info "done saving new articles for feed-id: ~a" feed-id)

  (update-one! (current-database-connection)
               (update-feed-last-sync-completed-at
                feed-record (const (now/utc)))))

(define (save-new-articles user-id feed-id feed-data)
  (for ([article-data (rss-feed-articles feed-data)])
    (define url (rss-article-link article-data))
    (define link (url->string url))
    (unless (lookup (current-database-connection)
                    (find-article-by-feed-and-link #:user-id user-id
                                                   #:feed-id feed-id
                                                   #:link link))
      (with-handlers ([exn:fail? (lambda (e)
                                   (log-error (exn-message e)))])
        (log-info "extracting content for ~a" link)
        (define content (extract link))
        (define extracted-content-text (article-info-content-text content))
        (define extracted-content-html (article-info-content-html content))

        (define original-content-text (or (rss-article-content-text article-data) sql-null))
        (define original-content-html (or (rss-article-content-html article-data) sql-null))
        (define title (rss-article-title article-data))
        (define description (article-info-description content))
        (define date (rss-article-date article-data))

        (define article-record
          (insert-one! (current-database-connection)
                       (make-article #:user-id user-id
                                     #:feed-id feed-id
                                     #:link link
                                     #:date date
                                     #:title title
                                     #:description description
                                     #:original-content-text original-content-text
                                     #:original-content-html original-content-html
                                     #:extracted-content-text extracted-content-text
                                     #:extracted-content-html extracted-content-html)))

        (define record-id (article-id article-record))
        (ws-publish (format "user/~a/article/created" user-id)
                    (hash 'id record-id))))))
