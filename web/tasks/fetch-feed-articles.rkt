#lang racket/base

(require racket/function

         deta
         gregor
         (prefix-in : scribble/html/xml)

         reader/entities/article
         reader/entities/feed

         reader/lib/html
         reader/lib/parameters
         reader/lib/websocket/message
         reader/extractor/easy
         reader/extractor/text
         reader/extractor/render
         reader/extractor/metadata
         reader/extractor/document
         (prefix-in rss- reader/rss/parse))

(provide fetch-feed-articles
         fetch-feed-articles/handler)

(struct fetch-feed-articles (user-id feed-id) #:prefab)

(define (fetch-feed-articles/handler cmd)
  (define user-id (fetch-feed-articles-user-id cmd))
  (define feed-id (fetch-feed-articles-feed-id cmd))

  (define feed-record
    (lookup (current-database-connection)
            (find-feed-by-id #:id feed-id
                             #:user-id user-id)))
  (unless feed-record
    (error 'fetch-feed-articles
           "unable to find feed ~a for ~a"
           feed-url user-id))

  (define feed-url (feed-feed-url feed-record))
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
    (define link (rss-article-link article-data))
    (unless (lookup (current-database-connection)
                    (find-article-by-feed-and-link #:user-id user-id
                                                   #:feed-id feed-id
                                                   #:link link))
      (with-handlers ([exn:fail? (lambda (e)
                                   (log-error (exn-message e)))])
        (log-info "extracting content for ~a" link)
        (define-values (content metadata media document) (extract link))
        (define article-record
          (insert-one! (current-database-connection)
                       (make-article #:user-id user-id
                                     #:feed-id feed-id
                                     #:link link
                                     #:title (string-replace-html-entities
                                              (or (rss-article-title article-data)
                                                  (metadata-title metadata)))
                                     #:description (string-replace-html-entities
                                                    (document-summary document))
                                     #:type (or (metadata-type metadata) "")
                                     #:date (rss-article-date article-data)
                                     #:extracted-content-text (extract-text content)
                                     #:extracted-content-html (:xml->string (render-content content)))))

        (define record-id (article-id article-record))
        (ws-publish (format "user/~a/article/created" user-id)
                    (hash 'id record-id))))))