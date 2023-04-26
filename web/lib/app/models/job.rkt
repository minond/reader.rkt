#lang racket/base

(require racket/fasl
         racket/string
         racket/contract
         racket/serialize

         db
         threading
         gregor
         deta
         uuid

         reader/lib/parameters)

(provide (except-out (schema-out job)
                     make-job
                     job-name
                     job-data)
         (rename-out [make-job-override make-job])
         job-command
         job-label
         acquire-job!
         schedule-job!
         job-completed!
         job-errored!)

(define-values (ready running completed errored)
  (values "ready" "running" "completed" "errored"))

(define-schema job
  ([(id (uuid-string)) string/f #:primary-key #:contract non-empty-string?]
   [status string/f #:contract non-empty-string?]
   [name string/f #:contract non-empty-string?]
   [data binary/f]
   [logs string/f #:nullable]
   [started-at datetime/f #:nullable]
   [completed-at datetime/f #:nullable]
   [(created-at (now/utc)) datetime/f]))

(define/contract (make-job-override #:command command)
  (-> #:command serializable? job?)
  (make-job #:status ready
            #:name (symbol->string (object-name command))
            #:data (s-exp->fasl (serialize command))))

(define/contract (job-label job)
  (-> job? symbol?)
  (string->symbol (job-name job)))

(define/contract (job-command job)
  (-> job? serializable?)
  (deserialize (fasl->s-exp (job-data job))))

(define (schedule-job! command [conn (current-database-connection)])
  (insert-one! (current-database-connection)
               (make-job-override #:command command)))

(define (acquire-job! [conn (current-database-connection)])
  (let/cc return
    (define job (lookup conn (find-ready-job)))
    (unless (job? job)
      (return #f))

    (define results (query conn (update-job-as-running job)))
    (define affected-rows (cdr (assq 'affected-rows (simple-result-info results))))
    (unless (eq? 1 affected-rows)
      (return #f))

    job))

(define (job-completed! job logs [conn (current-database-connection)])
  (query conn (update-job-as-completed job logs)))

(define (job-errored! job logs [conn (current-database-connection)])
  (query conn (update-job-as-errored job logs)))

(define (find-ready-job)
  (~> (from job #:as j)
      (where (= j.status ,ready))
      (limit 1)))

(define (update-job-as-running job)
  (~> (from job #:as j)
      (update [status ,running]
              [started-at ,(datetime->sql-timestamp (now/utc))])
      (where (and (= j.status ,ready)
                  (= j.id ,(job-id job))))))

(define (update-job-as-completed job logs)
  (~> (from job #:as j)
      (update [status ,completed]
              [logs ,logs]
              [completed-at ,(datetime->sql-timestamp (now/utc))])
      (where (= j.id ,(job-id job)))))

(define (update-job-as-errored job logs)
  (~> (from job #:as j)
      (update [status ,errored]
              [logs ,logs]
              [completed-at ,(datetime->sql-timestamp (now/utc))])
      (where (= j.id ,(job-id job)))))

;; Not sure why deta isn't converting now/utc to a sql-timestamp in a prepared
;; statement, but it is when used as the default value in a schema definition.
(define (datetime->sql-timestamp dt)
  (sql-timestamp (->year dt)
                 (->month dt)
                 (->day dt)
                 (->hours dt)
                 (->minutes dt)
                 (->seconds dt)
                 (->nanoseconds dt)
                 #f))
