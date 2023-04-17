#lang racket/base

(require racket/string
         threading
         gregor
         uuid
         deta)

(provide (schema-out article)
         make-article
         count-articles
         count-articles-by-feed
         select-articles
         select-articles-by-feed
         find-article-by-id
         find-article-by-feed-and-link
         archive-article-by-id
         unarchive-article-by-id)

(define-schema article
  ([(id (uuid-string)) string/f #:primary-key #:contract non-empty-string?]
   [user-id string/f]
   [feed-id string/f]
   [link string/f #:contract non-empty-string?]
   [title string/f #:contract non-empty-string?]
   [description string/f]
   [type string/f]
   [date datetime/f]
   [extracted-content-html string/f #:nullable]
   [extracted-content-text string/f #:nullable]
   [generated-summary-html string/f #:nullable]
   [generated-summary-text string/f #:nullable]
   [(archived #f) boolean/f]
   [(created-at (now/utc)) datetime/f]))

(define (count-articles #:user-id user-id
                        #:archived [archived #f]
                        #:subscribed [subscribed #t])
  (~> (from article #:as a)
      (select (count a.id))
      (join feed #:as f #:on (= f.id a.feed-id))
      (where (and (= a.user-id ,user-id)
                  (= a.archived ,archived)
                  (= f.subscribed ,subscribed)))))

(define (count-articles-by-feed #:feed-id feed-id
                                #:user-id user-id)
  (~> (from article #:as a)
      (select (count a.id))
      (join feed #:as f #:on (= f.id a.feed-id))
      (where (and (= a.user-id ,user-id)
                  (= a.feed-id ,feed-id)))))

(define (select-articles #:user-id user-id
                         #:archived [archived #f]
                         #:subscribed [subscribed #t]
                         #:limit lim
                         #:offset [off 0])
  (~> (from article #:as a)
      (join feed #:as f #:on (= f.id a.feed-id))
      (where (and (= a.user-id ,user-id)
                  (= a.archived ,archived)
                  (= f.subscribed ,subscribed)))
      (order-by ([date #:desc]))
      (offset ,off)
      (limit ,lim)))

(define (select-articles-by-feed #:feed-id feed-id
                                 #:user-id user-id
                                 #:limit lim
                                 #:offset [off 0])
  (~> (from article #:as a)
      (where (and (= a.user-id ,user-id)
                  (= a.feed-id ,feed-id)))
      (order-by ([date #:desc]))
      (offset ,off)
      (limit ,lim)))

(define (find-article-by-id #:id id #:user-id user-id)
  (~> (from article #:as a)
      (where (and (= a.id ,id)
                  (= a.user-id ,user-id)))
      (limit 1)))

(define (find-article-by-feed-and-link #:user-id user-id
                                       #:feed-id feed-id
                                       #:link link)
  (~> (from article #:as a)
      (where (and (= a.user-id ,user-id)
                  (= a.feed-id ,feed-id)
                  (= a.link ,link)))
      (limit 1)))

(define (archive-article-by-id #:id id #:user-id user-id)
  (~> (from article #:as a)
      (update [archived #t])
      (where (and (= a.id ,id)
                  (= a.user-id ,user-id)))))

(define (unarchive-article-by-id #:id id #:user-id user-id)
  (~> (from article #:as a)
      (update [archived #f])
      (where (and (= a.id ,id)
                  (= a.user-id ,user-id)))))
