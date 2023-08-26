#lang racket/base

(require crontab

         "logger.rkt")

(provide run
         @every-minute
         (all-from-out crontab))

(define @every-minute "* * * * *")

(define-logger crontab)
(start-logger #:parent crontab-logger)

(define ((run f) ts)
  (parameterize ([current-logger crontab-logger])
    (log-info "running ~a" (object-name f))
    (with-handlers ([exn:fail? (lambda (e)
                                 (log-error (exn-message e)))])
      (f))))
