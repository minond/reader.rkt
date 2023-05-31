#lang racket/base

(require reader/lib/random
         reader/lib/logger
         reader/lib/parameters
         reader/lib/app/models/job)

(provide make-job-manager
         register-job-handler!
         (all-from-out reader/lib/app/models/job))

(define handlers (make-hash))
(define (register-job-handler! name f)
  (define label
    (cond [(symbol? name) name]
          [(string? name) (string->symbol name)]
          [else (object-name name)]))
  (hash-set! handlers label f))

(define (gen-loop id)
  (lambda ()
    (log-info "starting worker:~a" id)
    (let loop ()
      (sync
       (handle-evt (thread-receive-evt)
                   (lambda (_)
                     (log-info "stopping worker:~a" id)))
       (handle-evt (alarm-evt (+ (current-inexact-milliseconds) 1000))
                   (lambda (args)
                     (define job (acquire-job! (current-database-connection)))
                     (when job (safe-run-job job))
                     (loop)))))))

(define (make-job-manager #:background [background? #t]
                          #:custodian [custodian (current-custodian)])
  (define id (random-string))
  (if background?
      (let ([thd (parameterize ([current-custodian custodian])
                   (thread (gen-loop id)))])
        (lambda ()
          (thread-send thd 'stop)))
      ((gen-loop id))))

(define (safe-run-job job)
  (define errored? #f)
  (define buf (open-output-string))

  (define-logger worker)
  (define stop-logger (start-logger #:parent worker-logger
                                    #:out buf))

  (parameterize ([current-output-port buf]
                 [current-error-port buf]
                 [current-logger worker-logger])
    (with-handlers ([exn?
                     (lambda (e)
                       (set! errored? #t)
                       (displayln (exn-message e)))])
      (run-job job)))

  (stop-logger)

  (if errored?
      (job-errored! job (get-output-string buf))
      (job-completed! job (get-output-string buf))))

(define (run-job job)
  (define name (job-label job))
  (unless (hash-has-key? handlers name)
    (error "job handler not found"))

  (define handler (hash-ref handlers name))
  (log-info "running ~a" name)
  (handler (job-command job)))
