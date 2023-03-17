#lang racket/base

(require racket/function

         db
         deta
         net/url-string

         reader/app/models/feed
         reader/app/commands/errors
         reader/app/commands/fetch-feed-articles

         reader/lib/parameters
         reader/lib/extractor
         reader/lib/extractor/media
         (prefix-in rss- reader/lib/rss/parse))

(provide save-new-feed)

(define (save-new-feed user-id feed-url)
  (log-info "downloading feed, ~a" feed-url)
  (define feed-data (rss-fetch feed-url))
  (unless feed-data
    (raise (unabled-to-download-feed "failed"
                                     (current-continuation-marks)
                                     feed-url
                                     user-id)))

  (define link (rss-feed-link feed-data))
  (define logo-url (find-feed-logo-url link))
  (define feed-record
    (insert-one! (current-database-connection)
                 (make-feed #:user-id user-id
                            #:feed-url feed-url
                            #:logo-url logo-url
                            #:link link
                            #:title (rss-feed-title feed-data))))

  (log-info "saved feed record, fetching articles")
  (fetch-feed-articles user-id (feed-id feed-record)))

(define (find-feed-logo-url link)
  (with-handlers ([exn:fail? (lambda (e)
                               (displayln "ERRRRRRRRRRR")
                               (displayln e)
                               (log-error (exn-message e)))])
    (log-info "extracting content for ~a" link)
    (let* ([url (string->url link)]
           [doc (download url)]
           [images (media-images (extract-media doc url))])
      (define image
        (findf identity (list (find-image-by-type images "apple-touch-icon")
                              (find-image-by-type images "icon"))))
      (if image
          (media:image-url image)
          sql-null))))

(define (find-image-by-type lst type)
  (findf (lambda (image)
           (equal? (media:image-type image) type))
         lst))
