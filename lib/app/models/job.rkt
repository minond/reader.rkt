#lang racket/base

(require racket/fasl
         racket/string
         racket/contract
         racket/serialize

         db
         threading
         gregor
         deta

         reader/lib/parameters)

(provide (except-out (schema-out job)
                     make-job
                     job-data)
         (rename-out [make-job-override make-job]
                     [job-data-override job-data])
         acquire-next-job)

(define-schema job
  ([id id/f #:primary-key #:auto-increment]
   [name string/f #:contract non-empty-string?]
   [data binary/f]
   [started-at datetime/f #:nullable]
   [completed-at datetime/f #:nullable]
   [(created-at (now/utc)) datetime/f]))

(define/contract (make-job-override #:data data)
  (-> #:data serializable? job?)
  (make-job #:name (symbol->string (object-name data))
            #:data (s-exp->fasl (serialize data))))

(define/contract (job-data-override job)
  (-> job? serializable?)
  (deserialize (fasl->s-exp (job-data job))))

(define (acquire-next-job [conn (current-database-connection)])
  (let/cc return
    (define job (lookup conn (find-available-job)))
    (unless (job? job)
      (return #f))

    (define results (query conn (update-job-as-unavailable job)))
    (define affected-rows (cdr (assq 'affected-rows (simple-result-info results))))
    (unless (eq? 1 affected-rows)
      (return #f))

    job))

(define (find-available-job)
  (~> (from job #:as j)
      (where (is j.started-at null))
      (limit 1)))

(define (update-job-as-unavailable job)
  (~> (from job #:as j)
      (update [started-at ,(~t (now/utc) "yyyy-MM-dd'T'HH:mm:ss")])
      (where (and (is j.started-at null)
                  (= j.id ,(job-id job))))))
