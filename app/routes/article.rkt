#lang racket/base

(require (except-in racket/list group-by)
         racket/sequence

         web-server/servlet
         threading
         deta
         db
         json

         reader/app/models/article
         reader/app/models/feed
         reader/app/components/article
         reader/app/components/reader
         reader/app/commands/content-summary
         reader/lib/parameters
         reader/lib/web)

(provide /articles
         /articles/<id>/show
         /articles/<id>/archive
         /articles/<id>/unarchive
         /articles/<id>/summary
         /articles/<id>/chat)

(define page-size 20)

(define (/articles req)
  (let* ([scheduled (equal? "1" (parameter 'scheduled req))]
         [current-page (or (string->number (parameter 'page req #:default "")) 1)]
         [page-count (ceiling (/ (lookup (current-database-connection)
                                         (count-articles #:user-id (current-user-id)
                                                         #:archived #f))
                                 page-size))]
         [offset (* (- current-page 1) page-size)]
         [articles (sequence->list
                    (in-entities (current-database-connection)
                                 (select-articles #:user-id (current-user-id)
                                                  #:archived #f
                                                  #:limit page-size
                                                  #:offset offset)))]
         [feed-stats (sequence->list
                      (in-entities (current-database-connection)
                                   (select-feed-stats #:user-id (current-user-id))))])
    (render
     ; (:article/previews articles current-page page-count scheduled)
     (:reader feed-stats articles current-page page-count))))

(define (/articles/<id>/show req id)
  (let* ([article (lookup (current-database-connection)
                          (find-article-by-id #:id id
                                              #:user-id (current-user-id)))]
         [feed (lookup (current-database-connection)
                       (find-feed-by-id #:id (article-feed-id article)
                                        #:user-id (current-user-id)))])
    (render (:article/full feed article))))

(define (/articles/<id>/archive req id)
  (query (current-database-connection)
         (archive-article-by-id #:id id
                                #:user-id (current-user-id)))
  (with-flash #:alert "Article archived."
    (redirect-back)))

(define (/articles/<id>/unarchive req id)
  (query (current-database-connection)
         (unarchive-article-by-id #:id id
                                  #:user-id (current-user-id)))
  (with-flash #:alert "Article unarchived."
    (redirect-back)))

(define (/articles/<id>/summary req id)
  (let* ([article (lookup (current-database-connection)
                          (find-article-by-id #:id id
                                              #:user-id (current-user-id)))]
         [summary (article-generated-summary-html article)])
    (when (sql-null? summary)
      (define-values (text html) (generate-article-content-summary article))
      (set! summary html)
      (update-one! (current-database-connection)
                   (~> article
                       (set-article-generated-summary-html html)
                       (set-article-generated-summary-text text))))
    (json 'summary summary)))

(define (/articles/<id>/chat req id)
  (let* ([article (lookup (current-database-connection)
                          (find-article-by-id #:id id
                                              #:user-id (current-user-id)))]
         [summary (article-generated-summary-html article)]
         [body (bytes->string/utf-8 (request-post-data/raw req))]
         [chat (string->jsexpr body)]
         [messages (hash-ref chat 'chat)]
         [response (process-article-chat article messages)])
    (json 'response response)))
