#lang racket/base

(require racket/string
         racket/contract
         racket/sequence

         threading
         gregor
         uuid
         deta

         reader/app/models/article
         reader/lib/parameters)

(provide (except-out (schema-out tag)
                     make-tag)
         (schema-out article-tag)
         (rename-out [make-tag-override make-tag])
         select-article-tags
         create-article-tags)

(define set-by/c (one-of/c 'system 'user))

(define-schema tag
  ([(id (uuid-string)) string/f #:primary-key #:contract non-empty-string?]
   [label string/f #:contract non-empty-string?]
   [color string/f #:contract non-empty-string?]
   [(approved #f) boolean/f]
   [(created-at (now/utc)) datetime/f]))

(define-schema article-tag
  #:table "article_tags"
  ([(id (uuid-string)) string/f #:primary-key #:contract non-empty-string?]
   [article-id string/f #:contract non-empty-string?]
   [tag-id string/f #:contract non-empty-string?]
   [set-by symbol/f #:contract set-by/c]
   [(created-at (now/utc)) datetime/f]))

(define/contract (make-tag-override #:label label)
  (-> #:label string? tag?)
  (make-tag #:label label
            #:color (generate-random-tag-color)))

(define (generate-random-tag-color)
  (format "hsl(~a, ~a%, ~a%)"
          (* (random) 360)
          (+ (* (random) 70) 25)
          (+ (* (random) 10) 85)))

(define/contract (select-article-tags article)
  (-> article? (sequence/c tag?))
  (in-entities (current-database-connection)
               (~> (from tag #:as t)
                   (join #:left article-tag #:as at #:on (= t.id at.tag-id))
                   (where (= at.article-id ,(article-id article))))))

(define (select-tags-by-id ids)
  (in-entities (current-database-connection)
               (~> (from tag #:as t)
                   (where (in t.id ,@ids)))))

(define/contract (create-article-tags article tag-strings set-by)
  (-> article? (listof string?) set-by/c (sequence/c tag?))
  (define tags (create-tags tag-strings))
  (define article-tags (create-article-tag-mappings article tags set-by))
  (select-tags-by-id (map article-tag-tag-id article-tags)))

(define (create-tags labels)
  (define unsaved-tag-records
    (map (lambda (label)
           (make-tag-override #:label label))
         labels))
  (for/list ([tag unsaved-tag-records])
    (define label (tag-label tag))
    (define existing-tag (find-tag-by-label label))
    (or existing-tag
        (insert-one! (current-database-connection)
                     tag))))

(define (find-tag-by-label label)
  (lookup (current-database-connection)
          (~> (from tag #:as t)
              (where (= t.label ,label))
              (limit 1))))

(define (create-article-tag-mappings article tags set-by)
  (define unsaved-article-tag-records
    (map (lambda (tag)
           (make-article-tag #:article-id (article-id article)
                             #:tag-id (tag-id tag)
                             #:set-by set-by))
         tags))
  (for/list ([article-tag unsaved-article-tag-records])
    (define existing-tag
      (find-article-tag #:article-id (article-tag-article-id article-tag)
                        #:tag-id (article-tag-tag-id article-tag)))
    (or existing-tag
        (insert-one! (current-database-connection)
                     article-tag))))

(define (find-article-tag #:article-id article-id #:tag-id tag-id)
  (lookup (current-database-connection)
          (~> (from article-tag #:as at)
              (where (and (= at.article-id ,article-id)
                          (= at.tag-id ,tag-id)))
              (limit 1))))
