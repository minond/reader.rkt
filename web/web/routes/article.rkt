#lang racket/base

(require (except-in racket/list group-by)
         racket/sequence

         web-server/servlet
         threading
         deta
         db
         json

         reader/entities/article
         reader/entities/feed
         reader/entities/tag
         reader/web/components/article
         reader/web/components/reader
         reader/web/components/layout
         reader/ai/generate-article-summary
         reader/ai/generate-article-tags
         reader/ai/process-article-chat

         reader/lib/parameters
         reader/lib/web)

(provide /articles
         /articles/<id>/show
         /articles/<id>/archive
         /articles/<id>/unarchive
         /articles/<id>/summary
         /articles/<id>/tags
         /articles/<id>/chat)

(define page-size 20)

(define (/articles req)
  (let* ([scheduled-feed-download (equal? "1" (parameter 'scheduled req))]
         [current-page (or (string->number (parameter 'page req #:default "")) 1)]
         [page-count (ceiling (/ (lookup (current-database-connection)
                                         (count-articles #:user-id (current-user-id)
                                                         #:archived #f))
                                 page-size))]
         [offset (* (- current-page 1) page-size)]
         [article-summaries (select-article-summaries #:user-id (current-user-id)
                                                      #:archived #f
                                                      #:limit page-size
                                                      #:offset offset)]
         [feed-stats (in-entities (current-database-connection)
                                   (select-feed-stats #:user-id (current-user-id)))])
    (render
     (:reader (sequence->list feed-stats)
              (sequence->list article-summaries)
              scheduled-feed-download
              current-page page-count))))

(define (/articles/<id>/show req id)
  (let* ([article (lookup (current-database-connection)
                          (find-article-by-id #:id id
                                              #:user-id (current-user-id)))]
         [feed (lookup (current-database-connection)
                       (find-feed-by-id #:id (article-feed-id article)
                                        #:user-id (current-user-id)))])
    (render (:article/full feed article)
            #:layout (lambda (content)
                       (layout content #:body-class "hidden-header")))))

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
      (define-values (text html) (generate-article-summary article))
      (set! summary html)
      (update-one! (current-database-connection)
                   (~> article
                       (set-article-generated-summary-html html)
                       (set-article-generated-summary-text text))))
    (json 'summary summary)))

(define (/articles/<id>/tags req id)
  (let* ([article (lookup (current-database-connection)
                          (find-article-by-id #:id id
                                              #:user-id (current-user-id)))]
         [tags (select-article-tags article)])
    (when (zero? (sequence-length tags))
      (define tag-strings (generate-article-tags article))
      (set! tags (create-article-tags article tag-strings 'system)))
    (json 'tags (for/list ([tag tags])
                  (hash 'id (tag-id tag)
                        'label (tag-label tag)
                        'color (tag-color tag))))))

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
