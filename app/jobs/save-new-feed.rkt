#lang racket/base

(require racket/function

         db
         deta
         net/url-string

         reader/entities/feed
         reader/jobs/fetch-feed-articles

         reader/lib/job
         reader/lib/parameters
         reader/lib/websocket/message
         reader/extractor/easy
         reader/extractor/media
         reader/extractor/metadata
         (prefix-in rss- reader/rss/parse))

(provide save-new-feed
         save-new-feed/handler)

(struct save-new-feed (user-id feed-url) #:prefab)

(define (save-new-feed/handler cmd)
  (define user-id (save-new-feed-user-id cmd))
  (define feed-url (save-new-feed-feed-url cmd))

  (log-info "downloading feed, ~a" feed-url)
  (define feed-data (rss-fetch feed-url))
  (unless feed-data
    (error 'save-new-feed
           "unable to download feed at ~a for ~a"
           feed-url user-id))

  (define link (rss-feed-link feed-data))
  (define-values (logo-url description) (find-feed-logo-url+description link))
  (define feed-record
    (insert-one! (current-database-connection)
                 (make-feed #:user-id user-id
                            #:feed-url feed-url
                            #:logo-url logo-url
                            #:link link
                            #:title (rss-feed-title feed-data)
                            #:description description)))

  (define record-id (feed-id feed-record))
  (ws-publish (format "user/~a/feed/created" user-id)
              (hash 'id record-id))

  (log-info "saved feed record, fetching articles")
  (schedule-job! (fetch-feed-articles user-id record-id)))

(define (find-feed-logo-url+description link)
  (with-handlers ([exn:fail? (lambda (e)
                               (log-error (exn-message e)))])
    (log-info "extracting content for ~a" link)
    (let* ([url (string->url link)]
           [doc (download url)]
           [images (media-images (extract-media doc url))]
           [metadata (extract-metadata doc url)])
      (define image
        (findf identity (list (find-image-by-type images "apple-touch-icon")
                              (find-image-by-type images "icon"))))
      (define logo-url
        (if image
            (media:image-url image)
            sql-null))

      (define -description (or (metadata-description metadata) ""))
      (define description
        (if (not (zero? (string-length -description)))
            -description
            sql-null))

      (values logo-url description))))

(define (find-image-by-type lst type)
  (findf (lambda (image)
           (equal? (media:image-type image) type))
         lst))
